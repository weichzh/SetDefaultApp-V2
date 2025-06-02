#!/bin/bash

# 设置错误时退出
set -e

echo "🏗️  构建默认应用程序管理器..."

# 清理之前的构建
echo "🧹 清理构建文件..."
swift package clean

# 构建项目
echo "🔨 编译项目..."
swift build -c release

# 检查构建是否成功
if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    echo ""
    echo "📱 运行应用程序..."
    echo "注意：应用程序需要管理员权限来修改默认应用程序设置"
    echo ""
    
    # 运行应用程序
    swift run
else
    echo "❌ 构建失败"
    exit 1
fi 