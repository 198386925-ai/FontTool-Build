import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            PreviewView()
                .tabItem { Label("预览", systemImage: "textformat") }
            LibraryView()
                .tabItem { Label("字体库", systemImage: "folder") }
            SystemFontsView()
                .tabItem { Label("系统字体", systemImage: "character.book.closed") }
            InstallView()
                .tabItem { Label("安装", systemImage: "square.and.arrow.down") }
        }
    }
}
