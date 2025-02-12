#!/bin/bash

# Load environment variables
source "$(dirname "$0")/../common/utils.sh"
load_env

# Default values
ENVIRONMENT="development"
CLEAN_BUILD=false
SHOULD_UPLOAD=false
SHOULD_NOTIFY=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        development|staging|production) ENVIRONMENT="$1" ;;
        --clean) CLEAN_BUILD=true ;;
        --upload) SHOULD_UPLOAD=true ;;
        --notify) SHOULD_NOTIFY=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(development|staging|production)$ ]]; then
    echo "Error: Invalid environment. Must be one of: development, staging, production"
    exit 1
fi

# Configuration based on environment
case $ENVIRONMENT in
    development)
        CONFIGURATION="Debug"
        SCHEME="${PROJECT_NAME}_Dev"
        ;;
    staging)
        CONFIGURATION="Release"
        SCHEME="${PROJECT_NAME}_Staging"
        ;;
    production)
        CONFIGURATION="Release"
        SCHEME="${PROJECT_NAME}"
        ;;
esac

# Main build function
build_ios() {
    echo "🚀 Starting iOS build for $ENVIRONMENT environment..."
    
    # Navigate to iOS directory
    cd "$PROJECT_PATH/ios" || exit 1
    
    # Install pods if needed
    if [ ! -d "Pods" ] || [ "$CLEAN_BUILD" = true ]; then
        echo "📦 Installing CocoaPods dependencies..."
        pod install
    fi
    
    # Clean if requested
    if [ "$CLEAN_BUILD" = true ]; then
        echo "🧹 Cleaning build directory..."
        xcodebuild clean -workspace "$PROJECT_NAME.xcworkspace" -scheme "$SCHEME" -configuration "$CONFIGURATION"
    fi
    
    # Update build number
    current_version=$(get_version_number)
    new_build_number=$(increment_build_number)
    
    echo "📝 Building version $current_version ($new_build_number)"
    
    # Build archive
    echo "🏗 Building archive..."
    xcodebuild archive \
        -workspace "$PROJECT_NAME.xcworkspace" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -archivePath "build/$PROJECT_NAME.xcarchive" \
        CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
        PROVISIONING_PROFILE="$PROVISIONING_PROFILE" \
        DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
        | xcpretty || exit 1
        
    # Export IPA
    echo "📦 Exporting IPA..."
    xcodebuild -exportArchive \
        -archivePath "build/$PROJECT_NAME.xcarchive" \
        -exportOptionsPlist "exportOptions.plist" \
        -exportPath "build" \
        | xcpretty || exit 1
        
    # Get the path to the exported IPA
    IPA_PATH="build/$PROJECT_NAME.ipa"
    
    # Upload to TestFlight if requested
    if [ "$SHOULD_UPLOAD" = true ]; then
        echo "⬆️ Uploading to TestFlight..."
        upload_to_testflight "$IPA_PATH"
    fi
    
    # Send notification if requested
    if [ "$SHOULD_NOTIFY" = true ]; then
        if [ -f "$IPA_PATH" ]; then
            send_notification "success" "iOS" "$ENVIRONMENT" "$current_version" "$new_build_number" "$IPA_PATH"
        else
            send_notification "failure" "iOS" "$ENVIRONMENT" "$current_version" "$new_build_number"
        fi
    fi
    
    echo "✅ Build completed successfully!"
}

# Error handling
handle_error() {
    echo "❌ Build failed: $1"
    if [ "$SHOULD_NOTIFY" = true ]; then
        send_notification "failure" "iOS" "$ENVIRONMENT" "$(get_version_number)" "$(get_build_number)" "" "$1"
    fi
    exit 1
}

# Set error handler
trap 'handle_error "$BASH_COMMAND"' ERR

# Execute build
build_ios 