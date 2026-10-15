import Foundation

/// 偏好设置：默认预览文本 / 默认背景色
struct AppPreferences: Codable, Equatable {
    var defaultPreviewText: String = "字体工坊字体预览\n1234567890\nABCDEFGHIJKLMNOPQRSTUVWXYZ"
    var defaultBgHex: String = "#FFFFFF"
}

final class PreferencesStore: ObservableObject {
    static let shared = PreferencesStore()

    @Published var prefs: AppPreferences {
        didSet { save() }
    }

    private let key = "FontStudio.preferences.v1"

    private init() {
        if let d = UserDefaults.standard.data(forKey: key),
           let p = try? JSONDecoder().decode(AppPreferences.self, from: d) {
            prefs = p
        } else {
            prefs = AppPreferences()
        }
    }

    private func save() {
        if let d = try? JSONEncoder().encode(prefs) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }
}
