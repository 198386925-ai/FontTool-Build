import Foundation
import Compression

/// 字体格式转换：sfnt（ttf / otf）与 WOFF 1.0 互转
/// WOFF 只是把 sfnt 的表用 zlib 压缩打包，不改变字形轮廓
enum FontConverter {
    enum ConvertError: LocalizedError {
        case invalidFont
        case invalidWoff
        case unsupported(String)
        var errorDescription: String? {
            switch self {
            case .invalidFont: return "不是有效的 ttf / otf 字体文件"
            case .invalidWoff: return "不是有效的 woff 文件"
            case .unsupported(let s): return s
            }
        }
    }

    struct Table {
        let tag: Data   // 4 字节
        let bytes: Data
    }

    // MARK: - 字节读写（大端）

    private static func u16(_ d: Data, _ o: Int) -> UInt16 {
        (UInt16(d[o]) << 8) | UInt16(d[o + 1])
    }

    private static func u32(_ d: Data, _ o: Int) -> UInt32 {
        (UInt32(d[o]) << 24) | (UInt32(d[o + 1]) << 16) | (UInt32(d[o + 2]) << 8) | UInt32(d[o + 3])
    }

    private static func appendU16(_ d: inout Data, _ v: UInt16) {
        d.append(UInt8(v >> 8)); d.append(UInt8(v & 0xff))
    }

    private static func appendU32(_ d: inout Data, _ v: UInt32) {
        d.append(UInt8(v >> 24)); d.append(UInt8((v >> 16) & 0xff))
        d.append(UInt8((v >> 8) & 0xff)); d.append(UInt8(v & 0xff))
    }

    private static func checksum(_ d: Data) -> UInt32 {
        var sum: UInt64 = 0
        var i = 0
        while i < d.count {
            var w: UInt32 = 0
            for b in 0..<4 {
                w = (w << 8) | (i + b < d.count ? UInt32(d[i + b]) : 0)
            }
            sum &+= UInt64(w)
            i += 4
        }
        return UInt32(sum & 0xffffffff)
    }

    // MARK: - zlib

    private static func zlibCompress(_ d: Data) -> Data? {
        guard !d.isEmpty else { return Data() }
        let dstSize = d.count + 64
        var dst = Data(count: dstSize)
        let scratchSize = compression_encode_scratch_buffer_size(COMPRESSION_ZLIB)
        var scratch = Data(count: scratchSize)
        let outSize: Int = dst.withUnsafeMutableBytes { dp in
            d.withUnsafeBytes { sp in
                scratch.withUnsafeMutableBytes { scp in
                    compression_encode_buffer(
                        dp.bindMemory(to: UInt8.self).baseAddress!,
                        dstSize,
                        sp.bindMemory(to: UInt8.self).baseAddress!,
                        d.count,
                        scp.bindMemory(to: UInt8.self).baseAddress,
                        COMPRESSION_ZLIB)
                }
            }
        }
        guard outSize > 0 else { return nil }
        return dst.prefix(outSize)
    }

    private static func zlibDecompress(_ d: Data, expected: Int) -> Data? {
        guard !d.isEmpty, expected > 0 else { return nil }
        var dst = Data(count: expected)
        let scratchSize = compression_decode_scratch_buffer_size(COMPRESSION_ZLIB)
        var scratch = Data(count: scratchSize)
        let outSize: Int = dst.withUnsafeMutableBytes { dp in
            d.withUnsafeBytes { sp in
                scratch.withUnsafeMutableBytes { scp in
                    compression_decode_buffer(
                        dp.bindMemory(to: UInt8.self).baseAddress!,
                        expected,
                        sp.bindMemory(to: UInt8.self).baseAddress!,
                        d.count,
                        scp.bindMemory(to: UInt8.self).baseAddress,
                        COMPRESSION_ZLIB)
                }
            }
        }
        guard outSize == expected else { return nil }
        return dst
    }

    // MARK: - sfnt 解析 / 组装

    static func isWoff(_ d: Data) -> Bool {
        d.count >= 4 && u32(d, 0) == 0x774F4646 // "wOFF"
    }

    static func parseSfnt(_ d: Data) throws -> (flavor: UInt32, tables: [Table]) {
        guard d.count >= 12 else { throw ConvertError.invalidFont }
        let flavor = u32(d, 0)
        guard flavor == 0x00010000 || flavor == 0x4F54544F /* OTTO */ else {
            throw ConvertError.invalidFont
        }
        let n = Int(u16(d, 4))
        guard d.count >= 12 + n * 16 else { throw ConvertError.invalidFont }
        var tables: [Table] = []
        for i in 0..<n {
            let o = 12 + i * 16
            let tag = d[o..<(o + 4)]
            let offset = Int(u32(d, o + 8))
            let length = Int(u32(d, o + 12))
            guard offset + length <= d.count else { throw ConvertError.invalidFont }
            tables.append(Table(tag: tag, bytes: d[offset..<(offset + length)]))
        }
        return (flavor, tables)
    }

