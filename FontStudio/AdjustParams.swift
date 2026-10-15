import Foundation
import UIKit

/// 字体调整参数（渲染级）：大小 / 粗细 / 字间距 / 行间距 / 上浮下沉 / 颜色
struct AdjustParams: Codable, Equatable {
    var sizePct: Double = 0          // 大小 ±%
    var weightPct: Double = 0        // 粗细 ±%（合成粗体）
    var letterSpacingPct: Double = 0 // 字间距 ±%
    var lineSpacingPct: Double = 0   // 行间距 ±%
    var baselineShiftPct: Double = 0 // 上浮下沉 ±%
    var targetAll: Bool = true       // true=全部字符， false=指定字符
    var targetChars: String = ""     // 指定字符
    var textColorHex: String = "#1A1A1A"
    var bgColorHex: String = "#FFFFFF"
    var baseFontSize: Double = 28

    static var `default`: AdjustParams { AdjustParams() }

    // MARK: - 富文本构建

    private func uiFont(psName: String, size: CGFloat) -> UIFont {
        if let f = UIFont(name: psName, size: size) { return f }
        return .systemFont(ofSize: size)
    }

    /// 把参数应用到文本，生成富文本（指定字符模式下只调整目标字符）
    func attributedString(text: String, fontPSName: String) -> NSAttributedString {
        let effSize = CGFloat(baseFontSize * (1 + sizePct / 100))
        let baseSize = CGFloat(baseFontSize)
        let targetSet = Set(targetChars)

        func attrs(adjusted: Bool) -> [NSAttributedString.Key: Any] {
            let size = adjusted ? effSize : baseSize
            var a: [NSAttributedString.Key: Any] = [
                .font: uiFont(psName: fontPSName, size: size),
                .foregroundColor: UIColor(hex: textColorHex) ?? .label,
            ]
            if adjusted {
                if weightPct != 0 {
                    // strokeWidth 为负 = 描边+填充，视觉上加粗
                    a[.strokeWidth] = -weightPct * 0.12
                }
                if letterSpacingPct != 0 {
                    a[.kern] = letterSpacingPct / 100 * size * 0.5
                }
                if baselineShiftPct != 0 {
                    a[.baselineOffset] = baselineShiftPct / 100 * size * 0.5
                }
            }
            return a
        }

        let para = NSMutableParagraphStyle()
        if lineSpacingPct != 0 {
            para.lineSpacing = lineSpacingPct / 100 * effSize
        }

        let mas = NSMutableAttributedString()
        for ch in text {
            let adjusted = targetAll || targetSet.contains(ch)
            var a = attrs(adjusted: adjusted)
            a[.paragraphStyle] = para
            mas.append(NSAttributedString(string: String(ch), attributes: a))
        }
        return mas
    }

    func backgroundColor() -> UIColor {
        UIColor(hex: bgColorHex) ?? .systemBackground
    }

    /// 导出为图片
    func renderImage(text: String, fontPSName: String, maxWidth: CGFloat = 1000) -> UIImage? {
        let mas = attributedString(text: text, fontPSName: fontPSName)
        let rect = mas.boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        guard rect.width > 0, rect.height > 0 else { return nil }
        let size = CGSize(width: ceil(rect.width) + 48, height: ceil(rect.height) + 48)
        let bg = backgroundColor()
        return UIGraphicsImageRenderer(size: size).image { _ in
            bg.setFill()
            UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
            mas.draw(in: CGRect(x: 24, y: 24, width: maxWidth, height: ceil(rect.height) + 24))
        }
    }
}

// MARK: - UIColor 十六进制

extension UIColor {
    convenience init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if h.hasPrefix("#") { h.removeFirst() }
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        self.init(red: CGFloat((v >> 16) & 0xff) / 255,
                  green: CGFloat((v >> 8) & 0xff) / 255,
                  blue: CGFloat(v & 0xff) / 255, alpha: 1)
    }

    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
