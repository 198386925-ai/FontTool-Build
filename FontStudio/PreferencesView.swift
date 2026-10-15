import SwiftUI
import UIKit

/// 偏好设置
struct PreferencesView: View {
    @ObservedObject var store: PreferencesStore = .shared

    var body: some View {
        NavigationStack {
            Form {
                Section("预览") {
                    Text("默认预览文本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextEditor(text: $store.prefs.defaultPreviewText)
                        .frame(height: 110)
                }
                Section("颜色") {
                    ColorPicker("默认背景色", selection: Binding(
                        get: { Color(UIColor(hex: store.prefs.defaultBgHex) ?? .white) },
                        set: { store.prefs.defaultBgHex = UIColor($0).hexString }
                    ))
                }
                Section {
                    Text("设置保存在本机，调整界面新建时会自动套用。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("偏好设置")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
