import SwiftUI
import UIKit

/// 一条替换规则：把 find 换成 replace，并用指定字体渲染
struct ReplaceRule: Identifiable {
    let id = UUID()
    var find: String = ""
    var replace: String = ""
}

/// 字符替换：按规则替换文本中的字符，替换部分可用不同字体
struct ReplaceView: View {
    @EnvironmentObject var fontManager: FontManager

    @State private var input = "字体工坊 Font 123"
    @State private var rules: [ReplaceRule] = [ReplaceRule(find: "A", replace: "Ⓐ")]
    @State private var baseFontPSName = "__system__"
    @State private var replaceFontPSName = "__system__"
    @State private var shareURL: URL?
    @State private var showingShare = false
    @State private var showCopied = false

    let previewSize: CGFloat = 26

    var body: some View {
        NavigationStack {
            Form {
                Section("原文") {
                    TextEditor(text: $input).frame(height: 80)
                    Picker("基础字体", selection: $baseFontPSName) {
                        Text("系统").tag("__system__")
                        ForEach(fontManager.fonts) { f in Text(f.displayName).tag(f.postScriptName) }
                    }
                }

                Section("替换规则") {
                    ForEach($rules) { $rule in
                        HStack {
                            TextField("查找", text: $rule.find)
                                .textFieldStyle(.roundedBorder)
                            Text("→").foregroundColor(.secondary)
                            TextField("替换为", text: $rule.replace)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .onDelete { rules.remove(atOffsets: $0) }
                    Button("添加规则") { rules.append(ReplaceRule()) }
                    Picker("替换部分字体", selection: $replaceFontPSName) {
                        Text("跟随基础字体").tag("__system__")
                        ForEach(fontManager.fonts) { f in Text(f.displayName).tag(f.postScriptName) }
                    }
                }

                Section("效果预览") {
                    Text(AttributedString(buildAttributed()))
                        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
                }

                Section {
                    Button("复制结果文本") {
                        UIPasteboard.general.string = resultString()
                        showCopied = true
                    }
                    Button("导出为图片", action: exportImage)
                }
            }
            .navigationTitle("字符替换")
            .navigationBarTitleDisplayMode(.inline)
            .alert("已复制到剪贴板", isPresented: $showCopied) {
                Button("好", role: .cancel) {}
            }
            .sheet(isPresented: $showingShare) {
                if let u = shareURL { ShareSheet(items: [u]) }
            }
        }
    }

    // MARK: - 逻辑

    private func uiFont(_ psName: String, size: CGFloat) -> UIFont {
        psName == "__system__"
            ? UIFont.systemFont(ofSize: size)
            : (UIFont(name: psName, size: size) ?? UIFont.systemFont(ofSize: size))
    }

    /// 扫描原文，应用第一条命中的规则，返回富文本（替换部分用替换字体+蓝色）
    private func buildAttributed() -> NSAttributedString {
        let base = uiFont(baseFontPSName, size: previewSize)
        let rep = uiFont(replaceFontPSName == "__system__" ? baseFontPSName : replaceFontPSName,
                         size: previewSize)
        let mas = NSMutableAttributedString()
        var i = input.startIndex
        while i < input.endIndex {
            var matched = false
            for rule in rules where !rule.find.isEmpty {
                if input[i...].hasPrefix(rule.find) {
                    let seg = rule.replace.isEmpty ? rule.find : rule.replace
                    mas.append(NSAttributedString(string: seg, attributes: [
                        .font: rep,
                        .foregroundColor: UIColor.systemBlue,
                    ]))
                    i = input.index(i, offsetBy: rule.find.count)
                    matched = true
                    break
                }
            }
            if !matched {
                mas.append(NSAttributedString(string: String(input[i]),
                                              attributes: [.font: base]))
                i = input.index(after: i)
            }
        }
        return mas
    }

    private func resultString() -> String {
        var out = ""
        var i = input.startIndex
        while i < input.endIndex {
            var matched = false
            for rule in rules where !rule.find.isEmpty {
                if input[i...].hasPrefix(rule.find) {
                    out += rule.replace.isEmpty ? rule.find : rule.replace
                    i = input.index(i, offsetBy: rule.find.count)
                    matched = true
                    break
                }
            }
            if !matched {
                out += String(input[i])
                i = input.index(after: i)
            }
        }
        return out
    }

    private func exportImage() {
        let mas = buildAttributed()
        let maxW: CGFloat = 1000
        let rect = mas.boundingRect(
            with: CGSize(width: maxW, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        let size = CGSize(width: ceil(rect.width) + 48, height: ceil(rect.height) + 48)
        let img = UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            mas.draw(in: CGRect(x: 24, y: 24, width: maxW, height: ceil(rect.height) + 24))
        }
        if let data = img.pngData() {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("字体工坊-字符替换.png")
            try? data.write(to: url, options: .atomic)
            shareURL = url
            showingShare = true
        }
    }
}
