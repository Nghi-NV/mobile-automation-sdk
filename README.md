# Mobile Build Automation SDK

SDK này được tạo ra để tự động hóa quá trình build ứng dụng mobile cho cả iOS và Android platforms.

## Yêu cầu hệ thống

### Chung
- Git
- Node.js (>= 14.0.0)
- Yarn hoặc NPM

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

## Cài đặt

1. Clone repository:

```bash
git clone https://github.com/Nghi-NV/mobile-automation-sdk.git
```

2. Cấu hình môi trường:
- Copy file `.env.default` thành `.env`
- Cập nhật các thông tin trong file `.env`:

```bash
cp .env.default .env
```

3. Cài đặt các dependencies:

```bash
# Cài đặt Fastlane (cho iOS)
gem install fastlane

# Cài đặt các công cụ cần thiết
brew install node
brew install watchman
brew install cocoapods

# Cài đặt các dependencies của project
yarn install # hoặc npm install
```

## Cấu trúc Scripts

```
scripts/
├── ios/
│   ├── build.sh          # Script build iOS
│   ├── upload.sh         # Upload iOS build lên TestFlight
│   └── sign.sh          # Xử lý signing certificates
├── android/
│   ├── build.sh         # Script build Android
│   ├── upload.sh        # Upload APK/AAB lên Play Store
│   └── sign.sh         # Xử lý keystore
└── common/
    ├── notify.sh        # Gửi thông báo qua Lark
    ├── version.sh       # Quản lý version
    └── utils.sh         # Các utility functions
```

## Sử dụng Scripts

### iOS Build

```bash
# Build iOS Development
./scripts/ios/build.sh development

# Build iOS Staging
./scripts/ios/build.sh staging

# Build iOS Production
./scripts/ios/build.sh production
```

Các tham số có thể sử dụng:
- `--clean`: Clean build trước khi build mới
- `--upload`: Tự động upload lên TestFlight sau khi build
- `--notify`: Gửi thông báo sau khi build xong

Ví dụ:
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

Các tham số có thể sử dụng:
- `--clean`: Clean build trước khi build mới
- `--aab`: Build định dạng Android App Bundle
- `--upload`: Tự động upload lên Play Console
- `--notify`: Gửi thông báo sau khi build xong

Ví dụ:
```bash
./scripts/android/build.sh production --clean --aab --upload --notify
```

## Thông báo qua Lark

SDK sử dụng Lark Bot để gửi thông báo về trạng thái build. Định dạng thông báo bao gồm:
- Tên project
- Platform (iOS/Android)
- Environment (dev/staging/prod)
- Version number
- Build number
- Status (success/failure)
- Download link (nếu build thành công)
- Error log (nếu build thất bại)

## Quản lý Version

Sử dụng script `version.sh` để quản lý version:

```bash
# Tăng version patch (1.0.0 -> 1.0.1)
./scripts/common/version.sh bump patch

# Tăng version minor (1.0.0 -> 1.1.0)
./scripts/common/version.sh bump minor

# Tăng version major (1.0.0 -> 2.0.0)
./scripts/common/version.sh bump major
```

## Xử lý lỗi thường gặp

### iOS Build Issues

1. **Lỗi Certificates**
```bash
# Kiểm tra certificates
./scripts/ios/sign.sh check-certs

# Tải lại certificates
./scripts/ios/sign.sh fetch-certs
```

2. **Lỗi Provisioning Profiles**
```bash
# Kiểm tra profiles
./scripts/ios/sign.sh check-profiles

# Tải lại profiles
./scripts/ios/sign.sh fetch-profiles
```

### Android Build Issues

1. **Lỗi Keystore**
```bash
# Kiểm tra keystore
sh ./scripts/android/sign.sh verify

# Tạo keystore mới
sh ./scripts/android/sign.sh generate
```

2. **Lỗi Gradle**
```bash
# Clean Gradle cache
./scripts/android/build.sh clean-gradle

# Update Gradle wrapper
./scripts/android/build.sh update-gradle
```

## Tạo App Icons

SDK cung cấp script để tự động tạo app icons cho cả iOS và Android từ một file ảnh nguồn.

### Yêu cầu
- ImageMagick (`brew install imagemagick`)
- File ảnh nguồn có kích thước tối thiểu 1024x1024 pixels
- Định dạng PNG với nền trong suốt

### Sử dụng

```bash
# Tạo icons cho cả iOS và Android
./scripts/common/generate_icons.sh path/to/icon.png

# Chỉ tạo icons cho iOS
./scripts/common/generate_icons.sh path/to/icon.png ios

# Chỉ tạo icons cho Android
./scripts/common/generate_icons.sh path/to/icon.png android
```

### iOS Icons

Script sẽ tự động tạo các kích thước icon sau:

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

Icons sẽ được tạo trong thư mục:
```
ios/<PROJECT_NAME>/Images.xcassets/AppIcon.appiconset/
```

### Android Icons

Script sẽ tạo các loại icon sau cho mỗi mật độ điểm ảnh:

| Density    | Icon Size | Round Icon |
|------------|-----------|------------|
| mdpi       | 36x36     | ✓          |
| hdpi       | 48x48     | ✓          |
| xhdpi      | 72x72     | ✓          |
| xxhdpi     | 96x96     | ✓          |
| xxxhdpi    | 144x144   | ✓          |

Ngoài ra còn tạo:
- Adaptive Icons (Android 8.0+)
- Foreground layer với padding
- Background layer có thể tùy chỉnh

Icons sẽ được tạo trong các thư mục:
```
android/app/src/main/res/mipmap-*/
```

### Tùy chỉnh

Bạn có thể tùy chỉnh các thông số trong script:
- Background color cho Android adaptive icons
- Padding cho foreground layer
- Thêm/bớt kích thước icon
- Thay đổi định dạng file output

### Xử lý lỗi

1. **ImageMagick không được cài đặt**
```bash
brew install imagemagick
```

2. **File ảnh nguồn quá nhỏ**
- Sử dụng file ảnh có kích thước tối thiểu 1024x1024 pixels
- Khuyến nghị sử dụng file vector để có chất lượng tốt nhất

3. **Lỗi permissions**
```bash
chmod +x scripts/common/generate_icons.sh
```

## Contributing

Khi đóng góp vào project, vui lòng tuân thủ các quy tắc sau:

1. Tạo branch mới cho mỗi feature/fix
2. Sử dụng conventional commits
3. Viết tests cho các thay đổi
4. Update documentation nếu cần thiết
5. Tạo pull request với mô tả chi tiết

## License

MIT License - xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## Author

NghiNV (Nghi-NV)
