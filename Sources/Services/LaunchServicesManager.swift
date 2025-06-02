import Foundation
import CoreServices
import AppKit
import UniformTypeIdentifiers

class LaunchServicesManager: ObservableObject {
    @Published var fileTypes: [FileType] = []
    @Published var applications: [AppInfo] = []
    @Published var isLoading = false
    
    private var discoveredFileTypes: [String: FileType] = [:]
    
    init() {
        loadApplicationsAndFileTypes()
    }
    
    func loadApplicationsAndFileTypes() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.scanApplicationsAndBuildFileTypes()
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    private func scanApplicationsAndBuildFileTypes() {
        var apps: [AppInfo] = []
        var fileTypesDict: [String: FileType] = [:]
        var validApps: [AppInfo] = []
        
        // 扫描应用程序文件夹
        let applicationPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "/Applications/Utilities"
        ]
        
        for appPath in applicationPaths {
            let appURL = URL(fileURLWithPath: appPath)
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: appURL,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
                
                for url in contents {
                    if url.pathExtension == "app" {
                        if let appInfo = createAppInfo(from: url) {
                            apps.append(appInfo)
                            
                            // 从应用程序的 Info.plist 中提取文件类型
                            if extractFileTypes(from: url, appInfo: appInfo, into: &fileTypesDict) {
                                // 只有支持文件类型的应用才加入有效应用列表
                                validApps.append(appInfo)
                            }
                        }
                    }
                }
            } catch {
                print("Error scanning \(appPath): \(error)")
            }
        }
        
        // 更新当前默认应用程序
        for (_, fileType) in fileTypesDict {
            if let defaultApp = getDefaultApplication(for: fileType.uti) {
                fileTypesDict[fileType.uti]?.defaultApp = defaultApp
            }
        }
        
        // 更新 UI
        DispatchQueue.main.async {
            self.applications = validApps.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
            self.fileTypes = Array(fileTypesDict.values).sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }
    
    private func extractFileTypes(from appURL: URL, appInfo: AppInfo, into fileTypesDict: inout [String: FileType]) -> Bool {
        guard let bundle = Bundle(url: appURL) else { return false }
        
        // 读取 CFBundleDocumentTypes
        guard let documentTypes = bundle.infoDictionary?["CFBundleDocumentTypes"] as? [[String: Any]] else {
            return false
        }
        
        var appSupportedTypes: Set<String> = []
        
        for docType in documentTypes {
            var processedUTIs: Set<String> = []
            
            // 优先处理 LSItemContentTypes (UTI)
            if let contentTypes = docType["LSItemContentTypes"] as? [String] {
                for uti in contentTypes {
                    // 跳过folder类型，这不是真正的文件类型
                    if uti == "public.folder" { continue }
                    
                    if !processedUTIs.contains(uti) {
                        if processUTI(uti, docType: docType, appInfo: appInfo, into: &fileTypesDict) {
                            appSupportedTypes.insert(uti)
                            processedUTIs.insert(uti)
                        }
                    }
                }
            }
            
            // 处理旧式的 CFBundleTypeOSTypes
            if let osTypes = docType["CFBundleTypeOSTypes"] as? [String] {
                for osType in osTypes {
                    // 跳过通用的 OSType
                    if osType != "****" && osType != "TEXT" && osType != "utxt" && osType != "TUTX" {
                        if let uti = convertOSTypeToUTI(osType) {
                            if !processedUTIs.contains(uti) {
                                if processUTI(uti, docType: docType, appInfo: appInfo, into: &fileTypesDict) {
                                    appSupportedTypes.insert(uti)
                                    processedUTIs.insert(uti)
                                }
                            }
                        }
                    }
                }
            }
            
            // 从扩展名推断 UTI（如果前面没有明确的 UTI）
            if processedUTIs.isEmpty,
               let extensions = docType["CFBundleTypeExtensions"] as? [String] {
                for ext in extensions {
                    // 跳过空扩展名
                    if ext.isEmpty { continue }
                    
                    if let uti = getUTIForExtension(ext) {
                        if !processedUTIs.contains(uti) {
                            if processUTI(uti, docType: docType, appInfo: appInfo, into: &fileTypesDict) {
                                appSupportedTypes.insert(uti)
                                processedUTIs.insert(uti)
                            }
                        }
                    }
                }
            }
            
            // 处理 CFBundleTypeName 但没有 UTI 的情况（为Cursor这样的复杂应用）
            if processedUTIs.isEmpty,
               let typeName = docType["CFBundleTypeName"] as? String,
               let extensions = docType["CFBundleTypeExtensions"] as? [String],
               !extensions.isEmpty {
                // 创建一个基于类型名称的自定义标识符
                let customUTI = "custom.filetype." + typeName.lowercased()
                    .replacingOccurrences(of: " ", with: "-")
                    .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
                
                if processCustomFileType(customUTI, typeName: typeName, extensions: extensions, appInfo: appInfo, into: &fileTypesDict) {
                    appSupportedTypes.insert(customUTI)
                }
            }
        }
        
        // 处理 CFBundleURLTypes (URL Schemes) - 但不计入文件类型统计
        if let urlTypes = bundle.infoDictionary?["CFBundleURLTypes"] as? [[String: Any]] {
            processURLSchemes(urlTypes, appInfo: appInfo, into: &fileTypesDict)
        }
        
        // 返回该应用是否支持任何真正的文件类型
        return !appSupportedTypes.isEmpty
    }
    
    private func convertOSTypeToUTI(_ osType: String) -> String? {
        let osTypeMapping: [String: String] = [
            "PDF ": "com.adobe.pdf",
            "JPEG": "public.jpeg",
            "PNG ": "public.png",
            "GIF ": "com.compuserve.gif",
            "TIFF": "public.tiff",
            "MPEG": "public.mpeg",
            "MP4 ": "public.mpeg-4",
            "MOV ": "com.apple.quicktime-movie",
            "ZIP ": "public.zip-archive",
            "RTF ": "public.rtf"
        ]
        
        return osTypeMapping[osType]
    }
    
    private func getUTIForExtension(_ extension: String) -> String? {
        // 使用现代 UTType API（如果可用）
        if #available(macOS 11.0, *) {
            if let utType = UTType(filenameExtension: `extension`) {
                return utType.identifier
            }
        }
        
        // 回退到旧 API
        return UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            `extension` as CFString,
            nil
        )?.takeRetainedValue() as String?
    }
    
    private func processCustomFileType(_ uti: String, typeName: String, extensions: [String], appInfo: AppInfo, into fileTypesDict: inout [String: FileType]) -> Bool {
        // 过滤掉无效的扩展名
        let validExtensions = extensions.filter { !$0.isEmpty && $0 != "*" }
        if validExtensions.isEmpty { return false }
        
        // 获取或创建文件类型
        var fileType = fileTypesDict[uti] ?? FileType(
            uti: uti,
            name: typeName,
            extensions: validExtensions,
            defaultApp: nil,
            availableApps: []
        )
        
        // 添加应用程序到可用应用列表
        if !fileType.availableApps.contains(where: { $0.bundleIdentifier == appInfo.bundleIdentifier }) {
            fileType.availableApps.append(appInfo)
        }
        
        fileTypesDict[uti] = fileType
        return true
    }
    
    private func processURLSchemes(_ urlTypes: [[String: Any]], appInfo: AppInfo, into fileTypesDict: inout [String: FileType]) {
        for urlType in urlTypes {
            if let schemes = urlType["CFBundleURLSchemes"] as? [String] {
                for scheme in schemes {
                    let uti = "url.scheme." + scheme
                    let typeName = "\(scheme.uppercased()) URL"
                    
                    var fileType = fileTypesDict[uti] ?? FileType(
                        uti: uti,
                        name: typeName,
                        extensions: [], // URL schemes 没有文件扩展名
                        defaultApp: nil,
                        availableApps: []
                    )
                    
                    if !fileType.availableApps.contains(where: { $0.bundleIdentifier == appInfo.bundleIdentifier }) {
                        fileType.availableApps.append(appInfo)
                    }
                    
                    fileTypesDict[uti] = fileType
                }
            }
        }
    }
    
    private func processUTI(_ uti: String, docType: [String: Any], appInfo: AppInfo, into fileTypesDict: inout [String: FileType]) -> Bool {
        // 跳过太通用的类型
        let skipTypes = [
            "public.data", "public.content", "public.item", "public.database",
            "public.composite-content", "public.text", "com.apple.package",
            "public.folder", "public.directory"  // 添加folder相关类型
        ]
        if skipTypes.contains(uti) { return false }
        
        // 跳过系统内部类型
        if uti.hasPrefix("dyn.") || uti.hasPrefix("com.apple.internal") { return false }
        
        // 获取应用程序声明的角色
        let role = docType["CFBundleTypeRole"] as? String ?? "Editor"
        
        // 只处理编辑器和查看器角色
        guard ["Editor", "Viewer", "Shell", "QLGenerator"].contains(role) else { return false }
        
        // 获取或创建文件类型
        var fileType = fileTypesDict[uti] ?? FileType(
            uti: uti,
            name: getUTIDescription(uti, docType: docType),
            extensions: getUTIExtensions(uti, docType: docType),
            defaultApp: nil,
            availableApps: []
        )
        
        // 添加应用程序到可用应用列表（考虑角色优先级）
        if !fileType.availableApps.contains(where: { $0.bundleIdentifier == appInfo.bundleIdentifier }) {
            // 编辑器优先于查看器
            if role == "Editor" {
                fileType.availableApps.insert(appInfo, at: 0)
            } else {
                fileType.availableApps.append(appInfo)
            }
        }
        
        fileTypesDict[uti] = fileType
        return true
    }
    
    private func getUTIDescription(_ uti: String, docType: [String: Any]) -> String {
        // 首先尝试应用程序声明的类型名称
        if let bundleTypeName = docType["CFBundleTypeName"] as? String,
           !bundleTypeName.isEmpty && bundleTypeName != "Document" {
            return bundleTypeName
        }
        
        // 尝试获取系统提供的描述
        if #available(macOS 11.0, *) {
            if let utType = UTType(uti) {
                return utType.localizedDescription ?? utType.preferredFilenameExtension?.uppercased() ?? uti
            }
        }
        
        // 回退到旧 API
        if let description = UTTypeCopyDescription(uti as CFString)?.takeRetainedValue() as String? {
            return description
        }
        
        // 自定义描述映射
        let descriptions: [String: String] = [
            "public.plain-text": "纯文本文档",
            "public.rtf": "RTF 富文本文档",
            "com.adobe.pdf": "PDF 文档",
            "public.html": "HTML 网页",
            "public.xml": "XML 文档",
            "public.jpeg": "JPEG 图像",
            "public.png": "PNG 图像",
            "public.tiff": "TIFF 图像",
            "com.compuserve.gif": "GIF 图像",
            "public.svg-image": "SVG 矢量图",
            "public.mpeg": "MPEG 视频",
            "public.mpeg-4": "MP4 视频",
            "public.avi": "AVI 视频",
            "com.apple.quicktime-movie": "QuickTime 视频",
            "public.mp3": "MP3 音频",
            "public.aac-audio": "AAC 音频",
            "com.microsoft.waveform-audio": "WAV 音频",
            "public.zip-archive": "ZIP 压缩包",
            "public.tar-archive": "TAR 压缩包",
            "org.gnu.gnu-zip-archive": "GZIP 压缩包",
            "com.microsoft.word.doc": "Word 文档",
            "org.openxmlformats.wordprocessingml.document": "Word 文档",
            "com.microsoft.excel.xls": "Excel 表格",
            "org.openxmlformats.spreadsheetml.sheet": "Excel 表格",
            "com.microsoft.powerpoint.ppt": "PowerPoint 演示文稿",
            "org.openxmlformats.presentationml.presentation": "PowerPoint 演示文稿"
        ]
        
        if let customDescription = descriptions[uti] {
            return customDescription
        }
        
        // 从 UTI 生成友好名称
        let components = uti.components(separatedBy: ".")
        if let lastComponent = components.last {
            return lastComponent.capitalized + " 文件"
        }
        
        return uti
    }
    
    private func getUTIExtensions(_ uti: String, docType: [String: Any]) -> [String] {
        var extensions: Set<String> = []
        
        // 首先从应用程序声明的扩展名获取
        if let bundleExtensions = docType["CFBundleTypeExtensions"] as? [String] {
            extensions.formUnion(bundleExtensions.filter { !$0.isEmpty })
        }
        
        // 然后从系统获取扩展名
        if #available(macOS 11.0, *) {
            if let utType = UTType(uti) {
                if let preferredExt = utType.preferredFilenameExtension {
                    extensions.insert(preferredExt)
                }
                extensions.formUnion(utType.tags[.filenameExtension] ?? [])
            }
        } else {
            // 回退到旧 API
            if let cfExtensions = UTTypeCopyAllTagsWithClass(uti as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue() as? [String] {
                extensions.formUnion(cfExtensions.filter { !$0.isEmpty })
            }
        }
        
        // 常见扩展名映射作为最后的回退
        let extensionMappings: [String: [String]] = [
            "public.plain-text": ["txt", "text"],
            "public.rtf": ["rtf"],
            "com.adobe.pdf": ["pdf"],
            "public.html": ["html", "htm"],
            "public.xml": ["xml"],
            "public.jpeg": ["jpg", "jpeg"],
            "public.png": ["png"],
            "public.tiff": ["tiff", "tif"],
            "com.compuserve.gif": ["gif"],
            "public.svg-image": ["svg"],
            "public.mpeg": ["mpeg", "mpg"],
            "public.mpeg-4": ["mp4", "m4v"],
            "public.avi": ["avi"],
            "com.apple.quicktime-movie": ["mov", "qt"],
            "public.mp3": ["mp3"],
            "public.aac-audio": ["aac", "m4a"],
            "com.microsoft.waveform-audio": ["wav"],
            "public.zip-archive": ["zip"],
            "public.tar-archive": ["tar"],
            "org.gnu.gnu-zip-archive": ["gz", "gzip"],
            "com.microsoft.word.doc": ["doc"],
            "org.openxmlformats.wordprocessingml.document": ["docx"],
            "com.microsoft.excel.xls": ["xls"],
            "org.openxmlformats.spreadsheetml.sheet": ["xlsx"],
            "com.microsoft.powerpoint.ppt": ["ppt"],
            "org.openxmlformats.presentationml.presentation": ["pptx"]
        ]
        
        if extensions.isEmpty, let mappedExtensions = extensionMappings[uti] {
            extensions.formUnion(mappedExtensions)
        }
        
        return Array(extensions).sorted()
    }
    
    private func createAppInfo(from url: URL) -> AppInfo? {
        guard let bundle = Bundle(url: url) else { return nil }
        guard let bundleIdentifier = bundle.bundleIdentifier else { return nil }
        guard let name = bundle.infoDictionary?["CFBundleName"] as? String ??
                bundle.infoDictionary?["CFBundleDisplayName"] as? String else { return nil }
        
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        
        // 获取支持的文件类型 UTI
        var supportedTypes: [String] = []
        if let documentTypes = bundle.infoDictionary?["CFBundleDocumentTypes"] as? [[String: Any]] {
            for docType in documentTypes {
                if let utis = docType["LSItemContentTypes"] as? [String] {
                    supportedTypes.append(contentsOf: utis)
                }
            }
        }
        
        return AppInfo(
            bundleIdentifier: bundleIdentifier,
            name: name,
            path: url.path,
            icon: icon,
            supportedTypes: Array(Set(supportedTypes)) // 去重
        )
    }
    
    private func getDefaultApplication(for uti: String) -> AppInfo? {
        guard let bundleIdentifier = LSCopyDefaultRoleHandlerForContentType(
            uti as CFString,
            .all
        )?.takeRetainedValue() as String? else { return nil }
        
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            return createAppInfo(from: url)
        }
        
        return nil
    }
    
    func setDefaultApplication(_ app: AppInfo, for fileType: FileType) {
        let status = LSSetDefaultRoleHandlerForContentType(
            fileType.uti as CFString,
            .all,
            app.bundleIdentifier as CFString
        )
        
        if status == noErr {
            // 更新本地数据
            if let index = fileTypes.firstIndex(where: { $0.uti == fileType.uti }) {
                fileTypes[index].defaultApp = app
            }
        } else {
            print("Failed to set default application for \(fileType.uti): \(status)")
        }
    }
    
    func refreshFileType(_ fileType: FileType) {
        if let index = fileTypes.firstIndex(where: { $0.uti == fileType.uti }) {
            let defaultApp = getDefaultApplication(for: fileType.uti)
            fileTypes[index].defaultApp = defaultApp
        }
    }
    
    // 便捷方法：重新加载所有数据
    func loadFileTypes() {
        loadApplicationsAndFileTypes()
    }
    
    func loadApplications() {
        loadApplicationsAndFileTypes()
    }
} 