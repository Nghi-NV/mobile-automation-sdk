#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
DOCS_DIR="$PROJECT_PATH/docs"
SCRIPTS_DOCS_DIR="$DOCS_DIR/scripts"
SCRIPTS_DIR="$PROJECT_PATH/scripts"

# Function to generate script documentation
generate_script_docs() {
    log_info "Generating script documentation..."
    
    mkdir -p "$SCRIPTS_DOCS_DIR"
    
    # Generate main README
    cat > "$SCRIPTS_DOCS_DIR/README.md" <<EOF
# Scripts Documentation

This directory contains documentation for all automation scripts.

## Directory Structure

\`\`\`
scripts/
├── ios/
│   ├── build.sh          # iOS build script
│   ├── upload.sh         # Upload to TestFlight
│   └── sign.sh          # Handle certificates
├── android/
│   ├── build.sh         # Android build script
│   ├── upload.sh        # Upload to Play Store
│   └── sign.sh         # Handle keystore
└── common/
    ├── notify.sh        # Send notifications
    ├── version.sh       # Version management
    └── utils.sh         # Utility functions
\`\`\`

## Usage Examples

See individual script documentation for detailed usage examples.
EOF
    
    # Generate docs for each script
    find "$SCRIPTS_DIR" -name "*.sh" | while read -r script; do
        local script_name=$(basename "$script")
        local script_dir=$(dirname "$script" | sed "s|$SCRIPTS_DIR/||")
        local doc_file="$SCRIPTS_DOCS_DIR/${script_dir}/${script_name%.sh}.md"
        
        mkdir -p "$(dirname "$doc_file")"
        
        # Extract script header comments
        echo "# ${script_name%.sh}" > "$doc_file"
        echo "" >> "$doc_file"
        
        # Extract description from comments
        sed -n '/^#/p' "$script" | sed 's/^# //' >> "$doc_file"
        echo "" >> "$doc_file"
        
        # Extract functions and their descriptions
        echo "## Functions" >> "$doc_file"
        echo "" >> "$doc_file"
        
        grep -A 1 "^# Function" "$script" | while read -r line; do
            if [[ "$line" =~ ^#\ Function ]]; then
                echo "### ${line#\# Function to }" >> "$doc_file"
                echo "" >> "$doc_file"
            elif [[ "$line" =~ ^[a-zA-Z0-9_]+\(\) ]]; then
                echo "\`\`\`bash" >> "$doc_file"
                echo "$line" >> "$doc_file"
                echo "\`\`\`" >> "$doc_file"
                echo "" >> "$doc_file"
            fi
        done
        
        # Extract usage examples
        echo "## Usage" >> "$doc_file"
        echo "" >> "$doc_file"
        echo "\`\`\`bash" >> "$doc_file"
        grep "^    log_error \"Usage:" "$script" | sed 's/^    log_error "Usage: //' | sed 's/"$//' >> "$doc_file"
        echo "\`\`\`" >> "$doc_file"
    done
    
    log_success "Script documentation generated in: $SCRIPTS_DOCS_DIR"
}

# Function to generate usage examples
generate_examples() {
    log_info "Generating usage examples..."
    
    local examples_file="$SCRIPTS_DOCS_DIR/examples.md"
    
    cat > "$examples_file" <<EOF
# Script Usage Examples

This document provides common usage examples for the automation scripts.

## Build Examples

### iOS Build
\`\`\`bash
# Development build
./scripts/ios/build.sh development

# Production build with upload
./scripts/ios/build.sh production --clean --upload --notify
\`\`\`

### Android Build
\`\`\`bash
# Development build
./scripts/android/build.sh development

# Production AAB with upload
./scripts/android/build.sh production --clean --aab --upload --notify
\`\`\`

## Testing Examples

### Screenshot Tests
\`\`\`bash
# Capture iOS screenshots
./scripts/testing/screenshot/capture.sh ios --process

# Capture Android screenshots
./scripts/testing/screenshot/capture.sh android --process
\`\`\`

### UI Tests
\`\`\`bash
# Run iOS UI tests
./scripts/testing/ui/test.sh ios --report

# Run Android UI tests
./scripts/testing/ui/test.sh android --report
\`\`\`

## Asset Management Examples

### Optimize Assets
\`\`\`bash
# Optimize images
./scripts/common/assets/optimize.sh images --report

# Optimize all assets
./scripts/common/assets/optimize.sh all --report
\`\`\`

### Generate Asset Constants
\`\`\`bash
# Generate image constants
./scripts/common/assets/generate.sh images --update-pubspec

# Generate all constants
./scripts/common/assets/generate.sh all --update-pubspec
\`\`\`

## Monitoring Examples

### Crash Reporting
\`\`\`bash
# Setup crash reporting
./scripts/monitoring/crash.sh setup all

# Collect crash reports
./scripts/monitoring/crash.sh collect ios
\`\`\`

### Analytics
\`\`\`bash
# Setup analytics
./scripts/monitoring/analytics.sh setup all

# Export analytics data
./scripts/monitoring/analytics.sh export "2024-01-01" "2024-01-31"
\`\`\`

### Logging
\`\`\`bash
# Setup logging
./scripts/monitoring/logging.sh setup

# Collect logs
./scripts/monitoring/logging.sh collect ios app
\`\`\`
EOF
    
    log_success "Examples generated: $examples_file"
}

# Function to generate markdown documentation
generate_markdown() {
    log_info "Generating markdown documentation..."
    
    # Generate script documentation
    generate_script_docs
    
    # Generate examples
    generate_examples
    
    # Generate index
    local index_file="$SCRIPTS_DOCS_DIR/index.md"
    
    cat > "$index_file" <<EOF
# Scripts Documentation Index

## Overview
- [README](README.md)
- [Usage Examples](examples.md)

## Scripts
EOF
    
    # Add links to all script docs
    find "$SCRIPTS_DOCS_DIR" -name "*.md" -not -name "README.md" -not -name "examples.md" -not -name "index.md" | while read -r doc; do
        local rel_path=${doc#$SCRIPTS_DOCS_DIR/}
        echo "- [${rel_path%.md}]($rel_path)" >> "$index_file"
    done
    
    log_success "Documentation index generated: $index_file"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <command>"
        log_error "Commands: generate, examples, markdown"
        exit 1
    fi
    
    local command=$1
    
    case "$command" in
        "generate")
            generate_script_docs
            ;;
        "examples")
            generate_examples
            ;;
        "markdown")
            generate_markdown
            ;;
        *)
            log_error "Invalid command: $command"
            exit 1
            ;;
    esac
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 