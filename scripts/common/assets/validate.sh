#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
ASSETS_DIR="$PROJECT_PATH/assets"
SOURCE_DIR="$PROJECT_PATH/lib"
REPORT_DIR="$PROJECT_PATH/reports/assets"

# Function to find unused images
find_unused_images() {
    log_info "Finding unused images..."
    
    local report_file="$REPORT_DIR/unused_images.txt"
    mkdir -p "$REPORT_DIR"
    
    echo "Unused Images Report" > "$report_file"
    echo "===================" >> "$report_file"
    echo "" >> "$report_file"
    
    find "$ASSETS_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | while read -r file; do
        local filename=$(basename "$file")
        local path="assets/${file#$ASSETS_DIR/}"
        
        # Search for usage in source files
        if ! grep -r "$path" "$SOURCE_DIR" > /dev/null; then
            echo "- $path" >> "$report_file"
            log_warning "Unused image: $path"
        fi
    done
    
    log_success "Report generated: $report_file"
}

# Function to find unused fonts
find_unused_fonts() {
    log_info "Finding unused fonts..."
    
    local report_file="$REPORT_DIR/unused_fonts.txt"
    mkdir -p "$REPORT_DIR"
    
    echo "Unused Fonts Report" > "$report_file"
    echo "==================" >> "$report_file"
    echo "" >> "$report_file"
    
    find "$ASSETS_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) | while read -r file; do
        local filename=$(basename "$file")
        local fontname="${filename%.*}"
        
        # Search for usage in source files
        if ! grep -r "$fontname" "$SOURCE_DIR" > /dev/null; then
            echo "- $filename" >> "$report_file"
            log_warning "Unused font: $filename"
        fi
    done
    
    log_success "Report generated: $report_file"
}

# Function to check duplicate assets
find_duplicates() {
    log_info "Finding duplicate assets..."
    
    local report_file="$REPORT_DIR/duplicate_assets.txt"
    mkdir -p "$REPORT_DIR"
    
    echo "Duplicate Assets Report" > "$report_file"
    echo "======================" >> "$report_file"
    echo "" >> "$report_file"
    
    # Find duplicates by content
    find "$ASSETS_DIR" -type f -exec md5 {} \; | \
    sort | \
    awk '{print $4}' | \
    uniq -d | \
    while read -r hash; do
        echo "Duplicate files with hash $hash:" >> "$report_file"
        find "$ASSETS_DIR" -type f -exec md5 {} \; | grep "$hash" | awk '{print "- " $4}' >> "$report_file"
        echo "" >> "$report_file"
    done
    
    log_success "Report generated: $report_file"
}

# Function to check asset sizes
check_sizes() {
    log_info "Checking asset sizes..."
    
    local report_file="$REPORT_DIR/large_assets.txt"
    local size_limit=${1:-5242880} # Default 5MB
    
    mkdir -p "$REPORT_DIR"
    
    echo "Large Assets Report (>$(numfmt --to=iec-i --suffix=B $size_limit))" > "$report_file"
    echo "==================================================" >> "$report_file"
    echo "" >> "$report_file"
    
    find "$ASSETS_DIR" -type f -size +${size_limit}c | while read -r file; do
        local size=$(stat -f %z "$file")
        echo "- ${file#$ASSETS_DIR/} ($(numfmt --to=iec-i --suffix=B $size))" >> "$report_file"
        log_warning "Large asset: ${file#$ASSETS_DIR/}"
    done
    
    log_success "Report generated: $report_file"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <check_type> [size_limit]"
        log_error "Check types: unused, duplicates, sizes, all"
        exit 1
    fi
    
    local check_type=$1
    local size_limit=${2:-5242880}
    
    case "$check_type" in
        "unused")
            find_unused_images
            find_unused_fonts
            ;;
        "duplicates")
            find_duplicates
            ;;
        "sizes")
            check_sizes "$size_limit"
            ;;
        "all")
            find_unused_images
            find_unused_fonts
            find_duplicates
            check_sizes "$size_limit"
            ;;
        *)
            log_error "Invalid check type: $check_type"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 