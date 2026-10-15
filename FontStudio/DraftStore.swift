import Foundation

/// 一份调整草稿：字体 + 预览文本 + 调整参数
struct AdjustDraft: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var fontPSName: String
    var previewText: String
    var params: AdjustParams
    var updatedAt: Date = Date()
}

/// 草稿箱：内容保存在设备本地
final class DraftStore: ObservableObject {
    @Published private(set) var drafts: [AdjustDraft] = []
    private let url: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        url = docs.appendingPathComponent("adjust_drafts.json")
        load()
    }

    private func load() {
        if let d = try? Data(contentsOf: url),
           let arr = try? JSONDecoder().decode([AdjustDraft].self, from: d) {
            drafts = arr.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    private func persist() {
        try? JSONEncoder().encode(drafts).write(to: url, options: .atomic)
    }

    func add(_ draft: AdjustDraft) {
        var d = draft
        d.updatedAt = Date()
        drafts.removeAll { $0.id == d.id }
        drafts.insert(d, at: 0)
        persist()
    }

    func remove(_ draft: AdjustDraft) {
        drafts.removeAll { $0.id == draft.id }
        persist()
    }
}
