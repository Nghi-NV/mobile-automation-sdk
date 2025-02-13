#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
DOCS_DIR="$PROJECT_PATH/docs"
CHANGELOG_FILE="$PROJECT_PATH/CHANGELOG.md"
TEMP_FILE="/tmp/changelog.tmp"

# Function to parse commit messages
parse_commits() {
    local from_tag=$1
    local to_tag=$2
    
    # Get commits between tags
    if [ -z "$from_tag" ]; then
        git log --no-merges --format="%h %s" $to_tag
    else
        git log --no-merges --format="%h %s" $from_tag..$to_tag
    fi | while read -r hash message; do
        # Categorize commits based on conventional commits
        if [[ "$message" =~ ^feat: ]]; then
            echo "### Features" >> "$TEMP_FILE"
            echo "- ${message#feat: } ($hash)" >> "$TEMP_FILE"
        elif [[ "$message" =~ ^fix: ]]; then
            echo "### Bug Fixes" >> "$TEMP_FILE"
            echo "- ${message#fix: } ($hash)" >> "$TEMP_FILE"
        elif [[ "$message" =~ ^docs: ]]; then
            echo "### Documentation" >> "$TEMP_FILE"
            echo "- ${message#docs: } ($hash)" >> "$TEMP_FILE"
        elif [[ "$message" =~ ^style: ]]; then
            echo "### Styling" >> "$TEMP_FILE"
            echo "- ${message#style: } ($hash)" >> "$TEMP_FILE"
        elif [[ "$message" =~ ^refactor: ]]; then
            echo "### Code Refactoring" >> "$TEMP_FILE"
            echo "- ${message#refactor: } ($hash)" >> "$TEMP_FILE"
        elif [[ "$message" =~ ^perf: ]]; then
            echo "### Performance Improvements" >> "$TEMP_FILE"
            echo "- ${message#perf: } ($hash)" >> "$TEMP_FILE"
        elif [[ "$message" =~ ^test: ]]; then
            echo "### Tests" >> "$TEMP_FILE"
            echo "- ${message#test: } ($hash)" >> "$TEMP_FILE"
        elif [[ "$message" =~ ^build: ]]; then
            echo "### Build System" >> "$TEMP_FILE"
            echo "- ${message#build: } ($hash)" >> "$TEMP_FILE"
        elif [[ "$message" =~ ^ci: ]]; then
            echo "### Continuous Integration" >> "$TEMP_FILE"
            echo "- ${message#ci: } ($hash)" >> "$TEMP_FILE"
        else
            echo "### Other Changes" >> "$TEMP_FILE"
            echo "- $message ($hash)" >> "$TEMP_FILE"
        fi
    done
}

# Function to generate changelog
generate_changelog() {
    log_info "Generating changelog..."
    
    # Create or update changelog file
    if [ ! -f "$CHANGELOG_FILE" ]; then
        echo "# Changelog" > "$CHANGELOG_FILE"
        echo "" >> "$CHANGELOG_FILE"
        echo "All notable changes to this project will be documented in this file." >> "$CHANGELOG_FILE"
        echo "" >> "$CHANGELOG_FILE"
    fi
    
    # Get all tags sorted by version
    local tags=($(git tag --sort=-v:refname))
    
    # Process each tag
    for i in "${!tags[@]}"; do
        local current_tag="${tags[$i]}"
        local previous_tag="${tags[$i+1]}"
        local date=$(git log -1 --format=%ad --date=short $current_tag)
        
        echo "## [$current_tag] - $date" > "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        
        parse_commits "$previous_tag" "$current_tag"
        
        # Add new version to changelog
        if [ "$i" -eq 0 ]; then
            cat "$TEMP_FILE" > "$CHANGELOG_FILE.new"
            cat "$CHANGELOG_FILE" >> "$CHANGELOG_FILE.new"
            mv "$CHANGELOG_FILE.new" "$CHANGELOG_FILE"
        fi
    done
    
    # Add unreleased changes if any
    if [ -n "$(git log --no-merges HEAD...${tags[0]})" ]; then
        echo "## [Unreleased]" > "$TEMP_FILE"
        echo "" >> "$TEMP_FILE"
        
        parse_commits "${tags[0]}" "HEAD"
        
        cat "$TEMP_FILE" > "$CHANGELOG_FILE.new"
        cat "$CHANGELOG_FILE" >> "$CHANGELOG_FILE.new"
        mv "$CHANGELOG_FILE.new" "$CHANGELOG_FILE"
    fi
    
    rm -f "$TEMP_FILE"
    
    log_success "Changelog generated: $CHANGELOG_FILE"
}

# Function to validate changelog
validate_changelog() {
    log_info "Validating changelog..."
    
    local report_file="$DOCS_DIR/changelog_validation.txt"
    
    echo "Changelog Validation Report" > "$report_file"
    echo "==========================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Check for missing versions
    echo "Checking for missing versions..." >> "$report_file"
    git tag --sort=-v:refname | while read -r tag; do
        if ! grep -q "\[$tag\]" "$CHANGELOG_FILE"; then
            echo "- Missing version: $tag" >> "$report_file"
        fi
    done
    
    # Check for broken links
    echo "" >> "$report_file"
    echo "Checking for broken links..." >> "$report_file"
    grep -o "\[.*\]" "$CHANGELOG_FILE" | while read -r link; do
        if [[ "$link" =~ ^\[v[0-9] ]] && ! git tag | grep -q "${link:1:-1}"; then
            echo "- Broken version link: $link" >> "$report_file"
        fi
    done
    
    # Check for empty sections
    echo "" >> "$report_file"
    echo "Checking for empty sections..." >> "$report_file"
    sed -n '/^###/,/^$/p' "$CHANGELOG_FILE" | while read -r line; do
        if [[ "$line" =~ ^### ]] && [ -z "$(sed -n '/^###/,/^$/p' "$CHANGELOG_FILE" | grep "^-")" ]; then
            echo "- Empty section: ${line#### }" >> "$report_file"
        fi
    done
    
    log_success "Validation report generated: $report_file"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <command>"
        log_error "Commands: generate, validate"
        exit 1
    fi
    
    local command=$1
    
    case "$command" in
        "generate")
            generate_changelog
            ;;
        "validate")
            validate_changelog
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