import SwiftUI

struct ContentView: View {
    @StateObject private var launchServicesManager = LaunchServicesManager()
    @State private var selectedTab = 0
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            VStack {
                HStack {
                    Text("默认应用程序管理器")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if launchServicesManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    
                    Button("刷新") {
                        refresh()
                    }
                    .buttonStyle(.bordered)
                    .disabled(launchServicesManager.isLoading)
                }
                .padding()
                
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("搜索文件类型或应用程序...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .disabled(launchServicesManager.isLoading)
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            // 标签页选择器
            Picker("视图", selection: $selectedTab) {
                Text("文件类型 (\(launchServicesManager.fileTypes.count))").tag(0)
                Text("应用程序 (\(launchServicesManager.applications.count))").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .disabled(launchServicesManager.isLoading)
            
            // 内容区域
            Group {
                if launchServicesManager.isLoading {
                    VStack {
                        Spacer()
                        ProgressView("正在扫描应用程序和文件类型...")
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("这可能需要几秒钟时间...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                        Spacer()
                    }
                } else if selectedTab == 0 {
                    FileTypesView(
                        launchServicesManager: launchServicesManager,
                        searchText: searchText
                    )
                } else {
                    ApplicationsView(
                        launchServicesManager: launchServicesManager,
                        searchText: searchText
                    )
                }
            }
        }
    }
    
    private func refresh() {
        launchServicesManager.loadApplicationsAndFileTypes()
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 700)
} 