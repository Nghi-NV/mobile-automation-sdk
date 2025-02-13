#!/bin/bash

# Load common utilities
source "$(dirname "$0")/../common/utils.sh"

# Constants
TEMPLATES_DIR="$(dirname "$0")/../templates"
CLEAN_ARCH_DIR="$TEMPLATES_DIR/clean_architecture"

# Function to setup templates directory
setup_templates_dir() {
    log_info "Setting up templates directory..."
    
    # Create templates directory if not exists
    mkdir -p "$TEMPLATES_DIR"
    
    # Create .gitkeep to track empty directory
    touch "$TEMPLATES_DIR/.gitkeep"
    
    # Create README for templates
    cat > "$TEMPLATES_DIR/README.md" <<EOF
# Project Templates

This directory contains project templates for different architecture patterns:

- clean_architecture/ - Clean Architecture pattern
- mvvm/ - Model-View-ViewModel pattern
- mvc/ - Model-View-Controller pattern  
- bloc/ - BLoC (Business Logic Component) pattern

## Usage

Create new project using template:
\`\`\`bash
./scripts/architecture/create_project.sh create my_project <template_name>
\`\`\`

List available templates:
\`\`\`bash
./scripts/architecture/create_project.sh list
\`\`\`

Create new template:
\`\`\`bash
./scripts/architecture/create_project.sh new-template <template_name> [source_dir]
\`\`\`
EOF

    log_success "Templates directory setup completed"
}

# Create clean architecture template
create_clean_arch_template() {
    log_info "Creating clean architecture template..."
    
    # Create directory structure
    mkdir -p "$CLEAN_ARCH_DIR"/{lib/{core/{di,network,storage,utils},features},test,scripts/architecture}
    
    # Create core files
    cat > "$CLEAN_ARCH_DIR/lib/core/di/injection.dart" <<EOF
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

Future<void> initializeDependencies() async {
  // Services
  
  // Repositories
  
  // UseCases
  
  // BLoCs
}
EOF

    cat > "$CLEAN_ARCH_DIR/lib/core/network/api_client.dart" <<EOF
class ApiClient {
  // TODO: Implement API client
}
EOF

    cat > "$CLEAN_ARCH_DIR/lib/core/storage/local_storage.dart" <<EOF
class LocalStorage {
  // TODO: Implement local storage
}
EOF

    cat > "$CLEAN_ARCH_DIR/lib/core/utils/logger.dart" <<EOF
class Logger {
  static void d(String message) {
    print('DEBUG: \$message');
  }
  
  static void e(String message) {
    print('ERROR: \$message');
  }
}
EOF

    # Create main.dart
    cat > "$CLEAN_ARCH_DIR/lib/main.dart" <<EOF
import 'package:flutter/material.dart';
import 'core/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '{{project_name_pascal}}',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Container(), // TODO: Add home page
    );
  }
}
EOF

    # Create pubspec.yaml
    cat > "$CLEAN_ARCH_DIR/pubspec.yaml" <<EOF
name: {{project_name}}
description: A new Flutter project using Clean Architecture.

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  get_it: ^7.2.0
  flutter_bloc: ^8.0.1
  equatable: ^2.0.3
  dio: ^4.0.6
  shared_preferences: ^2.0.15

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  mockito: ^5.2.0
  build_runner: ^2.1.11

flutter:
  uses-material-design: true
EOF

    # Create analysis_options.yaml
    cat > "$CLEAN_ARCH_DIR/analysis_options.yaml" <<EOF
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_declare_return_types
    - avoid_empty_else
    - avoid_print
    - prefer_const_constructors
    - prefer_final_fields
    - prefer_final_locals
EOF

    # Create .gitignore
    cat > "$CLEAN_ARCH_DIR/.gitignore" <<EOF
# Flutter/Dart
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
build/
ios/Pods/
.pub-cache/
.pub/

# IDE
.idea/
.vscode/
*.iml

# Project specific
.env
*.g.dart
coverage/
EOF

    # Create README.md
    cat > "$CLEAN_ARCH_DIR/README.md" <<EOF
# {{project_name_pascal}}

A new Flutter project using Clean Architecture.

## Getting Started

1. Setup dependencies:
   \`\`\`bash
   flutter pub get
   \`\`\`

2. Run code generation:
   \`\`\`bash
   flutter pub run build_runner build
   \`\`\`

3. Run the app:
   \`\`\`bash
   flutter run
   \`\`\`

## Architecture

This project follows Clean Architecture principles:

- lib/
  - core/          # Core functionality and utilities
  - features/      # Feature modules following clean architecture
    - feature_name/
      - data/      # Data layer (repositories, models, datasources)
      - domain/    # Domain layer (entities, repositories, usecases)
      - presentation/  # UI layer (pages, widgets, blocs)

## Scripts

Use the provided scripts for common tasks:

- Generate new feature:
  \`\`\`bash
  ./scripts/architecture/generate.sh feature <name>
  \`\`\`

- Analyze architecture:
  \`\`\`bash
  ./scripts/architecture/analyze.sh all
  \`\`\`

## Testing

Run tests with:
\`\`\`bash
flutter test
\`\`\`
EOF

    log_success "Clean architecture template created at: $CLEAN_ARCH_DIR"
}

# Create MVVM template
create_mvvm_template() {
    local template_dir="$TEMPLATES_DIR/mvvm"
    log_info "Creating MVVM template..."
    
    mkdir -p "$template_dir"/{lib/{core/{di,services,utils},features,shared/{models,widgets}},test}
    
    # Create core files
    cat > "$template_dir/lib/core/di/service_locator.dart" <<EOF
import 'package:get_it/get_it.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Register services
  
  // Register view models
}
EOF

    cat > "$template_dir/lib/core/services/navigation_service.dart" <<EOF
import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  Future<dynamic> navigateTo(String routeName, {dynamic arguments}) {
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }
  
  void goBack() {
    return navigatorKey.currentState!.pop();
  }
}
EOF

    # Create base view model
    cat > "$template_dir/lib/core/utils/base_view_model.dart" <<EOF
import 'package:flutter/material.dart';

class BaseViewModel extends ChangeNotifier {
  bool _busy = false;
  bool get busy => _busy;
  
  void setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}
EOF

    # Create pubspec.yaml
    cat > "$template_dir/pubspec.yaml" <<EOF
name: {{project_name}}
description: A new Flutter project using MVVM architecture.

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  get_it: ^7.2.0
  stacked: ^3.0.0
  stacked_services: ^0.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
  build_runner: ^2.1.11
EOF

    # Create README
    cat > "$template_dir/README.md" <<EOF
# {{project_name_pascal}} - MVVM Template

## Overview
This template follows the MVVM (Model-View-ViewModel) architecture pattern.

## Structure
- lib/
  - core/          # Core services and utilities
  - features/      # Feature modules
    - feature_name/
      - models/    # Data models
      - views/     # UI components
      - viewmodels/ # Business logic
  - shared/        # Shared components

## Usage
1. Create new view model:
   \`\`\`bash
   ./scripts/architecture/generate.sh viewmodel <name>
   \`\`\`

2. Create new view:
   \`\`\`bash
   ./scripts/architecture/generate.sh view <name>
   \`\`\`
EOF
}

# Create MVC template
create_mvc_template() {
    local template_dir="$TEMPLATES_DIR/mvc"
    log_info "Creating MVC template..."
    
    mkdir -p "$template_dir"/{lib/{controllers,models,views,utils},test}
    
    # Create base controller
    cat > "$template_dir/lib/controllers/base_controller.dart" <<EOF
abstract class BaseController {
  void init();
  void dispose();
}
EOF

    # Create pubspec.yaml
    cat > "$template_dir/pubspec.yaml" <<EOF
name: {{project_name}}
description: A new Flutter project using MVC architecture.

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  mvc_pattern: ^8.0.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
EOF

    # Create README
    cat > "$template_dir/README.md" <<EOF
# {{project_name_pascal}} - MVC Template

## Overview
This template follows the MVC (Model-View-Controller) architecture pattern.

## Structure
- lib/
  - controllers/  # Business logic
  - models/       # Data models
  - views/        # UI components
  - utils/        # Utilities

## Usage
1. Create new controller:
   \`\`\`bash
   ./scripts/architecture/generate.sh controller <name>
   \`\`\`

2. Create new model:
   \`\`\`bash
   ./scripts/architecture/generate.sh model <name>
   \`\`\`
EOF
}

# Create BLoC template
create_bloc_template() {
    local template_dir="$TEMPLATES_DIR/bloc"
    log_info "Creating BLoC template..."
    
    mkdir -p "$template_dir"/{lib/{blocs,repositories,models,screens,widgets},test}
    
    # Create base bloc
    cat > "$template_dir/lib/blocs/base_bloc.dart" <<EOF
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(State initialState) : super(initialState);
}
EOF

    # Create pubspec.yaml
    cat > "$template_dir/pubspec.yaml" <<EOF
name: {{project_name}}
description: A new Flutter project using BLoC pattern.

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=2.17.0 <3.0.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.0.0
  equatable: ^2.0.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.0.0
  flutter_lints: ^2.0.0
EOF

    # Create README
    cat > "$template_dir/README.md" <<EOF
# {{project_name_pascal}} - BLoC Template

## Overview
This template follows the BLoC (Business Logic Component) pattern.

## Structure
- lib/
  - blocs/        # Business logic components
  - repositories/ # Data layer
  - models/       # Data models
  - screens/      # UI screens
  - widgets/      # Reusable widgets

## Usage
1. Create new bloc:
   \`\`\`bash
   ./scripts/architecture/generate.sh bloc <name>
   \`\`\`

2. Create new repository:
   \`\`\`bash
   ./scripts/architecture/generate.sh repository <name>
   \`\`\`
EOF
}

# Main function
main() {
    # Setup templates directory first
    setup_templates_dir
    
    # Create all templates
    create_clean_arch_template
    create_mvvm_template
    create_mvc_template
    create_bloc_template
    
    log_success "All templates created successfully in: $TEMPLATES_DIR"
    log_info "Available templates:"
    ls -1 "$TEMPLATES_DIR" | grep -v "README.md\|.gitkeep"
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 