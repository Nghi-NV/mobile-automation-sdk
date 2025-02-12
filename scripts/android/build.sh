#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
GRADLE_PROPERTIES="$PROJECT_PATH/android/gradle.properties"
KEYSTORE_PROPERTIES="$PROJECT_PATH/android/keystore.properties"
BUILD_DIR="$PROJECT_PATH/android/app/build/outputs"

# Function to validate Android environment
validate_android_env() {
    local required_vars=(
        "ANDROID_KEYSTORE_PATH"
        "ANDROID_KEYSTORE_PASSWORD"
        "ANDROID_KEY_ALIAS"
        "ANDROID_KEY_PASSWORD"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
    
    # Check if keystore file exists
    if [ ! -f "$ANDROID_KEYSTORE_PATH" ]; then
        log_error "Keystore file not found at: $ANDROID_KEYSTORE_PATH"
        exit 1
    fi
}

# Function to setup keystore properties
setup_keystore() {
    log_info "Setting up keystore properties..."
    
    # Create keystore.properties file
    cat > "$KEYSTORE_PROPERTIES" <<EOF
storeFile=$ANDROID_KEYSTORE_PATH
storePassword=$ANDROID_KEYSTORE_PASSWORD
keyAlias=$ANDROID_KEY_ALIAS
keyPassword=$ANDROID_KEY_PASSWORD
EOF
}

# Function to update version code and name
update_version() {
    local version=$(get_version_number)
    local build_number=$(get_build_number)
    
    log_info "Updating version to $version ($build_number)..."
    
    # Update build.gradle
    local gradle_file="$PROJECT_PATH/android/app/build.gradle"
    sed -i '' \
        -e "s/versionCode [0-9]*/versionCode $build_number/" \
        -e "s/versionName \".*\"/versionName \"$version\"/" \
        "$gradle_file"
}

# Function to clean project
clean_project() {
    log_info "Cleaning project..."
    
    cd "$PROJECT_PATH/android"
    ./gradlew clean
}

# Function to build APK/AAB
build_android() {
    local build_type=$1
    local is_aab=${2:-false}
    
    log_info "Building Android ${build_type}..."
    
    cd "$PROJECT_PATH/android"
    
    local task
    if [ "$is_aab" = true ]; then
        task="bundle${build_type^}"
        output_dir="$BUILD_DIR/bundle/$build_type"
    else
        task="assemble${build_type^}"
        output_dir="$BUILD_DIR/apk/$build_type"
    fi
    
    # Execute build
    if ! ./gradlew "$task"; then
        log_error "Build failed"
        return 1
    fi
    
    # Find built artifact
    local artifact_path
    if [ "$is_aab" = true ]; then
        artifact_path=$(find "$output_dir" -name "*.aab" | head -n 1)
    else
        artifact_path=$(find "$output_dir" -name "*.apk" | head -n 1)
    fi
    
    echo "$artifact_path"
}

# Function to handle the build process
handle_build() {
    local environment=$1
    local clean=${2:-false}
    local is_aab=false
    local should_upload=false
    local should_notify=false
    
    # Validate environment
    validate_android_env
    
    # Setup keystore
    setup_keystore
    
    # Clean if requested
    if [ "$clean" = true ]; then
        clean_project
    fi
    
    # Update version
    update_version
    
    # Determine build type based on environment
    local build_type
    case "$environment" in
        "development")
            build_type="debug"
            ;;
        "staging")
            build_type="release"
            ;;
        "production")
            build_type="release"
            ;;
        *)
            log_error "Invalid environment: $environment"
            exit 1
            ;;
    esac
    
    # Get current version info
    local version=$(get_version_number)
    local build_number=$(get_build_number)
    
    # Send start notification if requested
    if [ "$should_notify" = true ]; then
        notify_build_start "Android" "$environment" "$version" "$build_number"
    fi
    
    # Build the app
    local artifact_path=$(build_android "$build_type" "$is_aab")
    
    if [ $? -eq 0 ] && [ ! -z "$artifact_path" ]; then
        log_info "Build successful: $artifact_path"
        
        # Upload if requested
        if [ "$should_upload" = true ]; then
            if [ "$is_aab" = true ]; then
                upload_to_play_store "$artifact_path" "$environment"
            else
                upload_to_drive "$artifact_path"
            fi
        fi
        
        # Send success notification if requested
        if [ "$should_notify" = true ]; then
            notify_build_success "Android" "$environment" "$version" "$build_number" "$artifact_path"
        fi
    else
        log_error "Build failed"
        if [ "$should_notify" = true ]; then
            notify_build_failure "Android" "$environment" "$version" "$build_number" "Build failed"
        fi
        exit 1
    fi
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <environment> [--clean] [--aab] [--upload] [--notify]"
        exit 1
    fi
    
    local environment=$1
    shift
    
    local clean=false
    local is_aab=false
    local should_upload=false
    local should_notify=false
    
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --clean) clean=true ;;
            --aab) is_aab=true ;;
            --upload) should_upload=true ;;
            --notify) should_notify=true ;;
            *) log_error "Unknown parameter: $1"; exit 1 ;;
        esac
        shift
    done
    
    handle_build \
        "$environment" \
        "$clean" \
        "$is_aab" \
        "$should_upload" \
        "$should_notify"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 