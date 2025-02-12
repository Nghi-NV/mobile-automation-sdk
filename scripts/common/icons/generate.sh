#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
OUTPUT_DIR="$PROJECT_PATH/generated_icons"
IOS_ICON_CONFIG=(
    # size  idiom        scales
    "20    iphone      1,2,3"
    "29    iphone      2,3"
    "40    iphone      2,3"
    "60    iphone      2,3"
    "20    ipad        1,2"
    "29    ipad        1,2"
    "40    ipad        1,2"
    "76    ipad        1,2"
    "83.5  ipad        2"
    "1024  ios-marketing 1"
)
ANDROID_ICON_SIZES=(36 48 72 96 144 192)
ANDROID_ICON_TYPES=("mdpi" "hdpi" "xhdpi" "xxhdpi" "xxxhdpi")

# Function to generate iOS icons
generate_ios_icons() {
    local source_icon=$1
    local output_dir="$OUTPUT_DIR/ios"
    
    log_info "Generating iOS icons..."
    mkdir -p "$output_dir"
    
    # Generate icons for each configuration
    for config in "${IOS_ICON_CONFIG[@]}"; do
        read -r size idiom scales <<< "$config"
        IFS=',' read -ra scale_array <<< "$scales"
        
        for scale in "${scale_array[@]}"; do
            local actual_size=$(echo "$size * $scale" | bc)
            local filename="icon_${size}x${size}@${scale}x.png"
            
            convert "$source_icon" -resize "${actual_size}x${actual_size}" "$output_dir/$filename"
        done
    done
    
    log_info "iOS icons generated in: $output_dir"
}

# Function to generate Android icons
generate_android_icons() {
    local source_icon=$1
    local output_dir="$OUTPUT_DIR/android"
    
    log_info "Generating Android icons..."
    mkdir -p "$output_dir"
    
    # Generate icons for each density
    for i in "${!ANDROID_ICON_TYPES[@]}"; do
        local type="${ANDROID_ICON_TYPES[$i]}"
        local size="${ANDROID_ICON_SIZES[$i]}"
        local dir="$output_dir/$type"
        mkdir -p "$dir"
        
        # Regular icon
        convert "$source_icon" -resize "${size}x${size}" "$dir/ic_launcher.png"
        
        # Round icon
        convert "$source_icon" \
            -resize "${size}x${size}" \
            \( +clone -alpha extract -draw "circle ${size}/2,${size}/2 ${size}/2,0" -alpha copy \) \
            -compose copy_opacity -composite \
            "$dir/ic_launcher_round.png"
            
        # Adaptive icons
        convert "$source_icon" \
            -resize "70%" -gravity center -background transparent \
            -extent "108x108%" \
            "$dir/ic_launcher_foreground.png"
            
        convert -size 108x108 xc:"#FFFFFF" \
            "$dir/ic_launcher_background.png"
    done
    
    log_info "Android icons generated in: $output_dir"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <source_icon> [platform]"
        log_error "Platforms: ios, android, all (default)"
        exit 1
    fi
    
    local source_icon=$1
    local platform=${2:-"all"}
    
    # Check requirements
    check_imagemagick
    validate_icon "$source_icon"
    
    # Create output directory
    mkdir -p "$OUTPUT_DIR"
    
    case "$platform" in
        "ios")
            generate_ios_icons "$source_icon"
            ;;
        "android")
            generate_android_icons "$source_icon"
            ;;
        "all")
            generate_ios_icons "$source_icon"
            generate_android_icons "$source_icon"
            ;;
        *)
            log_error "Invalid platform: $platform"
            exit 1
            ;;
    esac
    
    log_info "All icons generated successfully in: $OUTPUT_DIR"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 