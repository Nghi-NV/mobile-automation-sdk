#!/bin/bash

# Load common utilities
source "$(dirname "$0")/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
IOS_ICON_SIZES=(20 29 40 58 60 76 80 87 120 152 167 180 1024)
ANDROID_ICON_SIZES=(36 48 72 96 144 192)
ANDROID_ICON_TYPES=("mdpi" "hdpi" "xhdpi" "xxhdpi" "xxxhdpi")

# Update iOS icon sizes with scales
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

# Function to check if ImageMagick is installed
check_imagemagick() {
    if ! command -v convert &> /dev/null; then
        log_error "ImageMagick is not installed. Please install it first:"
        log_error "brew install imagemagick"
        exit 1
    fi
}

# Function to validate source icon
validate_icon() {
    local source_icon=$1
    local min_size=1024
    
    if [ ! -f "$source_icon" ]; then
        log_error "Source icon not found: $source_icon"
        exit 1
    fi
    
    # Check image dimensions
    local dimensions=$(identify -format "%wx%h" "$source_icon")
    local width=$(echo $dimensions | cut -d'x' -f1)
    local height=$(echo $dimensions | cut -d'x' -f2)
    
    if [ $width -lt $min_size ] || [ $height -lt $min_size ]; then
        log_error "Source icon must be at least ${min_size}x${min_size} pixels"
        log_error "Current size: ${width}x${height}"
        exit 1
    fi
}

# Function to generate iOS icons
generate_ios_icons() {
    local source_icon=$1
    local output_dir="$PROJECT_PATH/ios/$PROJECT_NAME/Images.xcassets/AppIcon.appiconset"
    
    log_info "Generating iOS icons..."
    
    # Create output directory
    mkdir -p "$output_dir"
    
    # Start Contents.json
    cat > "$output_dir/Contents.json" <<EOF
{
  "images" : [
EOF
    
    # Generate icons for each configuration
    local first=true
    for config in "${IOS_ICON_CONFIG[@]}"; do
        read -r size idiom scales <<< "$config"
        
        # Split scales into array
        IFS=',' read -ra scale_array <<< "$scales"
        
        for scale in "${scale_array[@]}"; do
            # Calculate actual size
            local actual_size=$(echo "$size * $scale" | bc)
            local filename="icon_${size}x${size}@${scale}x.png"
            
            # Add comma if not first entry
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> "$output_dir/Contents.json"
            fi
            
            # Convert image
            convert "$source_icon" -resize "${actual_size}x${actual_size}" "$output_dir/$filename"
            
            # Add entry to Contents.json
            cat >> "$output_dir/Contents.json" <<EOF
    {
      "size" : "${size}x${size}",
      "idiom" : "${idiom}",
      "filename" : "${filename}",
      "scale" : "${scale}x"
    }
EOF
        done
    done
    
    # Close Contents.json
    cat >> "$output_dir/Contents.json" <<EOF
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF
    
    log_info "iOS icons generated successfully"
}

# Function to generate Android icons
generate_android_icons() {
    local source_icon=$1
    local base_dir="$PROJECT_PATH/android/app/src/main/res"
    
    log_info "Generating Android icons..."
    
    # Generate icons for each density
    for i in "${!ANDROID_ICON_TYPES[@]}"; do
        local type="${ANDROID_ICON_TYPES[$i]}"
        local size="${ANDROID_ICON_SIZES[$i]}"
        local dir="$base_dir/mipmap-$type"
        
        # Create directory
        mkdir -p "$dir"
        
        # Generate regular icon
        convert "$source_icon" -resize "${size}x${size}" "$dir/ic_launcher.png"
        
        # Generate round icon
        convert "$source_icon" \
            -resize "${size}x${size}" \
            \( +clone -alpha extract -draw "circle ${size}/2,${size}/2 ${size}/2,0" -alpha copy \) \
            -compose copy_opacity -composite \
            "$dir/ic_launcher_round.png"
    }
    
    log_info "Android icons generated successfully"
}

# Function to generate adaptive icons for Android
generate_adaptive_icons() {
    local source_icon=$1
    local base_dir="$PROJECT_PATH/android/app/src/main/res"
    
    log_info "Generating Android adaptive icons..."
    
    # Create foreground and background
    for type in "${ANDROID_ICON_TYPES[@]}"; do
        local dir="$base_dir/mipmap-$type"
        mkdir -p "$dir"
        
        # Generate foreground (icon with padding)
        convert "$source_icon" \
            -resize "70%" -gravity center -background transparent \
            -extent "108x108%" \
            "$dir/ic_launcher_foreground.png"
            
        # Generate background (solid color)
        convert -size 108x108 xc:"#FFFFFF" \
            "$dir/ic_launcher_background.png"
    }
    
    # Create XML resources
    mkdir -p "$base_dir/mipmap-anydpi-v26"
    
    # ic_launcher.xml
    cat > "$base_dir/mipmap-anydpi-v26/ic_launcher.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF
    
    # ic_launcher_round.xml
    cat > "$base_dir/mipmap-anydpi-v26/ic_launcher_round.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF
    
    log_info "Android adaptive icons generated successfully"
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
    
    case "$platform" in
        "ios")
            generate_ios_icons "$source_icon"
            ;;
        "android")
            generate_android_icons "$source_icon"
            generate_adaptive_icons "$source_icon"
            ;;
        "all")
            generate_ios_icons "$source_icon"
            generate_android_icons "$source_icon"
            generate_adaptive_icons "$source_icon"
            ;;
        *)
            log_error "Invalid platform: $platform"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 