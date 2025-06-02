import SwiftUI

@main
struct SetDefaultAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            // 添加菜单命令
            CommandGroup(after: .appInfo) {
                Button("刷新数据") {
                    // 这个会被ContentView中的刷新功能处理
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }
    }
} 