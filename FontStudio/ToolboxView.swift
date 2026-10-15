import SwiftUI

/// 工具箱：字体转换 / 字符替换
struct ToolboxView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(destination: ConvertView()) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("字体转换")
                            Text("ttf / otf 与 woff 互转")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                }
                NavigationLink(destination: ReplaceView()) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("字符替换")
                            Text("按规则替换字符，可指定替换字体")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "textformat.abc")
                    }
                }
                NavigationLink(destination: AdjustView()) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("字体调整")
                            Text("大小 / 粗细 / 间距 / 基线 / 颜色，含草稿箱")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                NavigationLink(destination: PreferencesView()) {
                    Label {
                        VStack(alignment: .leading) {
                            Text("偏好设置")
                            Text("默认预览文本、默认背景色")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .navigationTitle("工具箱")
        }
    }
}
