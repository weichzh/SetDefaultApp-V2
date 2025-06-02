# SetDefaultApp v1.0.0 - macOS Default Application Manager

## 🎉 Initial Release

SetDefaultApp is a modern macOS application that provides a Windows 11-style interface for managing default applications and file type associations on macOS.

## ✨ Features

### 🔍 **File Type Management**
- **Real-time Discovery**: Automatically scans all installed applications for supported file types
- **Comprehensive View**: Browse all file types and their current default applications
- **Search & Filter**: Quickly find specific file extensions or file types
- **Detailed Information**: View file type descriptions, extensions, and associated applications

### 📱 **Application Management**
- **Application Browser**: View all installed applications and their supported file types
- **Bidirectional View**: Switch between file types → apps and apps → file types
- **Application Details**: See comprehensive information about each application's capabilities
- **Real-time Updates**: Automatically refreshes when applications are installed or removed

### 🎯 **Default App Control**
- **Easy Assignment**: Change default applications with an intuitive interface
- **Alternative Apps**: View all capable applications for any file type
- **Native Integration**: Uses macOS LaunchServices for system-level changes
- **Instant Changes**: See updates immediately without requiring restarts

### 🎨 **Modern Interface**
- **SwiftUI Design**: Beautiful, native macOS interface with system integration
- **Dark Mode Support**: Fully supports macOS appearance preferences
- **Responsive Layout**: Optimized for all screen sizes and window configurations
- **Accessibility**: Full VoiceOver and accessibility support

## 💾 Installation

1. Download `SetDefaultApp-macOS.dmg` from the release assets
2. Double-click to mount the disk image
3. Drag `SetDefaultApp.app` to the `Applications` folder
4. Launch from Applications or Spotlight

## 🖥️ System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Architecture**: Universal Binary (Intel & Apple Silicon)
- **Permissions**: May require administrator privileges for system-level changes

## 🚀 Usage

### Getting Started
1. Launch SetDefaultApp from Applications
2. Browse file types in the left sidebar
3. View current default applications in the main view
4. Use the search bar to quickly find specific file types

### Changing Default Applications
1. Select a file type from the list
2. Click on the current default application
3. Choose a new application from the alternatives
4. Changes take effect immediately

### Application View
1. Switch to "Applications" tab
2. Browse installed applications
3. View supported file types for each app
4. Change defaults directly from application details

## 🛠️ Technical Details

- **Framework**: SwiftUI + AppKit
- **Language**: Swift 5.9+
- **Architecture**: Swift Package Manager
- **Integration**: macOS LaunchServices API
- **Performance**: Asynchronous scanning with concurrent processing

## 📋 What's Included

- `SetDefaultApp.app` - The main application
- `README.txt` - Basic documentation
- `Installation Guide.txt` - Step-by-step installation instructions

## 🔧 Advanced Features

- **Batch Operations**: Change multiple file type associations at once
- **Import/Export**: Save and restore default application configurations
- **System Integration**: Respects macOS security and permission models
- **Performance Optimization**: Efficient scanning with minimal system impact

## 🐛 Known Issues

- Some system-protected file types may require administrator privileges
- Application scanning may take a moment on first launch
- Custom URL schemes are displayed but may have limited modification support

## 🙏 Acknowledgments

Built with modern macOS development practices and inspired by Windows 11's default apps interface.

## 📞 Support

For issues, feature requests, or contributions, please visit the [GitHub repository](https://github.com/your-username/SetDefaultApp-V2).

---

**File Size**: ~380KB  
**Built**: June 2024  
**License**: MIT (see repository for details) 