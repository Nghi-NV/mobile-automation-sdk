#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
DOCS_DIR="$PROJECT_PATH/docs"
API_DOCS_DIR="$DOCS_DIR/api"
API_SPEC_FILE="$PROJECT_PATH/api/swagger.yaml"

# Function to setup documentation tools
setup_docs() {
    log_info "Setting up documentation tools..."
    
    # Install required tools
    if ! command -v dartdoc &> /dev/null; then
        dart pub global activate dartdoc
    fi
    
    if ! command -v swagger-cli &> /dev/null; then
        npm install -g swagger-cli
    fi
    
    # Create directories
    mkdir -p "$API_DOCS_DIR"
    
    # Create default config if not exists
    if [ ! -f "$DOCS_DIR/dartdoc_options.yaml" ]; then
        cat > "$DOCS_DIR/dartdoc_options.yaml" <<EOF
dartdoc:
  categories:
    - "API"
    - "Models"
    - "Utils"
  categoryOrder: ["API", "Models", "Utils"]
  showUndocumentedCategories: true
  ignore:
    - broken-link
    - missing-from-search-index
EOF
    fi
}

# Function to generate API documentation
generate_api_docs() {
    log_info "Generating API documentation..."
    
    # Validate OpenAPI spec
    if [ -f "$API_SPEC_FILE" ]; then
        swagger-cli validate "$API_SPEC_FILE"
        
        # Generate HTML docs from OpenAPI spec
        npx redoc-cli bundle "$API_SPEC_FILE" \
            --output "$API_DOCS_DIR/index.html" \
            --title "API Documentation" \
            --disableGoogleFont \
            --templateOptions.hideDownloadButton
    fi
    
    # Generate Dart API docs
    dartdoc \
        --output "$API_DOCS_DIR/dart" \
        --exclude "test" \
        --exclude "build" \
        --exclude ".dart_tool"
    
    log_success "API documentation generated in: $API_DOCS_DIR"
}

# Function to validate documentation
validate_docs() {
    log_info "Validating documentation..."
    
    local report_file="$DOCS_DIR/validation_report.txt"
    
    echo "Documentation Validation Report" > "$report_file"
    echo "============================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Check for undocumented public APIs
    echo "Undocumented Public APIs:" >> "$report_file"
    find "$PROJECT_PATH/lib" -name "*.dart" -exec grep -l "^[^_].*(" {} \; | while read -r file; do
        if ! grep -q "///" "$file"; then
            echo "- $file" >> "$report_file"
        fi
    done
    
    # Check for broken links
    echo "" >> "$report_file"
    echo "Broken Links:" >> "$report_file"
    find "$API_DOCS_DIR" -name "*.html" -exec grep -l "href=\".*\"" {} \; | while read -r file; do
        broken_links=$(grep -o 'href="[^"]*"' "$file" | cut -d'"' -f2 | while read -r link; do
            if [[ "$link" =~ ^http ]]; then
                curl -s --head "$link" || echo "$link"
            fi
        done)
        if [ ! -z "$broken_links" ]; then
            echo "File: $file" >> "$report_file"
            echo "$broken_links" | sed 's/^/  /' >> "$report_file"
        fi
    done
    
    log_success "Validation report generated: $report_file"
}

# Function to generate changelog
generate_changelog() {
    log_info "Generating changelog..."
    
    local changelog_file="$DOCS_DIR/CHANGELOG.md"
    local temp_file="$DOCS_DIR/CHANGELOG.tmp"
    
    echo "# Changelog" > "$changelog_file"
    echo "" >> "$changelog_file"
    
    # Get all tags sorted by date
    git tag --sort=-creatordate | while read -r tag; do
        echo "## $tag ($(git log -1 --format=%ad --date=short $tag))" >> "$changelog_file"
        echo "" >> "$changelog_file"
        
        # Get commits since last tag
        if [ "$tag" = "$(git tag | head -n1)" ]; then
            git log --no-merges --format="* %s (%h)" $tag >> "$changelog_file"
        else
            git log --no-merges --format="* %s (%h)" $tag...$prev_tag >> "$changelog_file"
        fi
        
        echo "" >> "$changelog_file"
        prev_tag=$tag
    done
    
    log_success "Changelog generated: $changelog_file"
}

# Function to publish documentation
publish_docs() {
    log_info "Publishing documentation..."
    
    local target=$1
    
    case "$target" in
        "github")
            # Setup GitHub Pages
            if [ ! -d "$PROJECT_PATH/docs" ]; then
                mkdir -p "$PROJECT_PATH/docs"
                echo "theme: jekyll-theme-minimal" > "$PROJECT_PATH/docs/_config.yml"
            fi
            
            # Copy docs to GitHub Pages directory
            cp -R "$API_DOCS_DIR"/* "$PROJECT_PATH/docs/"
            
            # Commit and push
            git add docs/
            git commit -m "Update documentation"
            git push origin main
            ;;
            
        "custom")
            # Add your custom publishing logic here
            ;;
            
        *)
            log_error "Invalid publish target: $target"
            exit 1
            ;;
    esac
    
    log_success "Documentation published to: $target"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <command> [target]"
        log_error "Commands: setup, generate, validate, changelog, publish"
        log_error "Publish targets: github, custom"
        exit 1
    fi
    
    local command=$1
    local target=$2
    
    case "$command" in
        "setup")
            setup_docs
            ;;
        "generate")
            generate_api_docs
            ;;
        "validate")
            validate_docs
            ;;
        "changelog")
            generate_changelog
            ;;
        "publish")
            if [ -z "$target" ]; then
                log_error "Publish target required"
                exit 1
            fi
            publish_docs "$target"
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