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
   ```bash
   ./scripts/architecture/generate.sh viewmodel <name>
   ```

2. Create new view:
   ```bash
   ./scripts/architecture/generate.sh view <name>
   ```
