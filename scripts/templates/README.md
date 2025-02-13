# Project Templates

This directory contains project templates for different architecture patterns:

- clean_architecture/ - Clean Architecture pattern
- mvvm/ - Model-View-ViewModel pattern
- mvc/ - Model-View-Controller pattern  
- bloc/ - BLoC (Business Logic Component) pattern

## Usage

Create new project using template:
```bash
./scripts/architecture/create_project.sh create my_project <template_name>
```

List available templates:
```bash
./scripts/architecture/create_project.sh list
```

Create new template:
```bash
./scripts/architecture/create_project.sh new-template <template_name> [source_dir]
```
