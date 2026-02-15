import SwiftUI

struct ApplicationsView: View {
    @ObservedObject var launchServicesManager: LaunchServicesManager
    let searchText: String
    
    private var filteredApplications: [AppInfo] {
        if searchText.isEmpty {
            return launchServicesManager.applications
        } else {
            return launchServicesManager.applications.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        List(filteredApplications) { app in
            NavigationLink(destination: ApplicationDetailsView(app: app, launchServicesManager: launchServicesManager)) {
                ApplicationRow(
                    app: app,
                    launchServicesManager: launchServicesManager
                )
            }
        }
        .listStyle(.inset)
    }
}

struct ApplicationRow: View {
    let app: AppInfo
    @ObservedObject var launchServicesManager: LaunchServicesManager
    
    private var supportedFileTypes: [FileType] {
        return launchServicesManager.fileTypes.filter { fileType in
            fileType.availableApps.contains { $0.bundleIdentifier == app.bundleIdentifier }
        }
    }
    
    private var isDefaultForAny: Bool {
        return supportedFileTypes.contains { fileType in
            fileType.defaultApp?.bundleIdentifier == app.bundleIdentifier
        }
    }
    
    var body: some View {
        HStack {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name)
                    .font(.headline)
                
                Text(app.bundleIdentifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("支持 \(supportedFileTypes.count) 种文件类型")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if isDefaultForAny {
                    Text("已设为部分默认")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct ApplicationDetailsView: View {
    let app: AppInfo
    @ObservedObject var launchServicesManager: LaunchServicesManager
    @State private var showingAlternativeAppSelector = false
    @State private var selectedFileType: FileType?
    @State private var selectedTypeIDs: Set<UUID> = []
    @State private var isSelectionMode = false
    
    private var supportedFileTypes: [FileType] {
        return launchServicesManager.fileTypes.filter { fileType in
            fileType.availableApps.contains { $0.bundleIdentifier == app.bundleIdentifier }
        }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    private var defaultFileTypesCount: Int {
        return supportedFileTypes.filter { $0.defaultApp?.bundleIdentifier == app.bundleIdentifier }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 64, height: 64)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(app.bundleIdentifier)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                    
                    Text(app.path)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .textSelection(.enabled)
                    
                    HStack {
                        Text("支持 \(supportedFileTypes.count) 种文件类型")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        if defaultFileTypesCount > 0 {
                            Text("• 默认 \(defaultFileTypesCount) 种")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                
                Spacer()
                
                if !supportedFileTypes.isEmpty {
                    if isSelectionMode {
                        Button("取消选择") {
                            isSelectionMode = false
                            selectedTypeIDs.removeAll()
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Button("批量管理") {
                            isSelectionMode = true
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Batch Action Bar
            if isSelectionMode {
                HStack {
                    Button(action: {
                        if selectedTypeIDs.count == supportedFileTypes.count {
                            selectedTypeIDs.removeAll()
                        } else {
                            selectedTypeIDs = Set(supportedFileTypes.map { $0.id })
                        }
                    }) {
                        Text(selectedTypeIDs.count == supportedFileTypes.count ? "取消全选" : "全选")
                    }
                    
                    Spacer()
                    
                    Text("已选 \(selectedTypeIDs.count) 项")
                        .foregroundColor(.secondary)
                    
                    Button("设为默认") {
                        setBatchAsDefault()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedTypeIDs.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                Divider()
            }
            
            Divider()
            
            // List
            if supportedFileTypes.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("此应用程序未声明支持任何文件类型")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
            } else {
                List(supportedFileTypes) { fileType in
                    FileTypeRowInAppDetails(
                        fileType: fileType,
                        app: app,
                        isSelectionMode: isSelectionMode,
                        isSelected: selectedTypeIDs.contains(fileType.id),
                        onToggleSelection: {
                            if selectedTypeIDs.contains(fileType.id) {
                                selectedTypeIDs.remove(fileType.id)
                            } else {
                                selectedTypeIDs.insert(fileType.id)
                            }
                        },
                        onChange: {
                            selectedFileType = fileType
                            showingAlternativeAppSelector = true
                        },
                        onSetDefault: {
                            launchServicesManager.setDefaultApplication(app, for: fileType)
                        }
                    )
                }
            }
        }
        .navigationTitle(app.name)
        .sheet(isPresented: $showingAlternativeAppSelector) {
            if let fileType = selectedFileType {
                AlternativeAppSelectorView(
                    fileType: fileType,
                    currentApp: app,
                    launchServicesManager: launchServicesManager
                )
            }
        }
    }
    
    private func setBatchAsDefault() {
        let typesToSet = supportedFileTypes.filter { selectedTypeIDs.contains($0.id) }
        for fileType in typesToSet {
            launchServicesManager.setDefaultApplication(app, for: fileType)
        }
        isSelectionMode = false
        selectedTypeIDs.removeAll()
    }
}

struct FileTypeRowInAppDetails: View {
    let fileType: FileType
    let app: AppInfo
    let isSelectionMode: Bool
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onChange: () -> Void
    let onSetDefault: () -> Void
    
    var body: some View {
        HStack {
            if isSelectionMode {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title3)
                    .onTapGesture {
                        onToggleSelection()
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(fileType.name)
                    .font(.headline)
                
                HStack {
                    Text("UTI:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(fileType.uti)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                }
                
                if !fileType.extensions.isEmpty {
                    HStack {
                        Text("扩展名:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(fileType.extensions.map { ".\($0)" }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if let defaultApp = fileType.defaultApp {
                    HStack {
                        Text("当前默认:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if defaultApp.bundleIdentifier == app.bundleIdentifier {
                            Text("本应用")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        } else {
                            Text(defaultApp.name)
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if isSelectionMode {
                    onToggleSelection()
                }
            }
            
            Spacer()
            
            if !isSelectionMode {
                VStack(spacing: 4) {
                    if fileType.defaultApp?.bundleIdentifier == app.bundleIdentifier {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("当前默认")
                                .font(.caption)
                                .foregroundColor(.green)
                                .fontWeight(.medium)
                        }
                        
                        Button("更改") {
                            onChange()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        if let defaultApp = fileType.defaultApp {
                            VStack(spacing: 2) {
                                HStack {
                                    if let icon = defaultApp.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 16, height: 16)
                                    }
                                    Text(defaultApp.name)
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                        .lineLimit(1)
                                }
                                
                                Button("替换为本应用") {
                                    onSetDefault()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        } else {
                            VStack(spacing: 2) {
                                Text("无默认应用")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("设为默认") {
                                    onSetDefault()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
    }
}

struct AlternativeAppSelectorView: View {
    let fileType: FileType
    let currentApp: AppInfo
    @ObservedObject var launchServicesManager: LaunchServicesManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredApps: [AppInfo] {
        let apps = fileType.availableApps.filter { $0.bundleIdentifier != currentApp.bundleIdentifier }
        
        if searchText.isEmpty {
            return apps.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        } else {
            return apps.filter { app in
                app.name.localizedCaseInsensitiveContains(searchText) ||
                app.bundleIdentifier.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("更改默认应用程序")
                        .font(.headline)
                    Text("为 \(fileType.name) 选择新的默认应用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if !fileType.extensions.isEmpty {
                        Text(fileType.extensions.map { ".\($0)" }.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // 清除默认应用选项
            if fileType.defaultApp != nil {
                Button(action: {
                    launchServicesManager.clearDefaultApplication(for: fileType)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.red)
                        Text("无默认程序 (清除设置)")
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                
                Divider()
            }
            
            HStack {
                Text("当前默认:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let icon = currentApp.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                
                Text(currentApp.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索其他应用程序...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            
            if filteredApps.isEmpty {
                VStack {
                    Spacer()
                    if searchText.isEmpty {
                        VStack {
                            Image(systemName: "app.badge.questionmark")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            Text("没有其他可用的应用程序")
                                .font(.headline)
                                .padding(.top)
                            Text("只有 \(currentApp.name) 支持此文件类型")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("没有找到匹配的应用程序")
                    }
                    Spacer()
                }
                .foregroundColor(.secondary)
            } else {
                List(filteredApps) { app in
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 32, height: 32)
                        }
                        
                        VStack(alignment: .leading) {
                            Text(app.name)
                                .font(.headline)
                            
                            Text(app.bundleIdentifier)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("设为默认") {
                            launchServicesManager.setDefaultApplication(app, for: fileType)
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

#Preview {
    ApplicationsView(
        launchServicesManager: LaunchServicesManager(),
        searchText: ""
    )
}
