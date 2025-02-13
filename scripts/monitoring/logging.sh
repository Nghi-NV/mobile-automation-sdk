#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
LOG_DIR="$PROJECT_PATH/logs"
MAX_LOG_SIZE=100M
MAX_LOG_AGE=7 # days
LOG_LEVELS=("debug" "info" "warning" "error")

# Function to setup logging
setup_logging() {
    log_info "Setting up logging..."
    
    # Create log directories
    for level in "${LOG_LEVELS[@]}"; do
        mkdir -p "$LOG_DIR/$level"
    done
    
    # Create log rotation config
    cat > "/etc/logrotate.d/$PROJECT_NAME" <<EOF
$LOG_DIR/*/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    size $MAX_LOG_SIZE
}
EOF
    
    log_success "Logging setup completed"
}

# Function to collect logs
collect_logs() {
    log_info "Collecting logs..."
    
    local platform=$1
    local level=${2:-"all"}
    local output_dir="$LOG_DIR/collected/$(date +%Y%m%d)"
    
    mkdir -p "$output_dir"
    
    case "$platform" in
        "ios")
            # Collect iOS logs
            if [ "$level" = "all" ] || [ "$level" = "system" ]; then
                xcrun simctl spawn booted log collect --start "$(date -v-1d '+%Y-%m-%d')" > "$output_dir/ios_system.log"
            fi
            
            if [ "$level" = "all" ] || [ "$level" = "app" ]; then
                xcrun simctl spawn booted log show --predicate "processImagePath contains '$PROJECT_NAME'" > "$output_dir/ios_app.log"
            fi
            ;;
            
        "android")
            # Collect Android logs
            if [ "$level" = "all" ] || [ "$level" = "system" ]; then
                adb logcat -d > "$output_dir/android_system.log"
            fi
            
            if [ "$level" = "all" ] || [ "$level" = "app" ]; then
                adb logcat -d | grep "$PROJECT_NAME" > "$output_dir/android_app.log"
            fi
            ;;
            
        *)
            log_error "Invalid platform: $platform"
            exit 1
            ;;
    esac
    
    log_success "Logs collected in: $output_dir"
}

# Function to analyze logs
analyze_logs() {
    log_info "Analyzing logs..."
    
    local log_file=$1
    local report_file="$LOG_DIR/analysis_$(date +%Y%m%d).txt"
    
    echo "Log Analysis Report" > "$report_file"
    echo "==================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "Analyzed file: $log_file" >> "$report_file"
    echo "" >> "$report_file"
    
    # Error frequency
    echo "Error Frequency:" >> "$report_file"
    grep -i "error" "$log_file" | sort | uniq -c | sort -nr >> "$report_file"
    
    # Warning frequency
    echo "" >> "$report_file"
    echo "Warning Frequency:" >> "$report_file"
    grep -i "warning" "$log_file" | sort | uniq -c | sort -nr >> "$report_file"
    
    # Performance issues
    echo "" >> "$report_file"
    echo "Performance Issues:" >> "$report_file"
    grep -i "slow\|timeout\|memory\|crash" "$log_file" >> "$report_file"
    
    log_success "Analysis report generated: $report_file"
}

# Function to cleanup old logs
cleanup_logs() {
    log_info "Cleaning up old logs..."
    
    find "$LOG_DIR" -type f -name "*.log" -mtime +$MAX_LOG_AGE -delete
    find "$LOG_DIR/collected" -type d -mtime +$MAX_LOG_AGE -exec rm -rf {} +
    
    log_success "Cleaned up logs older than $MAX_LOG_AGE days"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <command> [platform|log_file] [level]"
        log_error "Commands: setup, collect, analyze, cleanup"
        log_error "Platforms: ios, android"
        log_error "Levels: system, app, all"
        exit 1
    fi
    
    local command=$1
    shift
    
    case "$command" in
        "setup")
            setup_logging
            ;;
        "collect")
            if [ $# -lt 1 ]; then
                log_error "Platform required for collection"
                exit 1
            fi
            collect_logs "$1" "${2:-all}"
            ;;
        "analyze")
            if [ $# -lt 1 ]; then
                log_error "Log file required for analysis"
                exit 1
            fi
            analyze_logs "$1"
            ;;
        "cleanup")
            cleanup_logs
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