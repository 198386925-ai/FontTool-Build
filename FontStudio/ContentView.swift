import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PreviewView()
                .tabItem { Label("预览", systemImage: "textformat") }
            LibraryView()
                .tabItem { Label("字体库", systemImage: "folder") }
            InstallView()
                .tabItem { Label("安装", systemImage: "square.and.arrow.down") }
        }
    }
}
