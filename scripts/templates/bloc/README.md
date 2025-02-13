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
   ```bash
   ./scripts/architecture/generate.sh bloc <name>
   ```

2. Create new repository:
   ```bash
   ./scripts/architecture/generate.sh repository <name>
   ```
