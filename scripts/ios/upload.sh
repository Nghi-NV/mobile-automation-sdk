#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
FASTLANE_DIR="$PROJECT_PATH/ios/fastlane"
FASTFILE_PATH="$FASTLANE_DIR/Fastfile"
APPFILE_PATH="$FASTLANE_DIR/Appfile"

# Function to check and install fastlane
check_fastlane() {
    if ! command -v fastlane &> /dev/null; then
        log_info "Installing fastlane..."
        gem install fastlane -N
    fi
}

# Function to initialize fastlane if not already set up
init_fastlane() {
    if [ ! -d "$FASTLANE_DIR" ]; then
        log_info "Initializing fastlane..."
        mkdir -p "$FASTLANE_DIR"
        
        # Create Appfile
        cat > "$APPFILE_PATH" <<EOF
app_identifier("$DEVELOPER_APP_IDENTIFIER")
apple_id("$FASTLANE_APPLE_ID")
team_id("$DEVELOPMENT_TEAM")

# For more information about the Appfile, see:
# https://docs.fastlane.tools/advanced/#appfile
EOF
        
        # Create Fastfile
        cat > "$FASTFILE_PATH" <<EOF
default_platform(:ios)

platform :ios do
  desc "Upload to TestFlight"
  lane :upload_testflight do |options|
    api_key = app_store_connect_api_key(
      key_id: ENV["ASC_KEY_ID"],
      issuer_id: ENV["ASC_ISSUER_ID"],
      key_content: ENV["ASC_KEY"],
      is_key_content_base64: true
    )

    upload_to_testflight(
      api_key: api_key,
      ipa: options[:ipa_path],
      skip_waiting_for_build_processing: true,
      changelog: options[:changelog],
      distribute_external: options[:distribute_external],
      groups: options[:groups],
      notify_external_testers: options[:notify_testers]
    )
  end
end
EOF
    fi
}

# Function to validate required environment variables for upload
validate_upload_env() {
    local required_vars=(
        "DEVELOPER_APP_IDENTIFIER"
        "FASTLANE_APPLE_ID"
        "FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD"
        "ASC_KEY_ID"
        "ASC_ISSUER_ID"
        "ASC_KEY"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
}

# Function to upload IPA to TestFlight
upload_to_testflight() {
    local ipa_path=$1
    local version=$2
    local build_number=$3
    local changelog=$4
    local distribute_external=${5:-false}
    local groups=${6:-""}
    local notify_testers=${7:-false}
    
    if [ ! -f "$ipa_path" ]; then
        log_error "IPA file not found at: $ipa_path"
        exit 1
    }
    
    log_info "Starting upload to TestFlight..."
    log_info "IPA: $ipa_path"
    log_info "Version: $version ($build_number)"
    
    # Default changelog if not provided
    if [ -z "$changelog" ]; then
        changelog="Version $version ($build_number)"
    fi
    
    # Navigate to iOS directory
    cd "$PROJECT_PATH/ios"
    
    # Execute fastlane upload
    fastlane upload_testflight \
        ipa_path:"$ipa_path" \
        changelog:"$changelog" \
        distribute_external:"$distribute_external" \
        groups:"$groups" \
        notify_testers:"$notify_testers" || {
            log_error "Failed to upload to TestFlight"
            exit 1
        }
    
    log_info "Successfully uploaded to TestFlight"
}

# Function to handle the upload process
handle_upload() {
    local ipa_path=$1
    local version=$2
    local build_number=$3
    local changelog=$4
    local distribute_external=$5
    local groups=$6
    local notify_testers=$7
    
    # Validate environment
    validate_upload_env
    
    # Check and install fastlane
    check_fastlane
    
    # Initialize fastlane configuration
    init_fastlane
    
    # Start upload notification
    notify_build_start "iOS" "TestFlight" "$version" "$build_number"
    
    # Attempt upload
    if upload_to_testflight \
        "$ipa_path" \
        "$version" \
        "$build_number" \
        "$changelog" \
        "$distribute_external" \
        "$groups" \
        "$notify_testers"; then
        
        # Send success notification
        notify_build_success "iOS" "TestFlight" "$version" "$build_number" "$ipa_path"
    else
        # Send failure notification
        notify_build_failure "iOS" "TestFlight" "$version" "$build_number" "Failed to upload to TestFlight"
        exit 1
    fi
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <ipa_path> [changelog] [distribute_external] [groups] [notify_testers]"
        exit 1
    fi
    
    local ipa_path=$1
    local version=$(get_version_number)
    local build_number=$(get_build_number)
    local changelog=${2:-""}
    local distribute_external=${3:-false}
    local groups=${4:-""}
    local notify_testers=${5:-false}
    
    handle_upload \
        "$ipa_path" \
        "$version" \
        "$build_number" \
        "$changelog" \
        "$distribute_external" \
        "$groups" \
        "$notify_testers"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 