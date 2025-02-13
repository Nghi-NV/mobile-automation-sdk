#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Initialize environment
load_env
validate_env

# Constants
ANALYSIS_DIR="$PROJECT_PATH/reports/analysis"
METRICS_FILE="$ANALYSIS_DIR/metrics.json"

# Function to analyze code metrics
analyze_metrics() {
    log_info "Analyzing code metrics..."
    
    mkdir -p "$ANALYSIS_DIR"
    
    # Run dart analyze
    dart analyze > "$ANALYSIS_DIR/static_analysis.txt"
    
    # Run metrics analysis
    dart run dart_code_metrics:metrics analyze lib > "$ANALYSIS_DIR/code_metrics.txt"
    
    # Generate metrics JSON
    dart run dart_code_metrics:metrics analyze lib --reporter=json > "$METRICS_FILE"
    
    log_success "Code metrics analysis completed"
}

# Function to analyze dependencies
analyze_dependencies() {
    log_info "Analyzing dependencies..."
    
    local report_file="$ANALYSIS_DIR/dependencies.txt"
    
    echo "Dependencies Analysis Report" > "$report_file"
    echo "==========================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Analyze package dependencies
    echo "Package Dependencies:" >> "$report_file"
    dart pub deps >> "$report_file"
    
    # Analyze feature dependencies
    echo "" >> "$report_file"
    echo "Feature Dependencies:" >> "$report_file"
    find "$LIB_DIR/features" -type d -mindepth 1 -maxdepth 1 | while read -r feature_dir; do
        local feature=$(basename "$feature_dir")
        echo "Feature: $feature" >> "$report_file"
        
        # Find imports
        find "$feature_dir" -type f -name "*.dart" -exec grep -H "^import" {} \; | \
            grep -v "package:$PROJECT_NAME/features/$feature" >> "$report_file"
        
        echo "" >> "$report_file"
    done
    
    log_success "Dependencies analysis completed"
}

# Function to analyze complexity
analyze_complexity() {
    log_info "Analyzing code complexity..."
    
    local report_file="$ANALYSIS_DIR/complexity.txt"
    
    echo "Code Complexity Report" > "$report_file"
    echo "=====================" >> "$report_file"
    echo "Generated: $(date)" >> "$report_file"
    echo "" >> "$report_file"
    
    # Analyze cyclomatic complexity
    find "$LIB_DIR" -type f -name "*.dart" | while read -r file; do
        echo "File: ${file#$LIB_DIR/}" >> "$report_file"
        
        # Count conditional statements
        local conditionals=$(grep -c -E "if|switch|while|for|catch" "$file")
        echo "- Conditional statements: $conditionals" >> "$report_file"
        
        # Count methods
        local methods=$(grep -c -E "^[[:space:]]*[A-Za-z_][A-Za-z0-9_]*\([^)]*\)[[:space:]]*{" "$file")
        echo "- Methods: $methods" >> "$report_file"
        
        # Calculate complexity score
        local score=$((conditionals + methods))
        echo "- Complexity score: $score" >> "$report_file"
        
        if [ $score -gt 20 ]; then
            echo "  WARNING: High complexity" >> "$report_file"
        fi
        
        echo "" >> "$report_file"
    done
    
    log_success "Complexity analysis completed"
}

# Function to analyze test coverage
analyze_test_coverage() {
    log_info "Analyzing test coverage..."
    
    local report_dir="$ANALYSIS_DIR/coverage"
    mkdir -p "$report_dir"
    
    # Run tests with coverage
    flutter test --coverage
    
    # Generate coverage report
    genhtml coverage/lcov.info -o "$report_dir"
    
    # Generate summary
    local coverage_file="$ANALYSIS_DIR/test_coverage.txt"
    
    echo "Test Coverage Report" > "$coverage_file"
    echo "===================" >> "$coverage_file"
    echo "Generated: $(date)" >> "$coverage_file"
    echo "" >> "$coverage_file"
    
    lcov --summary coverage/lcov.info >> "$coverage_file"
    
    log_success "Test coverage analysis completed"
}

