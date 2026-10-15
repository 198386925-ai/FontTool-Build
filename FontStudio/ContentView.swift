import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PreviewView()
                .tabItem { Label("预览", systemImage: "textformat") }
            LibraryView()
                .tabItem { Label("字体库", systemImage: "folder") }
            PosterView()
                .tabItem { Label("海报", systemImage: "photo") }
            ToolboxView()
                .tabItem { Label("工具箱", systemImage: "wrench.and.screwdriver") }
            InstallView()
                .tabItem { Label("安装", systemImage: "square.and.arrow.down") }
        }
    }
}
