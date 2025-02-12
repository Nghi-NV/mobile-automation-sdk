#!/bin/bash

# Load common utilities
source "$(dirname "$0")/utils.sh"

# Initialize environment
load_env
validate_env

# Constants for version types
VERSION_MAJOR="major"
VERSION_MINOR="minor"
VERSION_PATCH="patch"

# Function to parse semver
parse_version() {
    local version=$1
    if [[ $version =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
        echo "${BASH_REMATCH[1]} ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}"
    else
        log_error "Invalid version format: $version"
        exit 1
    fi
}

# Function to bump version
bump_version() {
    local version=$1
    local type=$2
    
    read major minor patch <<< $(parse_version "$version")
    
    case "$type" in
        "$VERSION_MAJOR")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "$VERSION_MINOR")
            minor=$((minor + 1))
            patch=0
            ;;
        "$VERSION_PATCH")
            patch=$((patch + 1))
            ;;
        *)
            log_error "Invalid version type: $type"
            exit 1
            ;;
    esac
    
    echo "$major.$minor.$patch"
}

# Function to update version in package.json
update_react_native_version() {
    local new_version=$1
    local package_json="$PROJECT_PATH/package.json"
    
    if [ ! -f "$package_json" ]; then
        log_error "package.json not found at $package_json"
        exit 1
    }
    
    # Update version in package.json
    sed -i '' "s/\"version\": \".*\"/\"version\": \"$new_version\"/" "$package_json"
    
    # Update iOS project
    local plist_path="$PROJECT_PATH/ios/$PROJECT_NAME/Info.plist"
    if [ -f "$plist_path" ]; then
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $new_version" "$plist_path"
    fi
    
    # Update Android project
    local gradle_path="$PROJECT_PATH/android/app/build.gradle"
    if [ -f "$gradle_path" ]; then
        sed -i '' "s/versionName \".*\"/versionName \"$new_version\"/" "$gradle_path"
    fi
}

# Function to update version in pubspec.yaml
update_flutter_version() {
    local new_version=$1
    local pubspec_yaml="$PROJECT_PATH/pubspec.yaml"
    
    if [ ! -f "$pubspec_yaml" ]; then
        log_error "pubspec.yaml not found at $pubspec_yaml"
        exit 1
    }
    
    local build_number=$(get_build_number)
    sed -i '' "s/version: .*$/version: $new_version+$build_number/" "$pubspec_yaml"
}

# Main function to handle version bumping
main() {
    if [ $# -ne 1 ]; then
        log_error "Usage: $0 <major|minor|patch>"
        exit 1
    fi
    
    local version_type=$1
    if [[ ! $version_type =~ ^(major|minor|patch)$ ]]; then
        log_error "Invalid version type. Must be one of: major, minor, patch"
        exit 1
    }
    
    # Get current version
    local current_version=$(get_version_number)
    log_info "Current version: $current_version"
    
    # Calculate new version
    local new_version=$(bump_version "$current_version" "$version_type")
    log_info "New version: $new_version"
    
    # Update version based on SDK type
    if [ "$SDK" = "react-native" ]; then
        update_react_native_version "$new_version"
    elif [ "$SDK" = "flutter" ]; then
        update_flutter_version "$new_version"
    else
        log_error "Unsupported SDK type: $SDK"
        exit 1
    fi
    
    log_info "Version updated successfully to $new_version"
    
    # Git commit if in a git repository
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git add .
        git commit -m "chore: bump version to $new_version"
        log_info "Created version commit"
        
        # Create git tag
        git tag -a "v$new_version" -m "Version $new_version"
        log_info "Created git tag v$new_version"
    fi
}

# Execute main function
main "$@" 