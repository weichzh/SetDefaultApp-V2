import Foundation

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
    
    static func == (lhs: FileType, rhs: FileType) -> Bool {
        return lhs.uti == rhs.uti
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uti)
    }
} 