# SetDefaultApp v1.0.1

## 🐛 Bug Fixes

- **Compilation Error Fix**: Resolved an issue in `LaunchServicesManager.swift` where `setDefaultApplication` was using an incorrect parameter name (`toOpenContentType` instead of `toOpen`). This ensures the application compiles correctly on macOS 12.0+ environments.
- **API Usage Update**: Corrected the usage of `NSWorkspace.shared.setDefaultApplication` to match the latest Swift API signatures.

## 🛠️ Improvements

- **Stability**: Improved the stability of default application setting logic by ensuring correct API calls.
- **Code Quality**: Addressed deprecation warnings and potential runtime errors related to LaunchServices.

## 📦 Build Information

- **Version**: 1.0.1
- **Build Date**: 2026-02-15
- **Requirement**: macOS 13.0+

## 📝 Installation

1. Download `SetDefaultApp-macOS.dmg` from the release assets.
2. Drag `SetDefaultApp.app` to your Applications folder.
3. Open the app and follow the prompts.
