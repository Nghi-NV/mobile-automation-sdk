#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
SCREENSHOTS_DIR="$PROJECT_PATH/fastlane/screenshots"
DEVICES=(
    "iPhone 8 Plus"
    "iPhone 11 Pro Max"
    "iPhone 14 Pro Max"
    "iPad Pro (12.9-inch) (6th generation)"
)
LANGUAGES=("en-US" "ja" "ko" "vi")

# Function to setup Fastlane
setup_fastlane() {
    if [ ! -d "$PROJECT_PATH/fastlane" ]; then
        log_info "Initializing Fastlane..."
        cd "$PROJECT_PATH"
        fastlane init
    fi
    
    # Create Snapfile if not exists
    if [ ! -f "$PROJECT_PATH/fastlane/Snapfile" ]; then
        create_snapfile
    fi
}

# Function to create Snapfile
create_snapfile() {
    cat > "$PROJECT_PATH/fastlane/Snapfile" <<EOF
# Devices to take screenshots on
devices([
    "iPhone 8 Plus",
    "iPhone 11 Pro Max",
    "iPhone 14 Pro Max",
    "iPad Pro (12.9-inch) (6th generation)"
])

# Languages
languages([
    "en-US",
    "ja",
    "ko",
    "vi"
])

# The name of the scheme to build
scheme("YourApp")

# Where to store the screenshots
output_directory("./fastlane/screenshots")

# Clear previous screenshots
clear_previous_screenshots(true)

# Arguments to pass to the app on launch
launch_arguments(["-UITest"])

# Config to use for building
configuration("Debug")
EOF
}

# Function to capture screenshots for iOS
capture_ios_screenshots() {
    log_info "Capturing iOS screenshots..."
    
    cd "$PROJECT_PATH"
    
    # Run Fastlane snapshot
    fastlane snapshot
    
    # Create HTML report
    fastlane snapshot html
}

# Function to capture screenshots for Android
capture_android_screenshots() {
    log_info "Capturing Android screenshots..."
    
    cd "$PROJECT_PATH"
    
    for device in "${DEVICES[@]}"; do
        for language in "${LANGUAGES[@]}"; do
            log_info "Capturing screenshots for $device in $language"
            
            # Start emulator
            start_android_emulator "$device"
            
            # Change language
            adb shell "setprop persist.sys.locale $language"
            adb shell am broadcast -a android.intent.action.LOCALE_CHANGED
            
            # Run tests with screenshot capture
            ./gradlew app:executeScreenshotTests -Precord
        done
    done
}

# Function to process screenshots
process_screenshots() {
    log_info "Processing screenshots..."
    
    # Create output directory
    mkdir -p "$SCREENSHOTS_DIR/processed"
    
    # Process each screenshot
    find "$SCREENSHOTS_DIR" -name "*.png" | while read -r file; do
        # Add device frame
        fastlane frameit "$file"
        
        # Optimize image
        optimize_image "$file"
    done
}

# Function to optimize image
optimize_image() {
    local file=$1
    
    # Check if pngquant is installed
    if ! command -v pngquant &> /dev/null; then
        brew install pngquant
    fi
    
    # Optimize PNG
    pngquant --force --quality=80-95 "$file" --output "${file%.*}_optimized.png"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <platform> [--process]"
        log_error "Platforms: ios, android, all"
        exit 1
    fi
    
    local platform=$1
    local should_process=${2:-false}
    
    # Setup Fastlane
    setup_fastlane
    
    case "$platform" in
        "ios")
            capture_ios_screenshots
            ;;
        "android")
            capture_android_screenshots
            ;;
        "all")
            capture_ios_screenshots
            capture_android_screenshots
            ;;
        *)
            log_error "Invalid platform: $platform"
            exit 1
            ;;
    esac
    
    # Process screenshots if requested
    if [ "$should_process" = true ]; then
        process_screenshots
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 