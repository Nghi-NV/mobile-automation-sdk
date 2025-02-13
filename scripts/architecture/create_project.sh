#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Constants
TEMPLATES_DIR="$(dirname "$0")/../templates"
DEFAULT_TEMPLATE="clean_architecture"

# Function to list available templates
list_templates() {
    log_info "Available templates:"
    ls -1 "$TEMPLATES_DIR"
}

# Function to create project from template
create_project() {
    local project_name=$1
    local template=${2:-$DEFAULT_TEMPLATE}
    local output_dir=$3
    
    log_info "Creating project '$project_name' using template '$template'..."
    
    # Validate template exists
    if [ ! -d "$TEMPLATES_DIR/$template" ]; then
        log_error "Template '$template' not found"
        log_info "Available templates:"
        list_templates
        exit 1
    fi
    
    # Create project directory
    local project_dir="$output_dir/$project_name"
    if [ -d "$project_dir" ]; then
        log_error "Directory already exists: $project_dir"
        exit 1
    fi
    
    # Copy template
    cp -r "$TEMPLATES_DIR/$template" "$project_dir"
    
    # Replace template placeholders
    find "$project_dir" -type f -exec sed -i '' "s/{{project_name}}/$project_name/g" {} \;
    find "$project_dir" -type f -exec sed -i '' "s/{{project_name_pascal}}/$(echo "$project_name" | perl -pe 's/(^|_)./uc($&)/ge; s/_//g')/g" {} \;
    
    # Initialize git repository
    cd "$project_dir"
    git init
    git add .
    git commit -m "Initial commit from template: $template"
    
    # Setup dependencies
    flutter pub get
    
    # Create initial feature
    ./scripts/architecture/generate.sh feature home
    
    log_success "Project created successfully at: $project_dir"
    
    # Print next steps
    cat <<EOF

Next steps:
1. cd $project_dir
2. Review and update pubspec.yaml
3. Update README.md
4. Start building features with:
   ./scripts/architecture/generate.sh feature <feature_name>

Documentation:
- Architecture overview: docs/architecture/overview.md
- Development guide: docs/development.md
- Scripts usage: docs/scripts/README.md
EOF
}

# Function to create new template
create_template() {
    local template_name=$1
    local source_dir=${2:-"."}
    
    log_info "Creating template '$template_name' from '$source_dir'..."
    
    local template_dir="$TEMPLATES_DIR/$template_name"
    if [ -d "$template_dir" ]; then
        log_error "Template already exists: $template_name"
        exit 1
    fi
    
    # Create template directory
    mkdir -p "$template_dir"
    
    # Copy source files
    rsync -av --exclude={'.git','.dart_tool','build','ios/Pods','.idea','node_modules'} "$source_dir/" "$template_dir/"
    
    # Replace project-specific names with placeholders
    local project_name=$(basename "$source_dir")
    find "$template_dir" -type f -exec sed -i '' "s/$project_name/{{project_name}}/g" {} \;
    find "$template_dir" -type f -exec sed -i '' "s/$(echo "$project_name" | perl -pe 's/(^|_)./uc($&)/ge; s/_//g')/{{project_name_pascal}}/g" {} \;
    
    # Create template documentation
    cat > "$template_dir/README.md" <<EOF
# {{project_name_pascal}} Template

## Overview
This template provides a starting point for new Flutter projects using Clean Architecture.

## Features
- Clean Architecture structure
- Dependency injection setup
- Basic routing configuration
- Common utilities and widgets
- Testing setup
- CI/CD configuration

## Usage
\`\`\`bash
./scripts/architecture/create_project.sh new_project $template_name
\`\`\`

## Structure
\`\`\`
lib/
├── core/           # Core functionality
├── features/       # Feature modules
└── main.dart       # Application entry point
\`\`\`

## Customization
1. Update pubspec.yaml with required dependencies
2. Modify core configurations in lib/core
3. Add features using the generate script
EOF
    
    log_success "Template created successfully at: $template_dir"
}

# Main function
main() {
    if [ $# -lt 2 ]; then
        log_error "Usage: $0 <command> <name> [template|source_dir] [output_dir]"
        log_error "Commands: create, new-template, list"
        exit 1
    fi
    
    local command=$1
    local name=$2
    local template_or_source=$3
    local output_dir=${4:-$(pwd)}
    
    case "$command" in
        "create")
            create_project "$name" "$template_or_source" "$output_dir"
            ;;
        "new-template")
            create_template "$name" "$template_or_source"
            ;;
        "list")
            list_templates
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