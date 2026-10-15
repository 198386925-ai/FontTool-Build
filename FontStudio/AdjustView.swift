import SwiftUI
import UIKit

/// 百分比滑杆：右侧数值可点击直接输入
struct PctSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = -100...100
    var onCommit: () -> Void = {}
    @State private var typing = false
    @State private var text = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                if typing {
                    TextField("", text: $text, onCommit: commitTyping)
                        .keyboardType(.numbersAndPunctuation)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 64)
                        .textFieldStyle(.roundedBorder)
                    Text("%").foregroundColor(.secondary)
                } else {
                    Text(String(format: "%+.0f%%", value))
                        .foregroundColor(.secondary)
                        .onTapGesture {
                            text = String(format: "%.0f", value)
                            typing = true
                        }
                }
            }
            .font(.subheadline)
            Slider(value: $value, in: range, step: 1) { editing in
                if !editing { onCommit() }
            }
        }
        .padding(.vertical, 2)
    }

    private func commitTyping() {
        if let v = Double(text.trimmingCharacters(in: .whitespaces)) {
            value = min(max(v, range.lowerBound), range.upperBound)
            onCommit()
        }
        typing = false
    }
}

/// 字体调整（渲染级）：大小 / 粗细 / 字间距 / 行间距 / 上浮下沉 / 颜色
struct AdjustView: View {
    @EnvironmentObject var fontManager: FontManager
    @ObservedObject var prefsStore: PreferencesStore = .shared
    @StateObject private var draftStore = DraftStore()

    @State private var fontPSName: String = "__system__"
    @State private var previewText: String = ""
    @State private var params = AdjustParams.default
    @State private var tab = 0 // 0=调整 1=颜色

    @State private var history: [AdjustParams] = []
    @State private var historyIndex: Int = -1

    @State private var showDrafts = false
    @State private var showSaveDraft = false
    @State private var draftName = ""
    @State private var toast = ""
    @State private var showToast = false
    @State private var shareURL: URL?
    @State private var showingShare = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // 字体选择
                        Picker("字体", selection: $fontPSName) {
                            Text("系统字体").tag("__system__")
                            ForEach(fontManager.fonts) { f in
                                Text(f.displayName).tag(f.postScriptName)
                            }
                        }
                        .pickerStyle(.menu)

