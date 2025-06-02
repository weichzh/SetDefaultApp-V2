#!/bin/bash

# Advanced DMG creation script for SetDefaultApp
# Creates a professional-looking DMG with custom background and layout

set -e  # Exit on any error

# Configuration
APP_NAME="SetDefaultApp"
DMG_NAME="SetDefaultApp-macOS"
BUILD_DIR="build"
TEMP_DMG_DIR="temp_dmg"
RESOURCES_DIR="dmg_resources"
VERSION="1.0.0"

echo "🚀 Building ${APP_NAME} for distribution (Advanced DMG)..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${TEMP_DMG_DIR}"
rm -rf "${RESOURCES_DIR}"
rm -f "${DMG_NAME}.dmg"
rm -f "${DMG_NAME}-temp.dmg"

# Create resources directory
mkdir -p "${RESOURCES_DIR}"

# Create a simple background image using ImageMagick (if available) or just skip
if command -v convert >/dev/null 2>&1; then
    echo "🎨 Creating DMG background..."
    convert -size 600x400 gradient:#f0f0f0-#e0e0e0 \
        -pointsize 24 -fill '#333333' \
        -gravity center -annotate +0-100 'SetDefaultApp' \
        -pointsize 14 -fill '#666666' \
        -gravity center -annotate +0-70 'macOS Default Application Manager' \
        -pointsize 12 -fill '#888888' \
        -gravity center -annotate +0+150 'Drag app to Applications folder to install' \
        "${RESOURCES_DIR}/background.png"
else
    echo "ℹ️  ImageMagick not found, creating DMG without custom background"
fi

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
    
    # Move the built app to our build directory
    if [ -d "${APP_NAME}.app" ]; then
        mv "${APP_NAME}.app" "${BUILD_DIR}/"
    else
        echo "❌ Failed to create .app bundle"
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

# Copy documentation
if [ -f "README.md" ]; then
    cp README.md "${TEMP_DMG_DIR}/ReadMe.txt"
fi

# Create release notes
cat > "${TEMP_DMG_DIR}/Release Notes.txt" << EOF
SetDefaultApp v${VERSION} - Release Notes

What's New:
• Modern SwiftUI interface with native macOS design
• Real-time file type discovery from all installed applications
• Bidirectional management (file types ↔ applications)
• Advanced search and filtering capabilities
• Support for changing default applications
• Windows 11-style default app management experience

Features:
• Browse all file types and their default applications
• View detailed application information and supported formats
• Change default applications with easy-to-use interface
• Search functionality for quick access
• Real-time updates when applications are installed/removed
• Native integration with macOS LaunchServices

System Requirements:
• macOS 13.0 (Ventura) or later
• 64-bit Intel or Apple Silicon Mac

Installation:
1. Mount this disk image
2. Drag SetDefaultApp.app to the Applications folder
3. Launch from Applications or Spotlight

Built: $(date)
EOF

# Calculate size for DMG
SIZE=$(du -sm "${TEMP_DMG_DIR}" | cut -f1)
SIZE=$((SIZE + 100))  # Add padding

echo "📀 Creating temporary DMG..."

# Create temporary DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${TEMP_DMG_DIR}" \
    -ov \
    -format UDRW \
    -size ${SIZE}m \
    "${DMG_NAME}-temp.dmg"

# Mount the temporary DMG
MOUNT_DIR="/Volumes/${APP_NAME}"
echo "📂 Mounting temporary DMG..."
hdiutil attach "${DMG_NAME}-temp.dmg"

# Wait for mount
sleep 2

# Configure the DMG window appearance using AppleScript
echo "🎨 Configuring DMG appearance..."

# Create AppleScript to set up the DMG window
cat > "${RESOURCES_DIR}/setup_dmg.applescript" << 'EOF'
tell application "Finder"
    tell disk "SetDefaultApp"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 128
        set background picture of viewOptions to file ".background:background.png"
        
        -- Position items
        set position of item "SetDefaultApp.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        set position of item "ReadMe.txt" of container window to {150, 320}
        set position of item "Release Notes.txt" of container window to {450, 320}
        
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Copy background image if it exists
if [ -f "${RESOURCES_DIR}/background.png" ]; then
    mkdir -p "${MOUNT_DIR}/.background"
    cp "${RESOURCES_DIR}/background.png" "${MOUNT_DIR}/.background/"
fi

# Run the AppleScript to configure appearance
if [ -f "${RESOURCES_DIR}/background.png" ]; then
    osascript "${RESOURCES_DIR}/setup_dmg.applescript" || echo "⚠️  Could not set custom DMG appearance"
fi

# Unmount the temporary DMG
echo "📤 Unmounting temporary DMG..."
hdiutil detach "${MOUNT_DIR}"

# Wait for unmount
sleep 2

# Convert to compressed read-only DMG
echo "🗜️  Creating final compressed DMG..."
hdiutil convert "${DMG_NAME}-temp.dmg" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${DMG_NAME}.dmg"

# Clean up
echo "🧹 Cleaning up temporary files..."
rm -rf "${TEMP_DMG_DIR}"
rm -rf "${BUILD_DIR}"
rm -rf "${RESOURCES_DIR}"
rm -f "${DMG_NAME}-temp.dmg"

# Get final DMG info
DMG_SIZE=$(du -h "${DMG_NAME}.dmg" | cut -f1)
DMG_PATH=$(pwd)/${DMG_NAME}.dmg

echo ""
echo "✅ Advanced DMG created successfully!"
echo "📦 File: ${DMG_NAME}.dmg"
echo "📏 Size: ${DMG_SIZE}"
echo "📁 Path: ${DMG_PATH}"
echo ""
echo "🚀 Ready for GitHub release!"
echo "   Upload this file to your GitHub release"
echo "   Users can download and install by dragging to Applications" 