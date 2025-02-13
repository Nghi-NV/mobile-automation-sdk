#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
ASSETS_DIR="$PROJECT_PATH/assets"
OUTPUT_DIR="$PROJECT_PATH/assets/optimized"

# Function to optimize images
optimize_images() {
    log_info "Optimizing images..."
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR/images"
    
    # Find all images
    find "$ASSETS_DIR" -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" \) | while read -r file; do
        local filename=$(basename "$file")
        local output="$OUTPUT_DIR/images/$filename"
        
        # Optimize PNG
        if [[ "$file" == *.png ]]; then
            if ! command -v pngquant &> /dev/null; then
                brew install pngquant
            fi
            pngquant --force --quality=80-95 "$file" --output "$output"
            
        # Optimize JPEG
        elif [[ "$file" =~ \.jpe?g$ ]]; then
            if ! command -v jpegoptim &> /dev/null; then
                brew install jpegoptim
            fi
            jpegoptim -m80 --strip-all --stdout "$file" > "$output"
        fi
        
        log_success "Optimized: $filename"
    done
}

# Function to optimize fonts
optimize_fonts() {
    log_info "Optimizing fonts..."
    
    mkdir -p "$OUTPUT_DIR/fonts"
    
    # Find all fonts
    find "$ASSETS_DIR" -type f \( -name "*.ttf" -o -name "*.otf" \) | while read -r file; do
        local filename=$(basename "$file")
        local output="$OUTPUT_DIR/fonts/$filename"
        
        # Use fonttools to subset fonts
        if ! command -v pyftsubset &> /dev/null; then
            pip install fonttools
        fi
        
        pyftsubset "$file" \
            --output-file="$output" \
            --unicodes="*" \
            --layout-features="*" \
            --flavor="woff2"
            
        log_success "Optimized: $filename"
    done
}

# Function to optimize videos
optimize_videos() {
    log_info "Optimizing videos..."
    
    mkdir -p "$OUTPUT_DIR/videos"
    
    # Find all videos
    find "$ASSETS_DIR" -type f \( -name "*.mp4" -o -name "*.mov" \) | while read -r file; do
        local filename=$(basename "$file")
        local output="$OUTPUT_DIR/videos/$filename"
        
        # Use ffmpeg to optimize
        if ! command -v ffmpeg &> /dev/null; then
            brew install ffmpeg
        fi
        
        ffmpeg -i "$file" \
            -c:v libx264 -crf 23 \
            -c:a aac -b:a 128k \
            "$output"
            
        log_success "Optimized: $filename"
    done
}

# Function to generate size report
generate_size_report() {
    log_info "Generating size report..."
    
    local report_file="$OUTPUT_DIR/optimization_report.txt"
    
    echo "Asset Optimization Report" > "$report_file"
    echo "======================" >> "$report_file"
    echo "" >> "$report_file"
    
    # Compare sizes
    find "$ASSETS_DIR" -type f | while read -r original; do
        local filename=$(basename "$original")
        local optimized="$OUTPUT_DIR/${original#$ASSETS_DIR/}"
        
        if [ -f "$optimized" ]; then
            local original_size=$(stat -f %z "$original")
            local optimized_size=$(stat -f %z "$optimized")
            local saved_size=$((original_size - optimized_size))
            local saved_percent=$(bc <<< "scale=2; ($saved_size / $original_size) * 100")
            
            echo "File: $filename" >> "$report_file"
            echo "Original: $(numfmt --to=iec-i --suffix=B $original_size)" >> "$report_file"
            echo "Optimized: $(numfmt --to=iec-i --suffix=B $optimized_size)" >> "$report_file"
            echo "Saved: $(numfmt --to=iec-i --suffix=B $saved_size) ($saved_percent%)" >> "$report_file"
            echo "" >> "$report_file"
        fi
    done
    
    log_success "Report generated: $report_file"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <asset_type> [--report]"
        log_error "Asset types: images, fonts, videos, all"
        exit 1
    fi
    
    local asset_type=$1
    local generate_report=${2:-false}
    
    case "$asset_type" in
        "images")
            optimize_images
            ;;
        "fonts")
            optimize_fonts
            ;;
        "videos")
            optimize_videos
            ;;
        "all")
            optimize_images
            optimize_fonts
            optimize_videos
            ;;
        *)
            log_error "Invalid asset type: $asset_type"
            exit 1
            ;;
    esac
    
    if [ "$generate_report" = true ]; then
        generate_size_report
    fi
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 