                        // 预览文本
                        Text("预览文本")
                            .font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $previewText)
                            .frame(height: 70)
                            .overlay(RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3)))

                        // 修改后预览
                        Text("修改后")
                            .font(.caption).foregroundColor(.secondary)
                        Text(AttributedString(params.attributedString(
                            text: previewText, fontPSName: fontPSName)))
                            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
                            .padding(12)
                            .background(Color(params.backgroundColor()))
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2)))

                        // 页签
                        Picker("", selection: $tab) {
                            Text("调整").tag(0)
                            Text("颜色").tag(1)
                        }
                        .pickerStyle(.segmented)

                        if tab == 0 {
                            adjustTab
                        } else {
                            colorTab
                        }
                    }
                    .padding()
                }

                // 底部操作栏
                HStack(spacing: 12) {
                    Button(action: undo) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(!canUndo)
                    Button(action: redo) {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(!canRedo)
                    Spacer()
                    Button("应用调整") {
                        pushHistory()
                        showToastMsg("调整已应用")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                    Button("导出文件") { exportImage() }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    Button("还原") {
                        params = AdjustParams.default
                        params.bgColorHex = prefsStore.prefs.defaultBgHex
                        pushHistory()
                        showToastMsg("已还原")
                    }
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(UIColor.systemBackground).shadow(radius: 2))
            }
            .navigationTitle("字体调整")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showSaveDraft = true }) {
                            Image(systemName: "square.and.pencil")
                        }
                        Button(action: { showDrafts = true }) {
                            Image(systemName: "archivebox")
                        }
                    }
                }
            }
            .onAppear {
                if previewText.isEmpty {
                    previewText = prefsStore.prefs.defaultPreviewText
                }
                if params.bgColorHex == "#FFFFFF" {
                    params.bgColorHex = prefsStore.prefs.defaultBgHex
                }
                if historyIndex == -1 { pushHistory() }
            }
            .sheet(isPresented: $showDrafts) {
                DraftBoxView(store: draftStore, onLoad: loadDraft)
            }
            .sheet(isPresented: $showingShare) {
                if let u = shareURL { ShareSheet(items: [u]) }
            }
            .alert("保存草稿", isPresented: $showSaveDraft) {
                TextField("草稿名称", text: $draftName)
                Button("取消", role: .cancel) {}
                Button("保存") { saveDraft() }
            }
            .overlay(alignment: .bottom) {
                if showToast {
                    Text(toast)
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 80)
                }
            }
        }
    }

    // MARK: - 调整页签

    private var adjustTab: some View {
        VStack(alignment: .leading, spacing: 6) {
            Picker("", selection: Binding(
                get: { params.targetAll ? 0 : 1 },
                set: {
                    params.targetAll = ($0 == 0)
                    pushHistory()
                }
            )) {
                Text("全部字符").tag(0)
                Text("指定字符").tag(1)
            }
            .pickerStyle(.segmented)

            if !params.targetAll {
                TextField("输入要调整的字符，如：ABC", text: $params.targetChars)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { pushHistory() }
            }

            Group {
                PctSlider(title: "大小", value: $params.sizePct, onCommit: pushHistory)
                PctSlider(title: "粗细", value: $params.weightPct, onCommit: pushHistory)
                PctSlider(title: "字间距", value: $params.letterSpacingPct, onCommit: pushHistory)
                PctSlider(title: "行间距", value: $params.lineSpacingPct, onCommit: pushHistory)
                PctSlider(title: "上浮下沉", value: $params.baselineShiftPct, onCommit: pushHistory)
            }
            Text("点击右侧数值可以直接输入")
                .font(.caption).foregroundColor(.secondary)
        }
    }

    // MARK: - 颜色页签

    private var colorTab: some View {
        VStack(spacing: 12) {
            ColorPicker("文字颜色", selection: Binding(
                get: { Color(UIColor(hex: params.textColorHex) ?? .label) },
                set: {
                    params.textColorHex = UIColor($0).hexString
                    pushHistory()
                }
            ))
            ColorPicker("背景颜色", selection: Binding(
                get: { Color(params.backgroundColor()) },
                set: {
                    params.bgColorHex = UIColor($0).hexString
                    pushHistory()
                }
            ))
        }
        .padding(.vertical, 8)
    }

    // MARK: - 历史

    private var canUndo: Bool { historyIndex > 0 }
    private var canRedo: Bool { historyIndex < history.count - 1 }

    private func pushHistory() {
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)...)
        }
        // 避免连续重复快照
        if history.last != params {
            history.append(params)
            if history.count > 60 { history.removeFirst() }
        }
        historyIndex = history.count - 1
    }

    private func undo() {
        guard canUndo else { return }
        historyIndex -= 1
        params = history[historyIndex]
    }

    private func redo() {
        guard canRedo else { return }
        historyIndex += 1
        params = history[historyIndex]
    }

    // MARK: - 草稿

    private func saveDraft() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        draftStore.add(AdjustDraft(name: name, fontPSName: fontPSName,
                                   previewText: previewText, params: params))
        draftName = ""
        showToastMsg("草稿已保存")
    }

    private func loadDraft(_ d: AdjustDraft) {
        fontPSName = d.fontPSName
        previewText = d.previewText
        params = d.params
        pushHistory()
        showDrafts = false
        showToastMsg("已载入草稿")
    }

    // MARK: - 导出 / 提示

    private func exportImage() {
        guard let img = params.renderImage(text: previewText, fontPSName: fontPSName),
              let data = img.pngData() else {
            showToastMsg("导出失败")
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("字体工坊-字体调整.png")
        do {
            try data.write(to: url, options: .atomic)
            shareURL = url
            showingShare = true
        } catch {
            showToastMsg("导出失败")
        }
    }

    private func showToastMsg(_ s: String) {
        toast = s
        showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            showToast = false
        }
    }
}

/// 草稿箱
struct DraftBoxView: View {
    @ObservedObject var store: DraftStore
    var onLoad: (AdjustDraft) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if store.drafts.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "archivebox")
                            .font(.largeTitle).foregroundColor(.secondary)
                        Text("草稿箱是空的")
                            .foregroundColor(.secondary)
                        Text("在调整界面点右上角图标可保存当前为草稿")
                            .font(.caption).foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(store.drafts) { d in
                            Button(action: { onLoad(d) }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(d.name).font(.headline)
                                    Text(d.previewText.components(separatedBy: "\n").first ?? "")
                                        .font(.caption).foregroundColor(.secondary)
                                        .lineLimit(1)
                                    Text(d.updatedAt, style: .date)
                                        .font(.caption2).foregroundColor(.secondary)
                                }
                            }
                        }
                        .onDelete { idx in
                            for i in idx { store.remove(store.drafts[i]) }
                        }
                    }
                }
            }
            .navigationTitle("草稿箱")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
