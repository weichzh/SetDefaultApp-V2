#!/bin/bash

# 设置错误时退出
set -e

APP_NAME="默认应用程序管理器"
BUNDLE_ID="com.example.SetDefaultApp"
VERSION="1.0.0"
BUILD_DIR=".build"
RELEASE_DIR="$BUILD_DIR/release"
APP_DIR="$RELEASE_DIR/$APP_NAME.app"

echo "🏗️  构建 $APP_NAME..."

# 清理之前的构建
echo "🧹 清理构建文件..."
rm -rf "$APP_DIR"
swift package clean

# 构建项目
echo "🔨 编译项目..."
swift build -c release

# 创建 .app 包结构
echo "📦 创建 .app 包..."
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

# 复制可执行文件
echo "📋 复制可执行文件..."
cp "$RELEASE_DIR/SetDefaultApp" "$APP_DIR/Contents/MacOS/"

# 创建 Info.plist
echo "📝 创建 Info.plist..."
cat > "$APP_DIR/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    
    <key>CFBundleExecutable</key>
    <string>SetDefaultApp</string>
    
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
    
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    
    <key>NSHighResolutionCapable</key>
    <true/>
    
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    
    <key>LSRequiresIPhoneOS</key>
    <false/>
    
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 设置可执行权限
chmod +x "$APP_DIR/Contents/MacOS/SetDefaultApp"

# 检查构建结果
if [ -d "$APP_DIR" ]; then
    echo "✅ 构建成功！"
    echo "📱 应用程序位置: $APP_DIR"
    echo ""
    echo "🚀 运行应用程序:"
    echo "   open '$APP_DIR'"
    echo ""
    echo "或者直接运行:"
    echo "   '$APP_DIR/Contents/MacOS/SetDefaultApp'"
    echo ""
    echo "注意：应用程序需要管理员权限来修改默认应用程序设置"
else
    echo "❌ 构建失败"
    exit 1
fi 