# Function to generate visualization
generate_visualization() {
    log_info "Generating architecture visualization..."
    
    local output_dir="$ANALYSIS_DIR/visualization"
    mkdir -p "$output_dir"
    
    # Generate dependency graph
    if ! command -v dot &> /dev/null; then
        log_error "Graphviz not installed. Please install it first:"
        log_error "brew install graphviz"
        exit 1
    fi
    
    # Create DOT file
    local dot_file="$output_dir/architecture.dot"
    
    echo "digraph Architecture {" > "$dot_file"
    echo "  rankdir=TB;" >> "$dot_file"
    echo "  node [shape=box];" >> "$dot_file"
    
    # Add features
    find "$LIB_DIR/features" -type d -mindepth 1 -maxdepth 1 | while read -r feature_dir; do
        local feature=$(basename "$feature_dir")
        echo "  \"$feature\" [style=filled,fillcolor=lightblue];" >> "$dot_file"
        
        # Add dependencies
        find "$feature_dir" -type f -name "*.dart" -exec grep -H "^import" {} \; | \
            grep "package:$PROJECT_NAME/features/" | \
            sed -E "s/.*features\/([^\/]+).*/\1/" | \
            sort -u | while read -r dep; do
                if [ "$dep" != "$feature" ]; then
                    echo "  \"$feature\" -> \"$dep\";" >> "$dot_file"
                fi
            done
    done
    
    echo "}" >> "$dot_file"
    
    # Generate PNG
    dot -Tpng "$dot_file" -o "$output_dir/architecture.png"
    
    log_success "Architecture visualization generated"
}

# Function to generate report
generate_report() {
    log_info "Generating analysis report..."
    
    local report_file="$ANALYSIS_DIR/report.md"
    
    cat > "$report_file" <<EOF
# Architecture Analysis Report

Generated: $(date)

## Overview

This report provides a comprehensive analysis of the project's architecture.

## Code Metrics

$(cat "$ANALYSIS_DIR/code_metrics.txt")

## Dependencies

$(cat "$ANALYSIS_DIR/dependencies.txt")

## Complexity

$(cat "$ANALYSIS_DIR/complexity.txt")

## Test Coverage

$(cat "$ANALYSIS_DIR/test_coverage.txt")

## Recommendations

EOF
    
    # Add recommendations based on analysis
    if grep -q "WARNING" "$ANALYSIS_DIR/complexity.txt"; then
        echo "- Consider refactoring complex code modules" >> "$report_file"
    fi
    
    if [ $(grep -c "import" "$ANALYSIS_DIR/dependencies.txt") -gt 100 ]; then
        echo "- Review and optimize dependencies" >> "$report_file"
    fi
    
    local coverage=$(grep "lines" "$ANALYSIS_DIR/test_coverage.txt" | awk '{print $2}' | tr -d '%')
    if [ -n "$coverage" ] && [ "$coverage" -lt 80 ]; then
        echo "- Improve test coverage (current: ${coverage}%)" >> "$report_file"
    fi
    
    log_success "Analysis report generated: $report_file"
}

# Main function
main() {
    if [ $# -lt 1 ]; then
        log_error "Usage: $0 <command>"
        log_error "Commands: metrics, dependencies, complexity, coverage, visualization, all"
        exit 1
    fi
    
    local command=$1
    
    mkdir -p "$ANALYSIS_DIR"
    
    case "$command" in
        "metrics")
            analyze_metrics
            ;;
        "dependencies")
            analyze_dependencies
            ;;
        "complexity")
            analyze_complexity
            ;;
        "coverage")
            analyze_test_coverage
            ;;
        "visualization")
            generate_visualization
            ;;
        "all")
            analyze_metrics
            analyze_dependencies
            analyze_complexity
            analyze_test_coverage
            generate_visualization
            generate_report
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