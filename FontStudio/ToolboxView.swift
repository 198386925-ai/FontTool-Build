import SwiftUI

/// 工具箱：干净列表入口（极简风）
struct ToolboxView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    toolRow(title: "字体转换",
                            subtitle: "ttf / otf 与 woff 互转",
                            icon: "arrow.left.arrow.right",
                            color: .blue) {
                        ConvertView()
                    }
                    toolRow(title: "字符替换",
                            subtitle: "按规则替换字符，可指定字体",
                            icon: "textformat.abc",
                            color: .orange) {
                        ReplaceView()
                    }
                    toolRow(title: "字体调整",
                            subtitle: "大小 / 粗细 / 间距 / 颜色，含草稿箱",
                            icon: "slider.horizontal.3",
                            color: .purple) {
                        AdjustView()
                    }
                }

                Section {
                    toolRow(title: "偏好设置",
                            subtitle: "默认预览文本、默认背景色",
                            icon: "gearshape",
                            color: .gray) {
                        PreferencesView()
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("工具箱")
        }
    }

    private func toolRow<Destination: View>(
        title: String, subtitle: String, icon: String, color: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(color)
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
