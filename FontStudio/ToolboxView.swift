import SwiftUI

/// 工具箱：卡片式工具入口（极简风）
struct ToolboxView: View {
    private let columns = [GridItem(.flexible(), spacing: 16),
                           GridItem(.flexible(), spacing: 16)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    toolCard(title: "字体转换",
                             subtitle: "ttf / otf 与 woff 互转",
                             icon: "arrow.left.arrow.right",
                             color: .blue) {
                        ConvertView()
                    }
                    toolCard(title: "字符替换",
                             subtitle: "按规则替换字符，可指定字体",
                             icon: "textformat.abc",
                             color: .orange) {
                        ReplaceView()
                    }
                    toolCard(title: "字体调整",
                             subtitle: "大小 / 粗细 / 间距 / 颜色，含草稿箱",
                             icon: "slider.horizontal.3",
                             color: .purple) {
                        AdjustView()
                    }
                    toolCard(title: "偏好设置",
                             subtitle: "默认预览文本、默认背景色",
                             icon: "gearshape",
                             color: .gray) {
                        PreferencesView()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("工具箱")
        }
    }

    private func toolCard<Destination: View>(
        title: String, subtitle: String, icon: String, color: Color,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink(destination: destination()) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 46, height: 46)
                    .background(color)
                    .cornerRadius(13)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 140, alignment: .leading)
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}
