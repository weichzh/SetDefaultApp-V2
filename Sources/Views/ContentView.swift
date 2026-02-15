import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var launchServicesManager = LaunchServicesManager()
    @State private var selectedItem: SidebarItem? = .allFileTypes
    @State private var searchText = ""
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    // 拖拽相关状态
    @State private var droppedFileType: FileType?
    @State private var isTargeted = false

    enum SidebarItem: Hashable, Identifiable {
        case allFileTypes
        case allApplications
        case category(FileTypeCategory)
        
        var id: String {
            switch self {
            case .allFileTypes: return "allFileTypes"
            case .allApplications: return "allApplications"
            case .category(let category): return "category-\(category.rawValue)"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(selection: $selectedItem) {
                Section("概览") {
                    NavigationLink(value: SidebarItem.allFileTypes) {
                        Label("所有文件类型", systemImage: "doc.on.doc")
                    }
                    NavigationLink(value: SidebarItem.allApplications) {
                        Label("应用程序", systemImage: "app.dashed")
                    }
                }
                
                Section("分类浏览") {
                    ForEach(FileTypeCategory.allCases.filter { $0 != .all }) { category in
                        NavigationLink(value: SidebarItem.category(category)) {
                            Label(category.rawValue, systemImage: category.icon)
                        }
                    }
                }
            }
            .navigationTitle("SetDefaultApp")
            .listStyle(.sidebar)
        } detail: {
            ZStack {
                if launchServicesManager.isLoading {
                    VStack {
                        ProgressView("正在扫描...")
                        Text("首次加载可能需要几秒钟")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                } else {
                    switch selectedItem {
                    case .allFileTypes:
                        FileTypesView(
                            launchServicesManager: launchServicesManager,
                            category: nil,
                            searchText: searchText
                        )
                        .navigationTitle("所有文件类型")
                    case .allApplications:
                        ApplicationsView(
                            launchServicesManager: launchServicesManager,
                            searchText: searchText
                        )
                        .navigationTitle("应用程序")
                    case .category(let category):
                        FileTypesView(
                            launchServicesManager: launchServicesManager,
                            category: category,
                            searchText: searchText
                        )
                        .navigationTitle(category.rawValue)
                    case nil:
                        Text("请选择一个项目")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 拖拽提示覆盖层
                if isTargeted {
                    Color.black.opacity(0.1)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 64))
                            .foregroundColor(.accentColor)
                        Text("释放文件以更改默认应用")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(NSColor.windowBackgroundColor)))
                    .shadow(radius: 10)
                }
            }
            .searchable(text: $searchText, prompt: "搜索名称、扩展名或应用...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        launchServicesManager.loadApplicationsAndFileTypes()
                    }) {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                    .help("重新扫描应用程序")
                    .disabled(launchServicesManager.isLoading)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                guard let url = url else {
                    print("Drop failed: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                DispatchQueue.main.async {
                    if let fileType = launchServicesManager.resolveFileType(for: url) {
                        self.droppedFileType = fileType
                    }
                }
            }
            return true
        }
        .sheet(item: $droppedFileType) { fileType in
            AppSelectorView(
                fileType: fileType,
                launchServicesManager: launchServicesManager
            )
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
