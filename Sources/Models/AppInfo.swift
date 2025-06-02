import Foundation
import AppKit

struct AppInfo: Identifiable, Hashable, Equatable {
    let id = UUID()
    let bundleIdentifier: String
    let name: String
    let path: String
    let icon: NSImage?
    let supportedTypes: [String]
    
    init(bundleIdentifier: String, name: String, path: String, icon: NSImage? = nil, supportedTypes: [String] = []) {
        self.bundleIdentifier = bundleIdentifier
        self.name = name
        self.path = path
        self.icon = icon
        self.supportedTypes = supportedTypes
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.bundleIdentifier == rhs.bundleIdentifier
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleIdentifier)
    }
} 