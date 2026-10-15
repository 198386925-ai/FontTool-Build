import SwiftUI

/// 实时预览：输入文字、选字体、调大小
struct PreviewView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var text = "字体工坊\nABCDEFGHIJKLM\nabcdefghijklm\n0123456789"
    @State private var fontSize: CGFloat = 32
    @State private var selectedPSName: String = "__system__"

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                TextEditor(text: $text)
                    .frame(height: 110)
                    .padding(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                Picker("字体", selection: $selectedPSName) {
                    Text("系统默认").tag("__system__")
                    ForEach(fontManager.fonts) { f in
                        Text(f.displayName).tag(f.postScriptName)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                HStack {
                    Text("大小")
                    Slider(value: $fontSize, in: 12...120, step: 1)
                    Text("\(Int(fontSize))").frame(width: 36, alignment: .trailing)
                }
                .padding(.horizontal)

                ScrollView {
                    Text(text.isEmpty ? " " : text)
                        .font(previewFont(size: fontSize))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
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
