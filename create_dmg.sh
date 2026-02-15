#!/bin/bash

# Create DMG script for SetDefaultApp
# This script builds the app and creates a distributable DMG file

set -e  # Exit on any error

# Configuration
APP_NAME="SetDefaultApp"
APP_NAME_CN="默认应用程序管理器"
DMG_NAME="SetDefaultApp-macOS"
BUILD_DIR="build"
TEMP_DMG_DIR="temp_dmg"
VERSION="1.0.1"

echo "🚀 Building ${APP_NAME} for distribution..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${TEMP_DMG_DIR}"
rm -f "${DMG_NAME}.dmg"

# Build the application
echo "🔨 Building application..."
swift build --configuration release

# Create the .app bundle
echo "📦 Creating .app bundle..."
mkdir -p "${BUILD_DIR}"

# Run the existing build_app.sh script
if [ -f "build_app.sh" ]; then
    chmod +x build_app.sh
    ./build_app.sh
    
    # The build script creates the app, copy it immediately
    BUILT_APP_PATH=".build/release/${APP_NAME_CN}.app"
    if [ -d "${BUILT_APP_PATH}" ]; then
        echo "📱 Found app at: ${BUILT_APP_PATH}"
        cp -R "${BUILT_APP_PATH}" "${BUILD_DIR}/${APP_NAME}.app"
        echo "✅ Copied app to: ${BUILD_DIR}/${APP_NAME}.app"
    else
        echo "❌ Failed to find .app bundle at ${BUILT_APP_PATH}"
        echo "Searching for any .app files:"
        find .build -name "*.app" -type d 2>/dev/null || echo "No .app files found"
        exit 1
    fi
else
    echo "❌ build_app.sh not found"
    exit 1
fi

# Create temporary DMG directory
echo "📁 Preparing DMG contents..."
mkdir -p "${TEMP_DMG_DIR}"

# Copy the app to temp directory
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${TEMP_DMG_DIR}/"

# Create a symbolic link to Applications folder for easy installation
ln -s /Applications "${TEMP_DMG_DIR}/Applications"

# Copy README and other documentation
if [ -f "README.md" ]; then
    cp README.md "${TEMP_DMG_DIR}/README.txt"
fi

# Create a simple installation guide
cat > "${TEMP_DMG_DIR}/Installation Guide.txt" << EOF
SetDefaultApp - macOS Default Application Manager

INSTALLATION:
1. Drag SetDefaultApp.app to the Applications folder
2. Open SetDefaultApp from Applications or Launchpad
3. The app will help you manage default applications for file types

REQUIREMENTS:
- macOS 13.0 or later
- Administrator privileges may be required for some operations

USAGE:
- Browse file types and see which apps handle them
- Search for specific file extensions or applications
- Change default applications for file types
- Manage application associations

For more information, visit: https://github.com/your-username/SetDefaultApp-V2

Version: ${VERSION}
Built: $(date)
EOF

# Calculate size for DMG (add some padding)
SIZE=$(du -sm "${TEMP_DMG_DIR}" | cut -f1)
SIZE=$((SIZE + 50))  # Add 50MB padding

echo "📀 Creating DMG file..."

# Create the DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${TEMP_DMG_DIR}" \
    -ov \
    -format UDZO \
    -size ${SIZE}m \
    "${DMG_NAME}.dmg"

# Clean up
echo "🧹 Cleaning up temporary files..."
rm -rf "${TEMP_DMG_DIR}"
rm -rf "${BUILD_DIR}"

# Get DMG size
DMG_SIZE=$(du -h "${DMG_NAME}.dmg" | cut -f1)

echo "✅ DMG created successfully!"
echo "📦 File: ${DMG_NAME}.dmg"
echo "📏 Size: ${DMG_SIZE}"
echo ""
echo "🚀 Ready for GitHub release!"
echo "   You can now upload ${DMG_NAME}.dmg to your GitHub release" 