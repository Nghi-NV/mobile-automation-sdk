#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
REPORT_DIR="$PROJECT_PATH/reports/architecture"
RULES_FILE="$PROJECT_PATH/.architecture-rules"

# Function to check layer dependencies
check_layer_dependencies() {
    log_info "Checking layer dependencies..."
    
    local report_file="$REPORT_DIR/layer_dependencies.txt"
    mkdir -p "$REPORT_DIR"
    
    echo "Layer Dependencies Report" > "$report_file"
    echo "=======================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Check presentation -> domain dependencies
    echo "Checking presentation -> domain dependencies..." >> "$report_file"
    find "$LIB_DIR" -type f -name "*.dart" -path "*/presentation/*" | while read -r file; do
        if grep -q "import.*data/" "$file"; then
            echo "- Violation: $file imports from data layer" >> "$report_file"
        fi
    done
    
    # Check domain -> data dependencies
    echo "" >> "$report_file"
    echo "Checking domain -> data dependencies..." >> "$report_file"
    find "$LIB_DIR" -type f -name "*.dart" -path "*/domain/*" | while read -r file; do
        if grep -q "import.*data/" "$file"; then
            echo "- Violation: $file imports from data layer" >> "$report_file"
        fi
    done
    
    log_success "Layer dependencies report generated: $report_file"
}

# Function to check naming conventions
check_naming_conventions() {
    log_info "Checking naming conventions..."
    
    local report_file="$REPORT_DIR/naming_conventions.txt"
    
    echo "Naming Conventions Report" > "$report_file"
    echo "========================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Check feature naming
    echo "Checking feature naming..." >> "$report_file"
    find "$LIB_DIR/features" -type d -mindepth 1 -maxdepth 1 | while read -r dir; do
        local name=$(basename "$dir")
        if [[ ! "$name" =~ ^[a-z_]+$ ]]; then
            echo "- Invalid feature name: $name" >> "$report_file"
        fi
    done
    
    # Check bloc naming
    echo "" >> "$report_file"
    echo "Checking bloc naming..." >> "$report_file"
    find "$LIB_DIR" -type f -name "*_bloc.dart" | while read -r file; do
        local name=$(basename "$file")
        if [[ ! "$name" =~ ^[a-z_]+_bloc\.dart$ ]]; then
            echo "- Invalid bloc file name: $name" >> "$report_file"
        fi
    done
    
    log_success "Naming conventions report generated: $report_file"
}

# Function to check code organization
check_code_organization() {
    log_info "Checking code organization..."
    
    local report_file="$REPORT_DIR/code_organization.txt"
    
    echo "Code Organization Report" > "$report_file"
    echo "=======================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Check feature structure
    echo "Checking feature structure..." >> "$report_file"
    find "$LIB_DIR/features" -type d -mindepth 1 -maxdepth 1 | while read -r feature_dir; do
        local feature=$(basename "$feature_dir")
        echo "Feature: $feature" >> "$report_file"
        
        # Check required directories
        for dir in "data" "domain" "presentation"; do
            if [ ! -d "$feature_dir/$dir" ]; then
                echo "- Missing $dir directory" >> "$report_file"
            fi
        done
        
        # Check required files
        local required_files=(
            "data/repositories/${feature}_repository_impl.dart"
            "domain/repositories/${feature}_repository.dart"
            "presentation/bloc/${feature}_bloc.dart"
        )
        
        for file in "${required_files[@]}"; do
            if [ ! -f "$feature_dir/$file" ]; then
                echo "- Missing file: $file" >> "$report_file"
            fi
        done
        
        echo "" >> "$report_file"
    done
    
    log_success "Code organization report generated: $report_file"
}

# Function to check architecture rules
check_architecture_rules() {
    log_info "Checking architecture rules..."
    
    local report_file="$REPORT_DIR/architecture_rules.txt"
    
    echo "Architecture Rules Report" > "$report_file"
    echo "========================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    if [ -f "$RULES_FILE" ]; then
        while IFS= read -r rule; do
            if [[ "$rule" =~ ^# ]]; then
                continue
            fi
            
            echo "Checking rule: $rule" >> "$report_file"
            # Add your rule checking logic here
            echo "" >> "$report_file"
        done < "$RULES_FILE"
    else
        echo "No architecture rules file found" >> "$report_file"
    fi
    
    log_success "Architecture rules report generated: $report_file"
}

# Function to generate summary report
generate_summary() {
    log_info "Generating summary report..."
    
    local summary_file="$REPORT_DIR/summary.txt"
    
    echo "Architecture Validation Summary" > "$summary_file"
    echo "=============================" >> "$summary_file"
    echo "Generated: $(date)" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # Count violations
    local layer_violations=$(grep -c "Violation:" "$REPORT_DIR/layer_dependencies.txt" || echo "0")
    local naming_violations=$(grep -c "Invalid" "$REPORT_DIR/naming_conventions.txt" || echo "0")
    local missing_files=$(grep -c "Missing" "$REPORT_DIR/code_organization.txt" || echo "0")
    
    echo "Violations Summary:" >> "$summary_file"
    echo "- Layer Dependencies: $layer_violations" >> "$summary_file"
    echo "- Naming Conventions: $naming_violations" >> "$summary_file"
    echo "- Missing Files: $missing_files" >> "$summary_file"
    echo "" >> "$summary_file"
    
    # Add recommendations
    echo "Recommendations:" >> "$summary_file"
    if [ "$layer_violations" -gt 0 ]; then
        echo "- Fix layer dependency violations to maintain clean architecture" >> "$summary_file"
    fi
    if [ "$naming_violations" -gt 0 ]; then
        echo "- Follow naming conventions for better code maintainability" >> "$summary_file"
    fi
    if [ "$missing_files" -gt 0 ]; then
        echo "- Add missing files to complete feature implementations" >> "$summary_file"
    fi
    
    log_success "Summary report generated: $summary_file"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <command>"
        log_error "Commands: layers, naming, organization, rules, all"
        exit 1
    fi
    
    local command=$1
    
    mkdir -p "$REPORT_DIR"
    
    case "$command" in
        "layers")
            check_layer_dependencies
            ;;
        "naming")
            check_naming_conventions
            ;;
        "organization")
            check_code_organization
            ;;
        "rules")
            check_architecture_rules
            ;;
        "all")
            check_layer_dependencies
            check_naming_conventions
            check_code_organization
            check_architecture_rules
            generate_summary
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