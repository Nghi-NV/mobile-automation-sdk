#!/bin/bash

# Load common utilities
source "$(dirname "$0")/utils.sh"

# Initialize environment
load_env
validate_env

# Constants for notification types
STATUS_SUCCESS="success"
STATUS_FAILURE="failure"
STATUS_PROGRESS="progress"

# Constants for platforms
PLATFORM_IOS="iOS"
PLATFORM_ANDROID="Android"

# Constants for emojis
EMOJI_SUCCESS="✅"
EMOJI_FAILURE="❌"
EMOJI_ROCKET="🚀"
EMOJI_WRENCH="🔧"
EMOJI_PHONE="📱"
EMOJI_LINK="🔗"
EMOJI_WARNING="⚠️"

# Function to create notification card
create_notification_card() {
    local status=$1
    local platform=$2
    local environment=$3
    local version=$4
    local build_number=$5
    local artifact_path=$6
    local error_message=$7
    
    # Set emoji based on status
    local status_emoji
    case "$status" in
        "$STATUS_SUCCESS") status_emoji="$EMOJI_SUCCESS" ;;
        "$STATUS_FAILURE") status_emoji="$EMOJI_FAILURE" ;;
        "$STATUS_PROGRESS") status_emoji="$EMOJI_WRENCH" ;;
        *) status_emoji="$EMOJI_WARNING" ;;
    esac
    
    # Create basic card content
    local card_content="$EMOJI_ROCKET *Build Notification*\n\n"
    card_content+="$EMOJI_PHONE *Project:* $PROJECT_NAME\n"
    card_content+="*Platform:* $platform\n"
    card_content+="*Environment:* $environment\n"
    card_content+="*Version:* $version ($build_number)\n"
    card_content+="*Status:* $status_emoji $status\n"
    
    # Add error message if build failed
    if [ "$status" = "$STATUS_FAILURE" ]; then
        card_content+="\n$EMOJI_WARNING *Error Details:*\n\`\`\`\n$error_message\n\`\`\`"
    fi
    
    # Add artifact link if build succeeded and artifact exists
    if [ "$status" = "$STATUS_SUCCESS" ] && [ ! -z "$artifact_path" ]; then
        if [ ! -z "$GOOGLE_DRIVE_FOLDER_ID" ]; then
            local download_link=$(upload_to_drive "$artifact_path")
            card_content+="\n$EMOJI_LINK *Download:* $download_link"
        fi
    fi
    
    # Add build time if available
    if [ ! -z "$BUILD_START_TIME" ]; then
        local build_end_time=$(date +%s)
        local build_duration=$((build_end_time - BUILD_START_TIME))
        local minutes=$((build_duration / 60))
        local seconds=$((build_duration % 60))
        card_content+="\n⏱ *Build Time:* ${minutes}m ${seconds}s"
    fi
    
    echo "$card_content"
}

# Function to send notification to Lark with rich text
send_lark_notification() {
    local card_content=$1
    local timestamp=$(date +%s)
    local sign=""
    
    # Generate signature if verification is enabled
    if [ ! -z "$LARK_BOT_SIGNATURE_VERIFICATION" ]; then
        string_to_sign="$timestamp\n$LARK_BOT_SIGNATURE_VERIFICATION"
        sign=$(echo -n "$string_to_sign" | openssl sha256 -hmac "$LARK_BOT_SIGNATURE_VERIFICATION" -binary | base64)
    fi
    
    # Create JSON payload with markdown support
    local json_payload=$(cat <<EOF
{
    "timestamp": "$timestamp",
    "sign": "$sign",
    "msg_type": "interactive",
    "card": {
        "config": {
            "wide_screen_mode": true
        },
        "header": {
            "title": {
                "tag": "plain_text",
                "content": "Build Notification - $PROJECT_NAME"
            }
        },
        "elements": [
            {
                "tag": "markdown",
                "content": "$card_content"
            }
        ]
    }
}
EOF
)
    
    # Send notification to Lark
    if [ ! -z "$LARK_BOT_NOTIFY_WEBHOOK" ]; then
        local response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$json_payload" \
            "$LARK_BOT_NOTIFY_WEBHOOK")
        
        # Check if notification was sent successfully
        if [[ $response == *"\"StatusCode\":0"* ]]; then
            log_info "Notification sent successfully"
        else
            log_error "Failed to send notification: $response"
        fi
    else
        log_warning "Lark webhook URL not configured. Skipping notification."
    fi
}

# Function to send build start notification
notify_build_start() {
    local platform=$1
    local environment=$2
    local version=$3
    local build_number=$4
    
    export BUILD_START_TIME=$(date +%s)
    
    local card_content=$(create_notification_card \
        "$STATUS_PROGRESS" \
        "$platform" \
        "$environment" \
        "$version" \
        "$build_number")
    
    send_lark_notification "$card_content"
}

# Function to send build success notification
notify_build_success() {
    local platform=$1
    local environment=$2
    local version=$3
    local build_number=$4
    local artifact_path=$5
    
    local card_content=$(create_notification_card \
        "$STATUS_SUCCESS" \
        "$platform" \
        "$environment" \
        "$version" \
        "$build_number" \
        "$artifact_path")
    
    send_lark_notification "$card_content"
}

# Function to send build failure notification
notify_build_failure() {
    local platform=$1
    local environment=$2
    local version=$3
    local build_number=$4
    local error_message=$5
    
    local card_content=$(create_notification_card \
        "$STATUS_FAILURE" \
        "$platform" \
        "$environment" \
        "$version" \
        "$build_number" \
        "" \
        "$error_message")
    
    send_lark_notification "$card_content"
}

# Main function to handle notifications
main() {
    local command=$1
    shift
    
    case "$command" in
        "start")
            notify_build_start "$@"
            ;;
        "success")
            notify_build_success "$@"
            ;;
        "failure")
            notify_build_failure "$@"
            ;;
        *)
            log_error "Usage: $0 <start|success|failure> [arguments...]"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 