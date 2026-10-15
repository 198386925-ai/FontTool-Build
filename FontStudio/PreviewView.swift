import SwiftUI

/// 实时预览：输入文字、选字体、调大小（极简风）
struct PreviewView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var text = "字体工坊\nABCDEFGHIJKLM\nabcdefghijklm\n0123456789"
    @State private var fontSize: CGFloat = 32
    @State private var selectedPSName: String = "__system__"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 预览卡片
                    Text(text.isEmpty ? " " : text)
                        .font(previewFont(size: fontSize))
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
                        .padding(20)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)

                    // 控制卡片
                    VStack(spacing: 0) {
                        HStack {
                            Label("字体", systemImage: "textformat")
                                .foregroundColor(.primary)
                            Spacer()
                            Picker("字体", selection: $selectedPSName) {
                                Text("系统默认").tag("__system__")
                                ForEach(fontManager.fonts) { f in
                                    Text(f.displayName).tag(f.postScriptName)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        .padding()

                        Divider().padding(.leading, 16)

                        VStack(alignment: .leading, spacing: 8) {
                            Label("预览文字", systemImage: "pencil")
                                .foregroundColor(.primary)
                            TextEditor(text: $text)
                                .frame(height: 80)
                                .padding(8)
                                .background(Color(.systemGroupedBackground))
                                .cornerRadius(10)
                        }
                        .padding()

                        Divider().padding(.leading, 16)

                        HStack {
                            Label("大小", systemImage: "textformat.size")
                                .foregroundColor(.primary)
                            Slider(value: $fontSize, in: 12...120, step: 1)
                            Text("\(Int(fontSize))")
                                .monospacedDigit()
                                .frame(width: 36, alignment: .trailing)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("预览")
        }
    }

    private func previewFont(size: CGFloat) -> Font {
        if selectedPSName == "__system__" {
            return Font.system(size: size)
        }
        return Font.custom(selectedPSName, size: size)
    }
}
