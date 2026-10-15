import SwiftUI

@main
struct FontStudioApp: App {
    @StateObject private var fontManager = FontManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(fontManager)
        }
    }
}
