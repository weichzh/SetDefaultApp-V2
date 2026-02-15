import Foundation
import UniformTypeIdentifiers

enum FileTypeCategory: String, CaseIterable, Identifiable {
    case all = "所有类型"
    case image = "图像"
    case video = "视频"
    case audio = "音频"
    case document = "文档"
    case archive = "压缩包"
    case code = "代码"
    case system = "系统"
    case other = "其他"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .image: return "photo"
        case .video: return "film"
        case .audio: return "music.note"
        case .document: return "doc.text"
        case .archive: return "archivebox"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .system: return "gear"
        case .other: return "questionmark.folder"
        }
    }
}

struct FileType: Identifiable, Hashable, Equatable {
    let id = UUID()
    let uti: String
    let name: String
    let extensions: [String]
    var defaultApp: AppInfo?
    var availableApps: [AppInfo]
    
    init(uti: String, name: String, extensions: [String], defaultApp: AppInfo? = nil, availableApps: [AppInfo] = []) {
        self.uti = uti
        self.name = name
        self.extensions = extensions
        self.defaultApp = defaultApp
        self.availableApps = availableApps
    }
    
    var category: FileTypeCategory {
        if #available(macOS 11.0, *) {
            if let type = UTType(uti) {
                if type.conforms(to: .image) { return .image }
                if type.conforms(to: .audiovisualContent) {
                    if type.conforms(to: .audio) { return .audio }
                    if type.conforms(to: .movie) || type.conforms(to: .video) { return .video }
                }
                if type.conforms(to: .text) || type.conforms(to: .pdf) || type.conforms(to: .presentation) || type.conforms(to: .spreadsheet) {
                    if type.conforms(to: .sourceCode) { return .code }
                    return .document
                }
                if type.conforms(to: .archive) { return .archive }
                if type.conforms(to: .systemPreferencesPane) || type.conforms(to: .application) || type.conforms(to: .executable) { return .system }
            }
        }
        
        // Fallback for older systems or custom types
        if uti.contains("image") || uti.contains("jpeg") || uti.contains("png") { return .image }
        if uti.contains("video") || uti.contains("movie") || uti.contains("mpeg") { return .video }
        if uti.contains("audio") || uti.contains("music") || uti.contains("sound") { return .audio }
        if uti.contains("text") || uti.contains("document") || uti.contains("pdf") || uti.contains("doc") { return .document }
        if uti.contains("zip") || uti.contains("archive") || uti.contains("tar") || uti.contains("compressed") { return .archive }
        if uti.contains("code") || uti.contains("source") || uti.contains("script") { return .code }
        
        return .other
    }
    
    static func == (lhs: FileType, rhs: FileType) -> Bool {
        return lhs.uti == rhs.uti
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uti)
    }
} 