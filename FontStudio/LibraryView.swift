import SwiftUI

/// 字体库：导入 / 预览 / 删除 / 查看详情
struct LibraryView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var showingPicker = false
    @State private var showAlert = false
    @State private var alertText = ""

    var body: some View {
        NavigationStack {
            List {
                if fontManager.fonts.isEmpty {
                    Text("还没有导入字体，点击右上角 ＋ 从文件添加")
                        .foregroundColor(.secondary)
                }
                ForEach(fontManager.fonts) { info in
                    NavigationLink(destination: FontDetailView(info: info)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ag 字体工坊 123")
                                .font(Font.custom(info.postScriptName, size: 22))
                            Text(info.displayName)
                                .font(.headline)
                            Text("\(info.fileName) · \(formattedSize(info.fileSize))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: delete)
            }
            .navigationTitle("字体库")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingPicker = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingPicker) {
                DocumentPicker(onPick: importPicked)
            }
            .alert("提示", isPresented: $showAlert, actions: {
                Button("好", role: .cancel) {}
            }, message: {
                Text(alertText)
            })
        }
    }

    private func importPicked(_ url: URL) {
        do {
            let info = try fontManager.importFont(from: url)
            alertText = "已导入「\(info.displayName)」"
        } catch {
            alertText = error.localizedDescription
        }
        showAlert = true
    }

    private func delete(at offsets: IndexSet) {
        for i in offsets {
            fontManager.delete(fontManager.fonts[i])
        }
    }

    private func formattedSize(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / 1024 / 1024)
    }
}

/// 单个字体详情
struct FontDetailView: View {
    let info: FontInfo

    var body: some View {
        List {
            Section("预览") {
                Text("字体工坊 Font Studio\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n0123456789")
                    .font(Font.custom(info.postScriptName, size: 26))
                    .padding(.vertical, 4)
            }
            Section("信息") {
                row("显示名称", info.fullName)
                row("家族", info.familyName)
                row("样式", info.styleName)
                row("PostScript", info.postScriptName)
                row("文件名", info.fileName)
            }
        }
        .navigationTitle(info.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value.isEmpty ? "-" : value)
        }
        .font(.callout)
    }
}
