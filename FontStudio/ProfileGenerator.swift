import Foundation

/// 生成 iOS 描述文件（.mobileconfig），把字体打包成可安装的配置
enum ProfileGenerator {
    static func makeProfile(fontURLs: [URL], displayName: String) throws -> URL {
        var payloads: [[String: Any]] = []
        for url in fontURLs {
            let data = try Data(contentsOf: url)
            payloads.append([
                "PayloadType": "com.apple.font",
                "PayloadIdentifier": "com.youyou.fontstudio.font.\(url.deletingPathExtension().lastPathComponent)",
                "PayloadUUID": UUID().uuidString.uppercased(),
                "PayloadVersion": 1,
                "PayloadDisplayName": url.lastPathComponent,
                "Name": url.lastPathComponent,
                "Font": data,
            ])
        }

        let profile: [String: Any] = [
            "PayloadType": "Configuration",
            "PayloadIdentifier": "com.youyou.fontstudio.profile",
            "PayloadUUID": UUID().uuidString.uppercased(),
            "PayloadVersion": 1,
            "PayloadDisplayName": displayName,
            "PayloadDescription": "由字体工坊生成，用于在 iPhone / iPad 上安装自定义字体",
            "PayloadContent": payloads,
        ]

        let data = try PropertyListSerialization.data(
            fromPropertyList: profile, format: .xml, options: 0
        )
        let out = FileManager.default.temporaryDirectory
            .appendingPathComponent("字体工坊-字体安装.mobileconfig")
        try data.write(to: out, options: .atomic)
        return out
    }
}
