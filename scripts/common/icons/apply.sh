#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
ICONS_DIR="$PROJECT_PATH/generated_icons"

# Function to apply iOS icons
apply_ios_icons() {
    local source_dir="$ICONS_DIR/ios"
    local target_dir="$PROJECT_PATH/ios/$PROJECT_NAME/Images.xcassets/AppIcon.appiconset"
    
    if [ ! -d "$source_dir" ]; then
        log_error "iOS icons not found in: $source_dir"
        exit 1
    fi
    
    log_info "Applying iOS icons..."
    
    # Create target directory
    mkdir -p "$target_dir"
    
    # Copy icons
    cp -R "$source_dir"/* "$target_dir/"
    
    # Generate Contents.json
    generate_ios_contents_json "$target_dir"
    
    log_info "iOS icons applied successfully"
}

# Function to apply Android icons
apply_android_icons() {
    local source_dir="$ICONS_DIR/android"
    local target_base_dir="$PROJECT_PATH/android/app/src/main/res"
    
    if [ ! -d "$source_dir" ]; then
        log_error "Android icons not found in: $source_dir"
        exit 1
    fi
    
    log_info "Applying Android icons..."
    
    # Copy icons for each density
    for type in "${ANDROID_ICON_TYPES[@]}"; do
        local source_type_dir="$source_dir/$type"
        local target_dir="$target_base_dir/mipmap-$type"
        
        if [ -d "$source_type_dir" ]; then
            mkdir -p "$target_dir"
            cp -R "$source_type_dir"/* "$target_dir/"
        fi
    done
    
    # Create XML resources for adaptive icons
    mkdir -p "$target_base_dir/mipmap-anydpi-v26"
    generate_android_xml "$target_base_dir/mipmap-anydpi-v26")
    
    log_info "Android icons applied successfully"
}

# Function to generate iOS Contents.json
generate_ios_contents_json() {
    local target_dir=$1
    local contents_file="$target_dir/Contents.json"
    
    # Create Contents.json structure
    cat > "$contents_file" <<EOF
{
  "images" : [
EOF
    
    # Add entries for each icon
    local first=true
    for config in "${IOS_ICON_CONFIG[@]}"; do
        read -r size idiom scales <<< "$config"
        IFS=',' read -ra scale_array <<< "$scales"
        
        for scale in "${scale_array[@]}"; do
            local filename="icon_${size}x${size}@${scale}x.png"
            
            if [ "$first" = true ]; then
                first=false
            else
                echo "," >> "$contents_file"
            fi
            
            cat >> "$contents_file" <<EOF
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
    cat >> "$contents_file" <<EOF

  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
EOF
}

# Function to generate Android XML resources
generate_android_xml() {
    local target_dir=$1
    
    # ic_launcher.xml
    cat > "$target_dir/ic_launcher.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF
    
    # ic_launcher_round.xml
    cat > "$target_dir/ic_launcher_round.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
EOF
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <platform>"
        log_error "Platforms: ios, android, all"
        exit 1
    fi
    
    local platform=$1
    
    case "$platform" in
        "ios")
            apply_ios_icons
            ;;
        "android")
            apply_android_icons
            ;;
        "all")
            apply_ios_icons
            apply_android_icons
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