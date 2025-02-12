#!/bin/bash

# Colors for console output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
load_env() {
    if [ -f .env ]; then
        export $(cat .env | grep -v '#' | xargs)
    else
        echo -e "${RED}Error: .env file not found${NC}"
        exit 1
    fi
}

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

# Version management functions
get_version_number() {
    local version=""
    
    if [ "$SDK" = "react-native" ]; then
        version=$(grep "version" "$PROJECT_PATH/package.json" | head -1 | awk -F: '{ print $2 }' | sed 's/[",]//g' | tr -d '[[:space:]]')
    elif [ "$SDK" = "flutter" ]; then
        version=$(grep "version:" "$PROJECT_PATH/pubspec.yaml" | head -1 | awk '{ print $2 }' | sed 's/+.*$//')
    fi
    
    echo "$version"
}

get_build_number() {
    local build_number=""
    
    if [ "$SDK" = "react-native" ]; then
        if [ -f "$PROJECT_PATH/ios/build_number" ]; then
            build_number=$(cat "$PROJECT_PATH/ios/build_number")
        else
            build_number="1"
        fi
    elif [ "$SDK" = "flutter" ]; then
        build_number=$(grep "version:" "$PROJECT_PATH/pubspec.yaml" | head -1 | awk -F'+' '{ print $2 }')
    fi
    
    echo "$build_number"
}

increment_build_number() {
    local current_build_number=$(get_build_number)
    local new_build_number=$((current_build_number + 1))
    
    if [ "$SDK" = "react-native" ]; then
        echo "$new_build_number" > "$PROJECT_PATH/ios/build_number"
        # Update Info.plist
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $new_build_number" "$PROJECT_PATH/ios/$PROJECT_NAME/Info.plist"
    elif [ "$SDK" = "flutter" ]; then
        local version=$(get_version_number)
        sed -i '' "s/version: .*$/version: $version+$new_build_number/" "$PROJECT_PATH/pubspec.yaml"
    fi
    
    echo "$new_build_number"
}

# Notification functions
send_notification() {
    local status=$1
    local platform=$2
    local environment=$3
    local version=$4
    local build_number=$5
    local artifact_path=$6
    local error_message=$7
    
    # Prepare notification message
    local title="🚀 Build $status: $PROJECT_NAME ($platform)"
    local content="Environment: $environment\nVersion: $version ($build_number)"
    
    if [ "$status" = "success" ]; then
        content="$content\n✅ Build completed successfully!"
        if [ ! -z "$artifact_path" ]; then
            # Upload to Google Drive if configured
            if [ ! -z "$GOOGLE_DRIVE_FOLDER_ID" ]; then
                local download_link=$(upload_to_drive "$artifact_path")
                content="$content\n📥 Download: $download_link"
            fi
        fi
    else
        content="$content\n❌ Build failed!\nError: $error_message"
    fi
    
    # Send to Lark if webhook is configured
    if [ ! -z "$LARK_BOT_NOTIFY_WEBHOOK" ]; then
        send_to_lark "$title" "$content"
    fi
}

send_to_lark() {
    local title=$1
    local content=$2
    local timestamp=$(date +%s)
    local sign=""
    
    # Generate signature if verification is enabled
    if [ ! -z "$LARK_BOT_SIGNATURE_VERIFICATION" ]; then
        string_to_sign="$timestamp\n$LARK_BOT_SIGNATURE_VERIFICATION"
        sign=$(echo -n "$string_to_sign" | openssl sha256 -hmac "$LARK_BOT_SIGNATURE_VERIFICATION" -binary | base64)
    fi
    
    # Prepare JSON payload
    local json_payload=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "sign": "$sign",
    "msg_type": "post",
    "content": {
        "post": {
            "zh_cn": {
                "title": "$title",
                "content": [
                    [
                        {
                            "tag": "text",
                            "text": "$content"
                        }
                    ]
                ]
            }
        }
    }
}
EOF
)
    
    # Send notification to Lark
    curl -X POST -H "Content-Type: application/json" \
        -d "$json_payload" \
        "$LARK_BOT_NOTIFY_WEBHOOK"
}

# Google Drive upload function
upload_to_drive() {
    local file_path=$1
    local filename=$(basename "$file_path")
    local mime_type="application/octet-stream"
    
    if [ -z "$GOOGLE_DRIVE_CREDENTIALS" ] || [ -z "$GOOGLE_DRIVE_FOLDER_ID" ]; then
        log_warning "Google Drive credentials not configured. Skipping upload."
        return
    fi
    
    # Decode Google Drive credentials
    echo "$GOOGLE_DRIVE_CREDENTIALS" | base64 -d > credentials.json
    
    # Get access token
    local access_token=$(curl -s "https://oauth2.googleapis.com/token" \
        -d "$(cat credentials.json)" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        | jq -r '.access_token')
    
    # Upload file
    local upload_response=$(curl -s -X POST \
        "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: multipart/related" \
        -F "metadata={name:'$filename',parents:['$GOOGLE_DRIVE_FOLDER_ID']};type=application/json;charset=UTF-8" \
        -F "file=@$file_path;type=$mime_type")
    
    # Get file ID
    local file_id=$(echo "$upload_response" | jq -r '.id')
    
    # Create shareable link
    local share_response=$(curl -s -X POST \
        "https://www.googleapis.com/drive/v3/files/$file_id/permissions" \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -d '{"role":"reader","type":"anyone"}')
    
    # Clean up
    rm credentials.json
    
    # Return download link
    echo "https://drive.google.com/file/d/$file_id/view?usp=sharing"
}

# TestFlight upload function
upload_to_testflight() {
    local ipa_path=$1
    
    if [ -z "$FASTLANE_APPLE_ID" ] || [ -z "$FASTLANE_PASSWORD" ]; then
        log_error "TestFlight credentials not configured"
        exit 1
    fi
    
    # Use fastlane to upload
    fastlane pilot upload \
        --ipa "$ipa_path" \
        --skip_waiting_for_build_processing \
        --apple_id "$FASTLANE_APPLE_ID" \
        --team_id "$DEVELOPMENT_TEAM"
}

# Validate required environment variables
validate_env() {
    local required_vars=("PROJECT_NAME" "PROJECT_PATH" "SDK")
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
}

# Check if running on macOS for iOS builds
check_macos() {
    if [ "$(uname)" != "Darwin" ]; then
        log_error "iOS builds require macOS"
        exit 1
    fi
}

# Check if Xcode is installed
check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode is not installed"
        exit 1
    fi
}

# Initialize build environment
init_build_env() {
    validate_env
    
    if [ "$1" = "ios" ]; then
        check_macos
        check_xcode
    fi
} 