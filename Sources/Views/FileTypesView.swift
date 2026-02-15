import SwiftUI

struct FileTypesView: View {
    @ObservedObject var launchServicesManager: LaunchServicesManager
    var category: FileTypeCategory? = nil
    let searchText: String
    
    private var filteredFileTypes: [FileType] {
        let types = launchServicesManager.fileTypes.filter { fileType in
            if let category = category, category != .all {
                return fileType.category == category
            }
            return true
        }
        
        if searchText.isEmpty {
            return types
        } else {
            return types.filter { fileType in
                fileType.name.localizedCaseInsensitiveContains(searchText) ||
                fileType.uti.localizedCaseInsensitiveContains(searchText) ||
                fileType.extensions.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
                (fileType.defaultApp?.name.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack {
            if filteredFileTypes.isEmpty && !searchText.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("未找到匹配的文件类型")
                        .font(.headline)
                        .padding(.top)
                    Text("尝试搜索其他关键词")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if filteredFileTypes.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "doc.questionmark")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("暂无文件类型")
                        .font(.headline)
                        .padding(.top)
                    Spacer()
                }
            } else {
                List(filteredFileTypes) { fileType in
                    FileTypeRow(
                        fileType: fileType,
                        launchServicesManager: launchServicesManager
                    )
                }
                .listStyle(.inset)
            }
        }
    }
}

struct FileTypeRow: View {
    let fileType: FileType
    @ObservedObject var launchServicesManager: LaunchServicesManager
    @State private var showingAppSelector = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
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
                
                HStack {
                    Text("可用应用:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(fileType.availableApps.count) 个")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                if let defaultApp = fileType.defaultApp {
                    HStack {
                        if let icon = defaultApp.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 20, height: 20)
                        }
                        
                        VStack(alignment: .trailing) {
                            Text(defaultApp.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("默认应用")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                } else {
                    VStack(alignment: .trailing) {
                        Text("无默认应用")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("未设置")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                Button("设置默认") {
                    showingAppSelector = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(fileType.availableApps.isEmpty)
            }
        }
        .padding(.vertical, 6)
        .sheet(isPresented: $showingAppSelector) {
            AppSelectorView(
                fileType: fileType,
                launchServicesManager: launchServicesManager
            )
        }
    }
}

struct AppSelectorView: View {
    let fileType: FileType
    @ObservedObject var launchServicesManager: LaunchServicesManager
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    private var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return fileType.availableApps.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        } else {
            return fileType.availableApps.filter { app in
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
                    Text("选择默认应用程序")
                        .font(.headline)
                    Text(fileType.name)
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
            
            // 搜索框
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索应用程序...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            
            // 应用程序列表
            if filteredApps.isEmpty {
                VStack {
                    Spacer()
                    if searchText.isEmpty {
                        Text("没有找到支持此文件类型的应用程序")
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
                            
                            Text(app.path)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        if fileType.defaultApp?.bundleIdentifier == app.bundleIdentifier {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("当前默认")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        } else {
                            Button("设为默认") {
                                launchServicesManager.setDefaultApplication(app, for: fileType)
                                dismiss()
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .frame(width: 600, height: 500)
    }
}

#Preview {
    FileTypesView(
        launchServicesManager: LaunchServicesManager(),
        category: nil,
        searchText: ""
    )
} 