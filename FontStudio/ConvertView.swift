import SwiftUI
import UniformTypeIdentifiers

/// 字体格式转换：ttf / otf → woff，woff → ttf
struct ConvertView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var direction = 0 // 0: 字体 → WOFF，1: WOFF → 字体
    @State private var useLibrary = true
    @State private var selectedFont: FontInfo?
    @State private var pickedFile: URL?
    @State private var showingPicker = false
    @State private var resultURL: URL?
    @State private var showingShare = false
    @State private var message = ""
    @State private var showMessage = false

    var body: some View {
        Form {
            Section("转换方向") {
                Picker("", selection: $direction) {
                    Text("字体 → WOFF").tag(0)
                    Text("WOFF → 字体").tag(1)
                }
                .pickerStyle(.segmented)
                Text(direction == 0
                     ? "把 ttf / otf 打包成网页字体 woff（体积更小，适合网页使用）"
                     : "把 woff 解包还原成 ttf")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("源文件") {
                Toggle("从字体库选择", isOn: $useLibrary)
                if useLibrary {
                    if fontManager.fonts.isEmpty {
                        Text("字体库为空，请先去「字体库」导入").foregroundColor(.secondary)
                    } else {
                        Picker("字体", selection: $selectedFont) {
                            ForEach(fontManager.fonts) { f in
                                Text(f.displayName).tag(f as FontInfo?)
                            }
                        }
                    }
                } else {
                    Button(pickedFile?.lastPathComponent ?? "从文件选择") {
                        showingPicker = true
                    }
                }
            }

            Section {
                Button("开始转换", action: convert)
            }
        }
        .navigationTitle("字体转换")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedFont == nil { selectedFont = fontManager.fonts.first }
        }
        .sheet(isPresented: $showingPicker) {
            DocumentPicker(
                types: [.font, UTType(filenameExtension: "woff")].compactMap { $0 },
                onPick: { pickedFile = $0 }
            )
        }
        .sheet(isPresented: $showingShare) {
            if let u = resultURL { ShareSheet(items: [u]) }
        }
        .alert("提示", isPresented: $showMessage, actions: {
            Button("好", role: .cancel) {}
        }, message: {
            Text(message)
        })
    }

    private func convert() {
        do {
            let src: URL
            if useLibrary {
                guard let f = selectedFont else {
                    message = "请先选择字体"; showMessage = true; return
                }
                src = fontManager.fileURL(for: f)
            } else {
                guard let u = pickedFile else {
                    message = "请先选择文件"; showMessage = true; return
                }
                src = u
            }
            let ext = direction == 0 ? "woff" : "ttf"
            let out = try FontConverter.convertFile(inputURL: src, toExtension: ext)
            let before = (try? src.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            let after = (try? out.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            message = "转换成功：\(formatSize(before)) → \(formatSize(after))"
            resultURL = out
            showMessage = true
            showingShare = true
        } catch {
            message = error.localizedDescription
            showMessage = true
        }
    }

    private func formatSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / 1024 / 1024)
    }
}
