# {{project_name_pascal}}

A new Flutter project using Clean Architecture.

## Getting Started

1. Setup dependencies:
   ```bash
   flutter pub get
   ```

2. Run code generation:
   ```bash
   flutter pub run build_runner build
   ```

3. Run the app:
   ```bash
   flutter run
   ```

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
  ```bash
  ./scripts/architecture/generate.sh feature <name>
  ```

- Analyze architecture:
  ```bash
  ./scripts/architecture/analyze.sh all
  ```

## Testing

Run tests with:
```bash
flutter test
```
