import Foundation
import CoreText
import UIKit
import Combine

/// 字体文件信息
struct FontInfo: Identifiable, Codable, Equatable {
    let fileName: String
    let familyName: String
    let styleName: String
    let fullName: String
    let postScriptName: String
    let fileSize: Int

    var id: String { fileName }
    var displayName: String { fullName.isEmpty ? fileName : fullName }
}

/// 字体库管理：导入 / 注册 / 删除 / 枚举
final class FontManager: ObservableObject {
    static let shared = FontManager()

    @Published private(set) var fonts: [FontInfo] = []

    let fontsDirectory: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fontsDirectory = docs.appendingPathComponent("Fonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: fontsDirectory, withIntermediateDirectories: true)
        registerAll()
        reload()
    }

    // MARK: - 查询

    func reload() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: fontsDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        )) ?? []
        var infos: [FontInfo] = []
        for url in files {
            guard ["ttf", "otf", "ttc"].contains(url.pathExtension.lowercased()) else { continue }
            if let info = inspect(url: url) { infos.append(info) }
        }
        fonts = infos.sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    /// 读取字体文件的元信息（不注册）
    func inspect(url: URL) -> FontInfo? {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let desc = descriptors.first else { return nil }
        func attr(_ key: CFString) -> String {
            (CTFontDescriptorCopyAttribute(desc, key) as? String) ?? ""
        }
        let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
        return FontInfo(
            fileName: url.lastPathComponent,
            familyName: attr(kCTFontFamilyNameAttribute),
            styleName: attr(kCTFontStyleNameAttribute),
            fullName: attr(kCTFontDisplayNameAttribute),
            postScriptName: attr(kCTFontNameAttribute),
            fileSize: size
        )
    }

    /// App 启动时注册全部已导入字体（.process 作用域：仅本 App 内可用）
    func registerAll() {
        let files = (try? FileManager.default.contentsOfDirectory(
            at: fontsDirectory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
        )) ?? []
        for url in files where ["ttf", "otf", "ttc"].contains(url.pathExtension.lowercased()) {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    // MARK: - 导入 / 删除

    @discardableResult
    func importFont(from sourceURL: URL) throws -> FontInfo {
        let dest = fontsDirectory.appendingPathComponent(sourceURL.lastPathComponent)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        let scoped = sourceURL.startAccessingSecurityScopedResource()
        defer { if scoped { sourceURL.stopAccessingSecurityScopedResource() } }
        try FileManager.default.copyItem(at: sourceURL, to: dest)
        CTFontManagerRegisterFontsForURL(dest as CFURL, .process, nil)
        guard let info = inspect(url: dest) else {
            try? FileManager.default.removeItem(at: dest)
            throw FontError.unreadable
        }
        reload()
        return info
    }

    func delete(_ info: FontInfo) {
        let url = fontsDirectory.appendingPathComponent(info.fileName)
        CTFontManagerUnregisterFontsForURL(url as CFURL, .process, nil)
        try? FileManager.default.removeItem(at: url)
        reload()
    }

    // MARK: - 便捷

    func uiFont(postScriptName: String, size: CGFloat) -> UIFont {
        UIFont(name: postScriptName, size: size) ?? UIFont.systemFont(ofSize: size)
    }

    func fileURL(for info: FontInfo) -> URL {
        fontsDirectory.appendingPathComponent(info.fileName)
    }

    enum FontError: LocalizedError {
        case unreadable
        var errorDescription: String? { "无法识别该字体文件，请确认是有效的 ttf / otf / ttc" }
    }
}
