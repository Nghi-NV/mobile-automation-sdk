#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
TEST_RESULTS_DIR="$PROJECT_PATH/test-results/ui"
DEVICES=(
    "iPhone 14 Pro Max"
    "iPad Pro (12.9-inch)"
)

# Function to run iOS UI tests
run_ios_ui_tests() {
    log_info "Running iOS UI tests..."
    
    # Build for testing
    xcodebuild \
        -workspace "$PROJECT_PATH/ios/$PROJECT_NAME.xcworkspace" \
        -scheme "$PROJECT_NAME" \
        -destination 'platform=iOS Simulator,name=iPhone 14 Pro Max' \
        -derivedDataPath "$TEST_RESULTS_DIR" \
        test
}

# Function to run Android UI tests
run_android_ui_tests() {
    log_info "Running Android UI tests..."
    
    cd "$PROJECT_PATH/android"
    
    # Run instrumented tests
    ./gradlew connectedAndroidTest
}

# Function to generate test report
generate_report() {
    log_info "Generating test report..."
    
    # Create report directory
    mkdir -p "$TEST_RESULTS_DIR/report"
    
    # Generate HTML report
    # Add your reporting tool here
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <platform> [--report]"
        log_error "Platforms: ios, android, all"
        exit 1
    fi
    
    local platform=$1
    local generate_report=${2:-false}
    
    case "$platform" in
        "ios")
            run_ios_ui_tests
            ;;
        "android")
            run_android_ui_tests
            ;;
        "all")
            run_ios_ui_tests
            run_android_ui_tests
            ;;
        *)
            log_error "Invalid platform: $platform"
            exit 1
            ;;
    esac
    
    if [ "$generate_report" = true ]; then
        generate_report
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 