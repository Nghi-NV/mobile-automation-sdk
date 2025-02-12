#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
KEYCHAIN_NAME="ios-build.keychain"
KEYCHAIN_PASSWORD="temporary_password"
CERTS_DIR="$PROJECT_PATH/ios/certs"
PROFILES_DIR="$HOME/Library/MobileDevice/Provisioning Profiles"

# Function to create a new keychain
create_keychain() {
    log_info "Creating new keychain..."
    
    # Delete keychain if it exists
    security delete-keychain "$KEYCHAIN_NAME" 2>/dev/null || true
    
    # Create a new keychain
    security create-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
    
    # Set keychain as default
    security default-keychain -s "$KEYCHAIN_NAME"
    
    # Unlock the keychain
    security unlock-keychain -p "$KEYCHAIN_PASSWORD" "$KEYCHAIN_NAME"
    
    # Remove relock timeout
    security set-keychain-settings -t 3600 -l "$KEYCHAIN_NAME"
}

# Function to import certificates
import_certificates() {
    local cert_path=$1
    local cert_password=$2
    
    log_info "Importing certificate..."
    
    # Import certificate to keychain
    security import "$cert_path" \
        -k "$KEYCHAIN_NAME" \
        -P "$cert_password" \
        -T /usr/bin/codesign \
        -T /usr/bin/security
    
    # Allow codesign to access the certificate
    security set-key-partition-list \
        -S apple-tool:,apple:,codesign: \
        -s \
        -k "$KEYCHAIN_PASSWORD" \
        "$KEYCHAIN_NAME"
}

# Function to download certificates from App Store Connect
fetch_certificates() {
    log_info "Fetching certificates from App Store Connect..."
    
    # Create certificates directory if it doesn't exist
    mkdir -p "$CERTS_DIR"
    
    # Use fastlane match to fetch certificates
    cd "$PROJECT_PATH/ios"
    fastlane match development --readonly true --output_path "$CERTS_DIR"
    fastlane match appstore --readonly true --output_path "$CERTS_DIR"
}

# Function to check certificates validity
check_certificates() {
    log_info "Checking certificates..."
    
    # List all certificates
    security find-identity -v -p codesigning
    
    # Check each certificate's expiration
    security find-certificate -a -c "iPhone Developer" -p | \
        openssl x509 -noout -dates | \
        grep "notAfter" | \
        while read -r line; do
            echo "Developer certificate expires: ${line#*=}"
        done
    
    security find-certificate -a -c "iPhone Distribution" -p | \
        openssl x509 -noout -dates | \
        grep "notAfter" | \
        while read -r line; do
            echo "Distribution certificate expires: ${line#*=}"
        done
}

# Function to install provisioning profiles
install_profiles() {
    log_info "Installing provisioning profiles..."
    
    # Create profiles directory if it doesn't exist
    mkdir -p "$PROFILES_DIR"
    
    # Copy all provisioning profiles
    find "$CERTS_DIR" -name "*.mobileprovision" -exec cp {} "$PROFILES_DIR/" \;
}

# Function to check provisioning profiles
check_profiles() {
    log_info "Checking provisioning profiles..."
    
    # List all provisioning profiles
    for profile in "$PROFILES_DIR"/*.mobileprovision; do
        if [ -f "$profile" ]; then
            echo "Profile: $(basename "$profile")"
            security cms -D -i "$profile" | \
                plutil -extract Name raw - | \
                xargs echo "Name:"
            security cms -D -i "$profile" | \
                plutil -extract ExpirationDate raw - | \
                xargs echo "Expires:"
            echo "---"
        fi
    done
}

# Function to clean up certificates and profiles
clean_certificates() {
    log_info "Cleaning up certificates and profiles..."
    
    # Delete keychain
    security delete-keychain "$KEYCHAIN_NAME" 2>/dev/null || true
    
    # Reset to login keychain
    security default-keychain -s login.keychain
    
    # Remove downloaded certificates
    rm -rf "$CERTS_DIR"
    
    log_info "Cleanup completed"
}

# Function to validate signing configuration
validate_signing() {
    log_info "Validating signing configuration..."
    
    local required_vars=(
        "DEVELOPER_APP_IDENTIFIER"
        "FASTLANE_APPLE_ID"
        "DEVELOPMENT_TEAM"
        "ASC_KEY_ID"
        "ASC_ISSUER_ID"
        "ASC_KEY"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
    
    # Check if we have valid certificates
    if ! security find-identity -v -p codesigning | grep -q "iPhone"; then
        log_error "No valid iOS signing certificates found"
        exit 1
    fi
    
    # Check if we have provisioning profiles
    if [ ! "$(ls -A "$PROFILES_DIR"/*.mobileprovision 2>/dev/null)" ]; then
        log_error "No provisioning profiles found"
        exit 1
    }
    
    log_info "Signing configuration is valid"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <command> [arguments...]"
        log_error "Commands:"
        log_error "  setup              - Set up certificates and profiles"
        log_error "  check-certs        - Check certificates status"
        log_error "  check-profiles     - Check provisioning profiles"
        log_error "  fetch-certs        - Download certificates from App Store Connect"
        log_error "  clean              - Clean up certificates and profiles"
        log_error "  validate           - Validate signing configuration"
        exit 1
    fi
    
    local command=$1
    shift
    
    case "$command" in
        "setup")
            create_keychain
            fetch_certificates
            install_profiles
            validate_signing
            ;;
        "check-certs")
            check_certificates
            ;;
        "check-profiles")
            check_profiles
            ;;
        "fetch-certs")
            fetch_certificates
            install_profiles
            ;;
        "clean")
            clean_certificates
            ;;
        "validate")
            validate_signing
            ;;
        *)
            log_error "Unknown command: $command"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 