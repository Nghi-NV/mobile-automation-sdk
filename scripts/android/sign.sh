#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
KEYSTORE_DIR="$PROJECT_PATH/android/app/keystore"
KEYSTORE_PROPERTIES="$PROJECT_PATH/android/keystore.properties"

# Function to validate keystore environment
validate_keystore_env() {
    local required_vars=(
        "ANDROID_KEYSTORE_PATH"
        "ANDROID_KEYSTORE_PASSWORD"
        "ANDROID_KEY_ALIAS"
        "ANDROID_KEY_PASSWORD"
    )
    
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Required environment variable $var is not set"
            exit 1
        fi
    done
}

# Function to generate keystore
generate_keystore() {
    local keystore_path=$1
    local keystore_password=$2
    local key_alias=$3
    local key_password=$4
    local validity=${5:-36500} # Default 100 years
    
    log_info "Generating new keystore..."
    
    # Create keystore directory if it doesn't exist
    mkdir -p "$(dirname "$keystore_path")"
    
    # Generate keystore using keytool
    keytool -genkey -v \
        -keystore "$keystore_path" \
        -alias "$key_alias" \
        -keyalg RSA \
        -keysize 2048 \
        -validity "$validity" \
        -storepass "$keystore_password" \
        -keypass "$key_password" \
        -dname "CN=Android Debug,O=Android,C=US" || {
            log_error "Failed to generate keystore"
            exit 1
        }
    
    log_info "Keystore generated successfully at: $keystore_path"
}

# Function to verify keystore
verify_keystore() {
    local keystore_path=$1
    local keystore_password=$2
    local key_alias=$3
    
    log_info "Verifying keystore..."
    
    # Check if keystore file exists
    if [ ! -f "$keystore_path" ]; then
        log_error "Keystore file not found at: $keystore_path"
        return 1
    fi
    
    # Verify keystore using keytool
    if ! keytool -list \
        -keystore "$keystore_path" \
        -storepass "$keystore_password" \
        -alias "$key_alias" > /dev/null 2>&1; then
        log_error "Invalid keystore or credentials"
        return 1
    fi
    
    log_info "Keystore verification successful"
    return 0
}

# Function to show keystore information
show_keystore_info() {
    local keystore_path=$1
    local keystore_password=$2
    
    log_info "Keystore Information:"
    
    # Show keystore details
    keytool -list -v \
        -keystore "$keystore_path" \
        -storepass "$keystore_password"
}

# Function to backup keystore
backup_keystore() {
    local keystore_path=$1
    local backup_dir="$KEYSTORE_DIR/backup"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_path="$backup_dir/keystore_$timestamp.bak"
    
    log_info "Backing up keystore..."
    
    # Create backup directory
    mkdir -p "$backup_dir"
    
    # Copy keystore to backup location
    cp "$keystore_path" "$backup_path" || {
        log_error "Failed to backup keystore"
        exit 1
    }
    
    log_info "Keystore backed up to: $backup_path"
}

# Function to setup keystore properties
setup_keystore_properties() {
    log_info "Setting up keystore properties..."
    
    # Create keystore.properties file
    cat > "$KEYSTORE_PROPERTIES" <<EOF
storeFile=$ANDROID_KEYSTORE_PATH
storePassword=$ANDROID_KEYSTORE_PASSWORD
keyAlias=$ANDROID_KEY_ALIAS
keyPassword=$ANDROID_KEY_PASSWORD
EOF
    
    log_info "Keystore properties configured"
}

# Function to export keystore
export_keystore() {
    local keystore_path=$1
    local keystore_password=$2
    local key_alias=$3
    local output_dir=${4:-"$KEYSTORE_DIR/export"}
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    log_info "Exporting keystore..."
    
    # Create export directory
    mkdir -p "$output_dir"
    
    # Export certificate
    keytool -exportcert \
        -keystore "$keystore_path" \
        -alias "$key_alias" \
        -storepass "$keystore_password" \
        -file "$output_dir/certificate_$timestamp.cer" || {
            log_error "Failed to export certificate"
            exit 1
        }
    
    log_info "Certificate exported to: $output_dir/certificate_$timestamp.cer"
}

# Function to import certificate
import_certificate() {
    local cert_path=$1
    local keystore_path=$2
    local keystore_password=$3
    local key_alias=$4
    
    log_info "Importing certificate..."
    
    keytool -importcert \
        -file "$cert_path" \
        -keystore "$keystore_path" \
        -alias "$key_alias" \
        -storepass "$keystore_password" \
        -noprompt || {
            log_error "Failed to import certificate"
            exit 1
        }
    
    log_info "Certificate imported successfully"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <command> [arguments...]"
        log_error "Commands:"
        log_error "  generate           - Generate new keystore"
        log_error "  verify            - Verify existing keystore"
        log_error "  info              - Show keystore information"
        log_error "  backup            - Backup keystore"
        log_error "  setup             - Setup keystore properties"
        log_error "  export            - Export keystore certificate"
        log_error "  import            - Import certificate to keystore"
        exit 1
    fi
    
    # Validate environment variables
    validate_keystore_env
    
    local command=$1
    shift
    
    case "$command" in
        "generate")
            generate_keystore \
                "$ANDROID_KEYSTORE_PATH" \
                "$ANDROID_KEYSTORE_PASSWORD" \
                "$ANDROID_KEY_ALIAS" \
                "$ANDROID_KEY_PASSWORD"
            ;;
        "verify")
            verify_keystore \
                "$ANDROID_KEYSTORE_PATH" \
                "$ANDROID_KEYSTORE_PASSWORD" \
                "$ANDROID_KEY_ALIAS"
            ;;
        "info")
            show_keystore_info \
                "$ANDROID_KEYSTORE_PATH" \
                "$ANDROID_KEYSTORE_PASSWORD"
            ;;
        "backup")
            backup_keystore "$ANDROID_KEYSTORE_PATH"
            ;;
        "setup")
            setup_keystore_properties
            ;;
        "export")
            export_keystore \
                "$ANDROID_KEYSTORE_PATH" \
                "$ANDROID_KEYSTORE_PASSWORD" \
                "$ANDROID_KEY_ALIAS"
            ;;
        "import")
            if [ $# -lt 1 ]; then
                log_error "Usage: $0 import <certificate_path>"
                exit 1
            fi
            import_certificate \
                "$1" \
                "$ANDROID_KEYSTORE_PATH" \
                "$ANDROID_KEYSTORE_PASSWORD" \
                "$ANDROID_KEY_ALIAS"
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