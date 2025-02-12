#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
FASTLANE_DIR="$PROJECT_PATH/android/fastlane"
FASTFILE_PATH="$FASTLANE_DIR/Fastfile"
APPFILE_PATH="$FASTLANE_DIR/Appfile"
METADATA_DIR="$FASTLANE_DIR/metadata"

# Function to validate Play Store environment
validate_play_store_env() {
    local required_vars=(
        "GOOGLE_DRIVE_CREDENTIALS"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
}

# Function to initialize fastlane
init_fastlane() {
    if [ ! -d "$FASTLANE_DIR" ]; then
        log_info "Initializing fastlane..."
        mkdir -p "$FASTLANE_DIR"
        
        # Create Appfile
        cat > "$APPFILE_PATH" <<EOF
json_key_file("play-store-credentials.json")
package_name("$DEVELOPER_APP_IDENTIFIER")
EOF
        
        # Create Fastfile
        cat > "$FASTFILE_PATH" <<EOF
default_platform(:android)

platform :android do
  desc "Upload to Play Store"
  lane :upload_play_store do |options|
    upload_to_play_store(
      track: options[:track],
      aab: options[:aab_path],
      skip_upload_apk: true,
      skip_upload_metadata: false,
      skip_upload_images: true,
      skip_upload_screenshots: true,
      release_status: options[:release_status],
      version_name: options[:version_name],
      version_code: options[:version_code].to_i
    )
  end
end
EOF
    fi
}

# Function to setup Play Store credentials
setup_credentials() {
    log_info "Setting up Play Store credentials..."
    
    # Decode and save credentials
    echo "$GOOGLE_DRIVE_CREDENTIALS" | base64 -d > "$FASTLANE_DIR/play-store-credentials.json"
}

# Function to prepare release notes
prepare_release_notes() {
    local version=$1
    local build_number=$2
    local environment=$3
    
    mkdir -p "$METADATA_DIR/android/en-US/changelogs"
    
    # Create default release notes if not exists
    local changelog_file="$METADATA_DIR/android/en-US/changelogs/$build_number.txt"
    if [ ! -f "$changelog_file" ]; then
        echo "Version $version ($build_number) - $environment" > "$changelog_file"
        echo "- New features and improvements" >> "$changelog_file"
        echo "- Bug fixes and performance enhancements" >> "$changelog_file"
    fi
}

# Function to determine release track
get_release_track() {
    local environment=$1
    
    case "$environment" in
        "development")
            echo "internal"
            ;;
        "staging")
            echo "beta"
            ;;
        "production")
            echo "production"
            ;;
        *)
            log_error "Invalid environment: $environment"
            exit 1
            ;;
    esac
}

# Function to upload to Play Store
upload_to_play_store() {
    local artifact_path=$1
    local environment=$2
    local version=$3
    local build_number=$4
    
    if [ ! -f "$artifact_path" ]; then
        log_error "Artifact file not found at: $artifact_path"
        exit 1
    fi
    
    # Get release track
    local track=$(get_release_track "$environment")
    
    # Determine release status
    local release_status="completed"
    if [ "$environment" = "development" ]; then
        release_status="draft"
    fi
    
    log_info "Uploading to Play Store..."
    log_info "Track: $track"
    log_info "Version: $version ($build_number)"
    
    # Navigate to android directory
    cd "$PROJECT_PATH/android"
    
    # Execute fastlane upload
    fastlane upload_play_store \
        track:"$track" \
        aab_path:"$artifact_path" \
        release_status:"$release_status" \
        version_name:"$version" \
        version_code:"$build_number" || {
            log_error "Failed to upload to Play Store"
            return 1
        }
    
    log_info "Successfully uploaded to Play Store"
    return 0
}

# Function to handle the upload process
handle_upload() {
    local artifact_path=$1
    local environment=$2
    local version=$3
    local build_number=$4
    
    # Validate environment
    validate_play_store_env
    
    # Initialize fastlane
    init_fastlane
    
    # Setup credentials
    setup_credentials
    
    # Prepare release notes
    prepare_release_notes "$version" "$build_number" "$environment"
    
    # Start upload notification
    notify_build_start "Android" "Play Store" "$version" "$build_number"
    
    # Attempt upload
    if upload_to_play_store \
        "$artifact_path" \
        "$environment" \
        "$version" \
        "$build_number"; then
        
        # Send success notification
        notify_build_success "Android" "Play Store" "$version" "$build_number" "$artifact_path"
    else
        # Send failure notification
        notify_build_failure "Android" "Play Store" "$version" "$build_number" "Failed to upload to Play Store"
        exit 1
    fi
}

# Function to cleanup
cleanup() {
    # Remove credentials file
    rm -f "$FASTLANE_DIR/play-store-credentials.json"
}

# Main function
main() {
    if [ $# -lt 2 ]; then
        log_error "Usage: $0 <artifact_path> <environment>"
        exit 1
    fi
    
    local artifact_path=$1
    local environment=$2
    local version=$(get_version_number)
    local build_number=$(get_build_number)
    
    # Set trap for cleanup
    trap cleanup EXIT
    
    handle_upload \
        "$artifact_path" \
        "$environment" \
        "$version" \
        "$build_number"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 