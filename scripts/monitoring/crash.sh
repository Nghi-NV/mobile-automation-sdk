#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
CRASH_DIR="$PROJECT_PATH/logs/crashes"
SYMBOLICATE_DIR="$PROJECT_PATH/logs/symbolication"
MAX_CRASH_AGE=30 # days

# Function to setup crash reporting
setup_crash_reporting() {
    log_info "Setting up crash reporting..."
    
    # Create directories
    mkdir -p "$CRASH_DIR"
    mkdir -p "$SYMBOLICATE_DIR"
    
    # iOS setup
    if [ "$1" = "ios" ] || [ "$1" = "all" ]; then
        # Setup PLCrashReporter
        if ! grep -q "pod 'PLCrashReporter'" "$PROJECT_PATH/ios/Podfile"; then
            echo "pod 'PLCrashReporter'" >> "$PROJECT_PATH/ios/Podfile"
            cd "$PROJECT_PATH/ios" && pod install
        fi
    fi
    
    # Android setup
    if [ "$1" = "android" ] || [ "$1" = "all" ]; then
        # Setup Firebase Crashlytics
        if ! grep -q "com.google.firebase:firebase-crashlytics" "$PROJECT_PATH/android/app/build.gradle"; then
            echo "implementation 'com.google.firebase:firebase-crashlytics'" >> "$PROJECT_PATH/android/app/build.gradle"
        fi
    fi
}

# Function to collect crash reports
collect_crash_reports() {
    log_info "Collecting crash reports..."
    
    local platform=$1
    local output_dir="$CRASH_DIR/$(date +%Y%m%d)"
    mkdir -p "$output_dir"
    
    case "$platform" in
        "ios")
            # Collect iOS crash logs
            find ~/Library/Logs/DiagnosticReports -name "*.crash" -mtime -1 -exec cp {} "$output_dir/" \;
            ;;
        "android")
            # Collect Android crash logs
            adb logcat -b crash -d > "$output_dir/android_crash.log"
            ;;
        *)
            log_error "Invalid platform: $platform"
            exit 1
            ;;
    esac
    
    log_success "Crash reports collected in: $output_dir"
}

# Function to symbolicate crash reports
symbolicate_crash_reports() {
    log_info "Symbolicating crash reports..."
    
    local platform=$1
    local crash_file=$2
    
    case "$platform" in
        "ios")
            # Symbolicate iOS crash reports
            if [ ! -f "$crash_file" ]; then
                log_error "Crash file not found: $crash_file"
                exit 1
            fi
            
            xcrun atos -o "$PROJECT_PATH/ios/build/Release-iphoneos/$PROJECT_NAME.app.dSYM/Contents/Resources/DWARF/$PROJECT_NAME" -arch arm64 -l <(cat "$crash_file")
            ;;
        "android")
            # Symbolicate Android crash reports
            if [ ! -f "$crash_file" ]; then
                log_error "Crash file not found: $crash_file"
                exit 1
            }
            
            "$ANDROID_HOME/cmdline-tools/latest/bin/ndk-stack" -sym "$PROJECT_PATH/android/app/build/intermediates/merged_native_libs/release/out/lib" -dump "$crash_file"
            ;;
        *)
            log_error "Invalid platform: $platform"
            exit 1
            ;;
    esac
}

# Function to analyze crash patterns
analyze_crash_patterns() {
    log_info "Analyzing crash patterns..."
    
    local report_file="$CRASH_DIR/analysis_$(date +%Y%m%d).txt"
    
    echo "Crash Analysis Report" > "$report_file"
    echo "===================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Analyze crash frequency
    echo "Crash Frequency by Type:" >> "$report_file"
    find "$CRASH_DIR" -type f -name "*.crash" -exec grep "Exception Type:" {} \; | \
        sort | uniq -c | sort -nr >> "$report_file"
    
    # Find most common stack traces
    echo "" >> "$report_file"
    echo "Most Common Stack Traces:" >> "$report_file"
    find "$CRASH_DIR" -type f -name "*.crash" -exec grep -A 5 "Thread 0 Crashed:" {} \; | \
        sort | uniq -c | sort -nr | head -n 10 >> "$report_file"
    
    log_success "Analysis report generated: $report_file"
}

# Function to cleanup old crash reports
cleanup_crash_reports() {
    log_info "Cleaning up old crash reports..."
    
    find "$CRASH_DIR" -type f -mtime +$MAX_CRASH_AGE -delete
    find "$SYMBOLICATE_DIR" -type f -mtime +$MAX_CRASH_AGE -delete
    
    log_success "Cleaned up crash reports older than $MAX_CRASH_AGE days"
}

# Main function
main() {
    if [ $# -lt 2 ]; then
        log_error "Usage: $0 <command> <platform> [file]"
        log_error "Commands: setup, collect, symbolicate, analyze, cleanup"
        log_error "Platforms: ios, android, all"
        exit 1
    fi
    
    local command=$1
    local platform=$2
    local file=$3
    
    case "$command" in
        "setup")
            setup_crash_reporting "$platform"
            ;;
        "collect")
            collect_crash_reports "$platform"
            ;;
        "symbolicate")
            if [ -z "$file" ]; then
                log_error "Crash file path required for symbolication"
                exit 1
            fi
            symbolicate_crash_reports "$platform" "$file"
            ;;
        "analyze")
            analyze_crash_patterns
            ;;
        "cleanup")
            cleanup_crash_reports
            ;;
        *)
            log_error "Invalid command: $command"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 