# Mobile Build Automation SDK

This SDK is created to automate the mobile app build process for both iOS and Android platforms.

## System Requirements

### Common
- Git
- Node.js (>= 14.0.0)
- Yarn or NPM

### iOS Requirements
- macOS
- Xcode (>= 13.0)
- Ruby (>= 2.6)
- Fastlane
- Apple Developer Account

### Android Requirements
- Android Studio
- Java Development Kit (JDK 11)
- Android SDK
- Gradle

## Installation

1. Clone repository:

```bash
git clone https://github.com/Nghi-NV/mobile-automation-sdk.git
```

2. Configure environment:
- Copy `.env.default` to `.env`
- Update information in `.env` file:

```bash
cp .env.default .env
```

3. Install dependencies:

```bash
# Install Fastlane (for iOS)
gem install fastlane

# Install required tools
brew install node
brew install watchman
brew install cocoapods

# Install project dependencies
yarn install # or npm install
```

## Scripts Structure

```
scripts/
├── ios/
│   ├── build.sh          # iOS build script
│   ├── upload.sh         # Upload iOS build to TestFlight
│   └── sign.sh          # Handle signing certificates
├── android/
│   ├── build.sh         # Android build script
│   ├── upload.sh        # Upload APK/AAB to Play Store
│   └── sign.sh         # Handle keystore
└── common/
    ├── notify.sh        # Send notifications via Lark
    ├── version.sh       # Version management
    └── utils.sh         # Utility functions
```

## Using Scripts

### iOS Build

```bash
# Build iOS Development
./scripts/ios/build.sh development

# Build iOS Staging
./scripts/ios/build.sh staging

# Build iOS Production
./scripts/ios/build.sh production
```

Available parameters:
- `--clean`: Clean build before new build
- `--upload`: Auto upload to TestFlight after build
- `--notify`: Send notification after build

Example:
```bash
./scripts/ios/build.sh production --clean --upload --notify
```

### Android Build

```bash
# Build Android Development
./scripts/android/build.sh development

# Build Android Staging
./scripts/android/build.sh staging

# Build Android Production
./scripts/android/build.sh production
```

Available parameters:
- `--clean`: Clean build before new build
- `--aab`: Build Android App Bundle format
- `--upload`: Auto upload to Play Console
- `--notify`: Send notification after build

Example:
```bash
./scripts/android/build.sh production --clean --aab --upload --notify
```

## Lark Notifications

The SDK uses Lark Bot to send build status notifications. Notification format includes:
- Project name
- Platform (iOS/Android)
- Environment (dev/staging/prod)
- Version number
- Build number
- Status (success/failure)
- Download link (if build successful)
- Error log (if build failed)

## Version Management

Use `version.sh` script to manage versions:

```bash
# Bump patch version (1.0.0 -> 1.0.1)
./scripts/common/version.sh bump patch

# Bump minor version (1.0.0 -> 1.1.0)
./scripts/common/version.sh bump minor

# Bump major version (1.0.0 -> 2.0.0)
./scripts/common/version.sh bump major
```

## Common Issues

### iOS Build Issues

1. **Certificate Issues**
```bash
# Check certificates
./scripts/ios/sign.sh check-certs

# Fetch certificates
./scripts/ios/sign.sh fetch-certs
```

2. **Provisioning Profile Issues**
```bash
# Check profiles
./scripts/ios/sign.sh check-profiles

# Fetch profiles
./scripts/ios/sign.sh fetch-profiles
```

### Android Build Issues

1. **Keystore Issues**
```bash
# Verify keystore
./scripts/android/sign.sh verify-keystore

# Generate new keystore
./scripts/android/sign.sh generate-keystore
```

2. **Gradle Issues**
```bash
# Clean Gradle cache
./scripts/android/build.sh clean-gradle

# Update Gradle wrapper
./scripts/android/build.sh update-gradle
```

## Generate App Icons

The SDK provides scripts to automatically generate app icons for both iOS and Android from a source image.

### Requirements
- ImageMagick (`brew install imagemagick`)
- Source image with minimum size of 1024x1024 pixels
- PNG format with transparent background

### Usage

```bash
# Generate icons for both iOS and Android
./scripts/common/generate_icons.sh path/to/icon.png

# Generate only iOS icons
./scripts/common/generate_icons.sh path/to/icon.png ios

# Generate only Android icons
./scripts/common/generate_icons.sh path/to/icon.png android
```

### iOS Icons

The script will automatically generate the following icon sizes:

#### iPhone
- 20pt: @2x, @3x (40px, 60px)
- 29pt: @2x, @3x (58px, 87px)
- 40pt: @2x, @3x (80px, 120px)
- 60pt: @2x, @3x (120px, 180px)

#### iPad
- 20pt: @1x, @2x (20px, 40px)
- 29pt: @1x, @2x (29px, 58px)
- 40pt: @1x, @2x (40px, 80px)
- 76pt: @1x, @2x (76px, 152px)
- 83.5pt: @2x (167px)

#### App Store
- 1024pt @1x (1024px)

Icons will be generated in:
```
ios/<PROJECT_NAME>/Images.xcassets/AppIcon.appiconset/
```

### Android Icons

The script will generate the following icon types for each density:

| Density    | Icon Size | Round Icon |
|------------|-----------|------------|
| mdpi       | 36x36     | ✓          |
| hdpi       | 48x48     | ✓          |
| xhdpi      | 72x72     | ✓          |
| xxhdpi     | 96x96     | ✓          |
| xxxhdpi    | 144x144   | ✓          |

Additionally:
- Adaptive Icons (Android 8.0+)
- Foreground layer with padding
- Customizable background layer

Icons will be generated in:
```
android/app/src/main/res/mipmap-*/
```

### Customization

You can customize the following parameters in the script:
- Background color for Android adaptive icons
- Padding for foreground layer
- Add/remove icon sizes
- Change output file format

### Troubleshooting

1. **ImageMagick not installed**
```bash
brew install imagemagick
```

2. **Source image too small**
- Use image with minimum size of 1024x1024 pixels
- Recommended to use vector file for best quality

3. **Permission issues**
```bash
chmod +x scripts/common/generate_icons.sh
```

## Contributing

When contributing to this project, please follow these rules:

1. Create new branch for each feature/fix
2. Use conventional commits
3. Write tests for changes
4. Update documentation if needed
5. Create pull request with detailed description

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

NghiNV (Nghi-NV) 