import SwiftUI

/// 字体库：导入 / 预览 / 删除 / 查看详情（极简风）
struct LibraryView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var showingPicker = false
    @State private var showAlert = false
    @State private var alertText = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(fontManager.fonts) { info in
                    NavigationLink(destination: FontDetailView(info: info)) {
                        HStack(spacing: 14) {
                            Text("Ag")
                                .font(Font.custom(info.postScriptName, size: 32))
                                .frame(width: 58, height: 58)
                                .background(Color.accentColor.opacity(0.12))
                                .cornerRadius(14)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(info.displayName)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text("\(info.fileName) · \(formattedSize(info.fileSize))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }
                .onDelete(perform: delete)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("字体库")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingPicker = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .overlay {
                if fontManager.fonts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "folder")
                            .font(.system(size: 52))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text("还没有导入字体")
                            .font(.headline)
                        Text("点击右上角 ＋ 从文件添加")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
            Section {
                Text("字体工坊 Font Studio\nABCDEFGHIJKLMNOPQRSTUVWXYZ\nabcdefghijklmnopqrstuvwxyz\n0123456789")
                    .font(Font.custom(info.postScriptName, size: 26))
                    .padding(.vertical, 8)
            } header: {
                Text("预览")
            }

            Section {
                row("显示名称", info.fullName)
                row("家族", info.familyName)
                row("样式", info.styleName)
                row("PostScript", info.postScriptName)
                row("文件名", info.fileName)
            } header: {
                Text("信息")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(info.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.secondary)
            Spacer()
            Text(value.isEmpty ? "-" : value)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }
}
