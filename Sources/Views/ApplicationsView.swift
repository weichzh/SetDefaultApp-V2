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
            ApplicationRow(
                app: app,
                launchServicesManager: launchServicesManager
            )
        }
        .listStyle(.inset)
    }
}

struct ApplicationRow: View {
    let app: AppInfo
    @ObservedObject var launchServicesManager: LaunchServicesManager
    @State private var showingDetails = false
    
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
                
                Text("支持 \(supportedFileTypes.count) 种文件类型")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if isDefaultForAny {
                    Text("已设为部分文件类型的默认应用")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button("详情") {
                    showingDetails = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if !supportedFileTypes.isEmpty {
                    Button("设为全部默认") {
                        setAsDefaultForAll()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingDetails) {
            ApplicationDetailsView(
                app: app,
                launchServicesManager: launchServicesManager
            )
        }
    }
    
    private func setAsDefaultForAll() {
        for fileType in supportedFileTypes {
            launchServicesManager.setDefaultApplication(app, for: fileType)
        }
    }
}

struct ApplicationDetailsView: View {
    let app: AppInfo
    @ObservedObject var launchServicesManager: LaunchServicesManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAlternativeAppSelector = false
    @State private var selectedFileType: FileType?
    
    // 获取该应用程序支持的所有文件类型（不管当前默认应用是什么）
    private var supportedFileTypes: [FileType] {
        return launchServicesManager.fileTypes.filter { fileType in
            fileType.availableApps.contains { $0.bundleIdentifier == app.bundleIdentifier }
        }.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }
    
    // 统计该应用作为默认应用的文件类型数量
    private var defaultFileTypesCount: Int {
        return supportedFileTypes.filter { $0.defaultApp?.bundleIdentifier == app.bundleIdentifier }.count
    }
    
    var body: some View {
        VStack {
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
                    
                    Text(app.path)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
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
                
                Button("完成") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            VStack(alignment: .leading) {
                HStack {
                    Text("支持的文件类型")
                        .font(.headline)
                    
                    Spacer()
                    
                    if !supportedFileTypes.isEmpty {
                        Button("全部设为默认") {
                            setAsDefaultForAll()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.horizontal)
                
                if supportedFileTypes.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "doc.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("此应用程序未声明支持任何文件类型")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("这可能是应用程序配置问题或者它只支持特殊功能")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    List(supportedFileTypes) { fileType in
                        HStack {
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
                                
                                // 显示当前默认应用程序信息
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
                            
                            Spacer()
                            
                            VStack(spacing: 4) {
                                if fileType.defaultApp?.bundleIdentifier == app.bundleIdentifier {
                                    // 当前应用是默认应用
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("当前默认")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                            .fontWeight(.medium)
                                    }
                                    
                                    Button("更改") {
                                        selectedFileType = fileType
                                        showingAlternativeAppSelector = true
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                } else {
                                    // 其他应用是默认应用或无默认应用
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
                                                launchServicesManager.setDefaultApplication(app, for: fileType)
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                        }
                                    } else {
                                        // 无默认应用
                                        VStack(spacing: 2) {
                                            Text("无默认应用")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Button("设为默认") {
                                                launchServicesManager.setDefaultApplication(app, for: fileType)
                                            }
                                            .buttonStyle(.borderedProminent)
                                            .controlSize(.small)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .frame(width: 750, height: 650)
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
    
    private func setAsDefaultForAll() {
        for fileType in supportedFileTypes {
            launchServicesManager.setDefaultApplication(app, for: fileType)
        }
    }
}

// 添加一个专门的应用选择器组件
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
            // 标题栏
            HStack {
                VStack(alignment: .leading) {
                    Text("更改默认应用程序")
                        .font(.headline)
                    Text("为 \(fileType.name) 选择新的默认应用")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("取消") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            // 当前默认应用
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
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索其他应用程序...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            
            // 应用程序列表
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