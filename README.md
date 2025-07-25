# 默认应用程序管理器

一个用于管理 macOS 默认应用程序的工具，提供直观的图形界面来设置文件类型的默认应用程序。

## 功能特点

- 🗂️ **智能文件类型发现** - 深度解析所有应用程序的 Info.plist 文件，发现所有支持的文件类型
- 🔍 **全面扫描** - 扫描 `/Applications`、`/System/Applications` 等文件夹，包括系统应用和用户应用
- 📱 **灵活的应用程序管理** - 在应用详情中可以更改已设置的默认文件类型
- 🔄 **双向管理** - 既可以从文件类型找应用，也可以从应用程序管理文件类型
- 🔍 **强大搜索功能** - 可按文件类型名称、UTI、扩展名或应用程序名称搜索
- 🎨 **现代界面** - 使用 SwiftUI 构建的原生 macOS 界面
- ⚡ **实时更新** - 显示当前默认应用程序状态和即时更新
- 📊 **详细信息** - 显示文件类型的 UTI、扩展名、支持的应用程序数量等详细信息

## 系统要求

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本

## 构建方法

### 使用 Swift Package Manager

```bash
# 克隆仓库
git clone https://github.com/weichzh/SetDefaultApp-V2
cd SetDefaultApp-V2
```

### 构建 .app 包

```bash
# 构建完整的 .app 包
./build_app.sh

# 运行应用程序
open '.build/release/默认应用程序管理器.app'
```

### 使用 Xcode

1. 使用 Xcode 打开 `Package.swift` 文件
2. 选择 "SetDefaultApp" scheme
3. 点击运行按钮或按 Cmd+R

## 使用方法

### 文件类型视图

1. **浏览文件类型** - 查看系统中所有已知的文件类型
2. **查看详细信息** - 每个文件类型显示：
   - 友好名称和 UTI 标识符
   - 支持的文件扩展名
   - 当前默认应用程序
   - 支持该类型的应用程序数量
3. **设置默认应用** - 点击"设置默认"选择新的默认应用程序
4. **搜索过滤** - 按名称、UTI 或扩展名快速查找文件类型

### 应用程序视图

1. **浏览应用程序** - 查看所有已安装的应用程序（包括系统应用）
2. **查看支持的文件类型** - 每个应用程序显示它声明支持的文件类型数量
3. **批量设置** - 点击"设为全部默认"将应用程序设为其支持的所有文件类型的默认程序
4. **详细管理** - 点击"详情"查看具体支持的文件类型：
   - ✨ **新功能**: 可以更改已经设置为默认的文件类型
   - 点击"更改"按钮选择其他应用程序
   - 支持搜索和过滤其他可用应用

## 技术特点

### 智能 Info.plist 解析

从每个应用程序的 `Info.plist` 文件中提取：

- **现代 UTI 支持** - `LSItemContentTypes` (Uniform Type Identifier)
- **传统格式兼容** - `CFBundleTypeOSTypes` 旧式类型标识符
- **扩展名推断** - `CFBundleTypeExtensions` 文件扩展名
- **角色识别** - `CFBundleTypeRole` 应用程序角色（编辑器/查看器等）
- **URL Schemes** - `CFBundleURLTypes` URL 协议支持
- **自定义类型** - 处理未标准化的文件类型声明

### 先进的文件类型发现

- **多层次解析**: 优先处理 UTI，回退到 OSType，最后从扩展名推断
- **角色优先级**: 编辑器应用优先于查看器应用
- **智能过滤**: 自动过滤过于通用或系统内部的类型
- **去重机制**: 避免重复处理相同的文件类型
- **兼容性**: 同时支持现代 UTType API 和传统 Core Services API

### 动态文件类型发现

应用程序会自动扫描以下位置的应用程序：

- `/Applications` - 用户安装的应用程序
- `/System/Applications` - 系统应用程序
- `/System/Applications/Utilities` - 系统工具
- `/Applications/Utilities` - 用户工具

## 发现的文件类型示例

应用程序可以发现各种文件类型，包括但不限于：

- **文档**: PDF, Word, Excel, PowerPoint, Pages, Numbers, Keynote
- **图像**: JPEG, PNG, GIF, TIFF, SVG, WebP, HEIF, RAW 格式
- **视频**: MP4, MOV, AVI, MKV, WebM, MPEG
- **音频**: MP3, AAC, FLAC, WAV, AIFF, OGG
- **压缩包**: ZIP, RAR, 7Z, TAR, GZIP
- **代码**: Swift, Python, JavaScript, HTML, CSS, JSON, XML
- **专业格式**: Photoshop, Illustrator, Sketch, Figma 等
- **URL Schemes**: HTTP, HTTPS, FTP, 自定义协议

## 界面预览

### 文件类型视图
- 列表显示所有文件类型
- 显示 UTI、扩展名、当前默认应用
- 搜索和过滤功能
- 一键设置默认应用

### 应用程序视图
- 显示所有已安装应用程序
- 每个应用的图标、名称、路径
- 支持的文件类型数量
- 批量设置和详细管理

### 应用程序详情（新功能）
- ✨ **更改默认设置**: 可以更改已经设置为默认的文件类型
- **智能应用选择器**: 显示其他可用应用程序
- **搜索功能**: 在替代应用中快速搜索
- **用户友好**: 清晰显示当前默认应用和可选替代应用

## 权限说明

此应用程序需要以下权限：

- **文件系统访问** - 读取应用程序文件夹以获取 Info.plist 信息
- **LaunchServices 访问** - 查询和设置默认应用程序关联

## 安全性

- 应用程序仅读取公开的应用程序信息
- 不会修改任何应用程序文件
- 只通过系统 API 修改文件关联设置
- 所有操作都可以通过系统设置逆转

## 性能优化

- 异步加载应用程序和文件类型数据
- 缓存应用程序信息避免重复扫描
- 智能过滤过于通用的文件类型
- 优化的搜索和排序算法

## 故障排除

### 应用程序无法设置默认关联

1. 确保目标应用程序支持该文件类型
2. 检查应用程序是否已正确安装
3. 尝试重启应用程序并刷新数据

### 权限错误

如果遇到权限问题，请确保：

1. 应用程序有访问应用程序文件夹的权限
2. 系统完整性保护 (SIP) 设置允许修改文件关联

### 加载缓慢

首次启动时需要扫描所有应用程序：

1. 扫描过程在后台进行，显示进度指示器
2. 后续启动会更快（除非安装了新应用）
3. 可以手动点击"刷新"重新扫描

### swift run 无法显示界面

确保你的终端支持图形应用程序启动，或使用：
```bash
# 构建 .app 包然后运行
./build_app.sh
open '.build/release/默认应用程序管理器.app'
```