    static func buildSfnt(flavor: UInt32, tables: [Table]) -> Data {
        let sorted = tables.sorted { $0.tag.lexicographicallyPrecedes($1.tag) }
        let n = sorted.count
        var entrySelector = 0
        var p = 1
        while p * 2 <= n { p *= 2; entrySelector += 1 }
        let searchRange = p * 16
        var out = Data()
        appendU32(&out, flavor)
        appendU16(&out, UInt16(n))
        appendU16(&out, UInt16(searchRange))
        appendU16(&out, UInt16(entrySelector))
        appendU16(&out, UInt16(n * 16 - searchRange))
        var offset = 12 + n * 16
        var records = Data()
        var body = Data()
        for tab in sorted {
            records.append(tab.tag)
            appendU32(&records, checksum(tab.bytes))
            appendU32(&records, UInt32(offset))
            appendU32(&records, UInt32(tab.bytes.count))
            body.append(tab.bytes)
            let pad = (4 - tab.bytes.count % 4) % 4
            if pad > 0 { body.append(Data(repeating: 0, count: pad)) }
            offset += tab.bytes.count + pad
        }
        out.append(records)
        out.append(body)
        return out
    }

    // MARK: - WOFF 打包 / 解包

    static func sfntToWoff(_ d: Data) throws -> Data {
        let (flavor, tables) = try parseSfnt(d)
        let sorted = tables.sorted { $0.tag.lexicographicallyPrecedes($1.tag) }
        let n = sorted.count
        var out = Data()
        appendU32(&out, 0x774F4646) // "wOFF"
        appendU32(&out, flavor)
        appendU32(&out, 0)          // 总长度占位
        appendU16(&out, UInt16(n))
        appendU16(&out, 0)          // reserved
        var totalSfnt: UInt32 = UInt32(12 + n * 16)
        for t in sorted { totalSfnt &+= UInt32(t.bytes.count) }
        appendU32(&out, totalSfnt)
        appendU16(&out, 1); appendU16(&out, 0) // 版本 1.0
        for _ in 0..<5 { appendU32(&out, 0) }  // meta / priv 偏移长度（无）
        var dataOffset = 44 + 20 * n
        var dir = Data()
        var body = Data()
        for tab in sorted {
            let comp = zlibCompress(tab.bytes) ?? tab.bytes
            let stored = comp.count < tab.bytes.count ? comp : tab.bytes
            dir.append(tab.tag)
            appendU32(&dir, UInt32(dataOffset))
            appendU32(&dir, UInt32(stored.count))
            appendU32(&dir, UInt32(tab.bytes.count))
            appendU32(&dir, checksum(tab.bytes))
            body.append(stored)
            let pad = (4 - stored.count % 4) % 4
            if pad > 0 { body.append(Data(repeating: 0, count: pad)) }
            dataOffset += stored.count + pad
        }
        out.append(dir)
        out.append(body)
        var be = UInt32(out.count).bigEndian
        withUnsafeBytes(of: &be) { out.replaceSubrange(8..<12, with: $0) }
        return out
    }

    static func woffToSfnt(_ d: Data) throws -> Data {
        guard d.count >= 44, u32(d, 0) == 0x774F4646 else { throw ConvertError.invalidWoff }
        let flavor = u32(d, 4)
        let n = Int(u16(d, 12))
        guard d.count >= 44 + n * 20 else { throw ConvertError.invalidWoff }
        var tables: [Table] = []
        for i in 0..<n {
            let o = 44 + i * 20
            let tag = d[o..<(o + 4)]
            let offset = Int(u32(d, o + 4))
            let compLen = Int(u32(d, o + 8))
            let origLen = Int(u32(d, o + 12))
            guard offset + compLen <= d.count else { throw ConvertError.invalidWoff }
            let stored = d[offset..<(offset + compLen)]
            let bytes: Data
            if compLen == origLen {
                bytes = stored
            } else {
                guard let dec = zlibDecompress(stored, expected: origLen) else {
                    throw ConvertError.invalidWoff
                }
                bytes = dec
            }
            tables.append(Table(tag: tag, bytes: bytes))
        }
        return buildSfnt(flavor: flavor, tables: tables)
    }

    /// 转换文件并写入临时目录，返回输出文件 URL
    static func convertFile(inputURL: URL, toExtension ext: String) throws -> URL {
        let data = try Data(contentsOf: inputURL)
        let woff = isWoff(data)
        let out: Data
        switch ext.lowercased() {
        case "woff":
            guard !woff else { throw ConvertError.unsupported("已经是 woff 格式，无需转换") }
            out = try sfntToWoff(data)
        case "ttf", "otf":
            guard woff else { throw ConvertError.unsupported("请选择 woff 文件进行解包") }
            out = try woffToSfnt(data)
        default:
            throw ConvertError.unsupported("暂不支持 \(ext) 格式")
        }
        let name = inputURL.deletingPathExtension().lastPathComponent + "." + ext.lowercased()
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try out.write(to: url, options: .atomic)
        return url
    }
}
