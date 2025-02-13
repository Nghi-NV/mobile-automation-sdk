#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
ASSETS_DIR="$PROJECT_PATH/assets"
OUTPUT_DIR="$PROJECT_PATH/lib/generated"

# Function to generate image constants
generate_image_constants() {
    log_info "Generating image constants..."
    
    local output_file="$OUTPUT_DIR/images.dart"
    
    # Create header
    cat > "$output_file" <<EOF
// Generated file - do not modify manually
// Generated by scripts/common/assets/generate.sh

class AppImages {
EOF
    
    # Generate constants for each image
    find "$ASSETS_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | while read -r file; do
        local filename=$(basename "$file")
        local name=$(echo "${filename%.*}" | tr '-' '_')
        local path="assets/${file#$ASSETS_DIR/}"
        
        echo "  static const String $name = '$path';" >> "$output_file"
    done
    
    # Close class
    echo "}" >> "$output_file"
    
    log_success "Generated: $output_file"
}

# Function to generate font constants
generate_font_constants() {
    log_info "Generating font constants..."
    
    local output_file="$OUTPUT_DIR/fonts.dart"
    
    cat > "$output_file" <<EOF
// Generated file - do not modify manually
// Generated by scripts/common/assets/generate.sh

class AppFonts {
EOF
    
    find "$ASSETS_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) | while read -r file; do
        local filename=$(basename "$file")
        local name=$(echo "${filename%.*}" | tr '-' '_')
        
        echo "  static const String $name = '$filename';" >> "$output_file"
    done
    
    echo "}" >> "$output_file"
    
    log_success "Generated: $output_file"
}

# Function to generate color constants
generate_color_constants() {
    log_info "Generating color constants..."
    
    local output_file="$OUTPUT_DIR/colors.dart"
    
    cat > "$output_file" <<EOF
// Generated file - do not modify manually
// Generated by scripts/common/assets/generate.sh

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF007AFF);
  static const Color secondary = Color(0xFF5856D6);
  static const Color success = Color(0xFF4CD964);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF000000);
  
  // Add your custom colors here
}
EOF
    
    log_success "Generated: $output_file"
}

# Function to update pubspec
update_pubspec() {
    log_info "Updating pubspec.yaml..."
    
    local pubspec="$PROJECT_PATH/pubspec.yaml"
    
    # Add assets section if not exists
    if ! grep -q "^flutter:" "$pubspec"; then
        echo "" >> "$pubspec"
        echo "flutter:" >> "$pubspec"
    fi
    
    if ! grep -q "^  assets:" "$pubspec"; then
        echo "  assets:" >> "$pubspec"
    fi
    
    # Add all assets
    find "$ASSETS_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | while read -r file; do
        local path="assets/${file#$ASSETS_DIR/}"
        if ! grep -q "    - $path" "$pubspec"; then
            echo "    - $path" >> "$pubspec"
        fi
    done
    
    # Add fonts section
    if ! grep -q "^  fonts:" "$pubspec"; then
        echo "  fonts:" >> "$pubspec"
    fi
    
    find "$ASSETS_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) | while read -r file; do
        local filename=$(basename "$file")
        if ! grep -q "      - asset: assets/fonts/$filename" "$pubspec"; then
            echo "    - family: ${filename%.*}" >> "$pubspec"
            echo "      fonts:" >> "$pubspec"
            echo "      - asset: assets/fonts/$filename" >> "$pubspec"
        fi
    done
    
    log_success "Updated: $pubspec"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <type> [--update-pubspec]"
        log_error "Types: images, fonts, colors, all"
        exit 1
    fi
    
    local type=$1
    local update_pub=${2:-false}
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    case "$type" in
        "images")
            generate_image_constants
            ;;
        "fonts")
            generate_font_constants
            ;;
        "colors")
            generate_color_constants
            ;;
        "all")
            generate_image_constants
            generate_font_constants
            generate_color_constants
            ;;
        *)
            log_error "Invalid type: $type"
            exit 1
            ;;
    esac
    
    if [ "$update_pub" = true ]; then
        update_pubspec
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 