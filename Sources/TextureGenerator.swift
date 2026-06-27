import UIKit

/// 程序化生成所有天体贴图、星空背景、行星名字标签、土星环贴图。
/// 不依赖任何外部图片资源。
enum TextureGenerator {

    static func planetTexture(for p: Planet, width: Int = 1024, height: Int = 512) -> UIImage {
        let size = CGSize(width: width, height: height)
        let r = UIGraphicsImageRenderer(size: size, format: {
            let f = UIGraphicsImageRendererFormat.default(); f.scale = 1; f.opaque = true; return f
        }())
        let W = CGFloat(width), H = CGFloat(height)
        let c = p.colors.map { UIColor(hex: $0) }

        return r.image { ctx in
            let cg = ctx.cgContext
            func fill(_ color: UIColor) { color.setFill(); cg.fill(CGRect(x: 0, y: 0, width: W, height: H)) }

            switch p.style {
            case .sun:
                vGradient(cg, [c[0], c[1], c[2]], W, H)
                for _ in 0..<260 {
                    let x = CGFloat.random(in: 0..<W), y = CGFloat.random(in: 0..<H)
                    let s = CGFloat.random(in: 3...14)
                    (Bool.random() ? c[0] : c[2]).withAlphaComponent(0.5).setFill()
                    cg.fillEllipse(in: CGRect(x: x, y: y, width: s, height: s))
                }

            case .rocky:
                fill(c[0])
                for _ in 0..<420 {
                    let x = CGFloat.random(in: 0..<W), y = CGFloat.random(in: 0..<H)
                    let s = CGFloat.random(in: 4...26)
                    let col = [c[1], c[2], c[0]].randomElement()!
                    col.withAlphaComponent(0.55).setFill()
                    cg.fillEllipse(in: CGRect(x: x, y: y, width: s, height: s))
                }

            case .cloudy:
                vGradient(cg, [c[2], c[0], c[1]], W, H)
                for i in 0..<26 {
                    let y = H / 26 * CGFloat(i) + CGFloat.random(in: -6...6)
                    [c[0], c[1], c[2]].randomElement()!.withAlphaComponent(0.35).setFill()
                    let h = CGFloat.random(in: 6...20)
                    cg.fill(CGRect(x: 0, y: y, width: W, height: h))
                }

            case .earth:
                fill(c[0]) // 海洋
                for _ in 0..<16 { // 陆地
                    let x = CGFloat.random(in: 0..<W), y = CGFloat.random(in: H*0.18..<H*0.82)
                    let w = CGFloat.random(in: 60...190), h = CGFloat.random(in: 40...120)
                    c[1].setFill()
                    cg.fillEllipse(in: CGRect(x: x, y: y, width: w, height: h))
                }
                c[2].setFill() // 两极冰盖
                cg.fill(CGRect(x: 0, y: 0, width: W, height: H*0.07))
                cg.fill(CGRect(x: 0, y: H*0.93, width: W, height: H*0.07))
                for _ in 0..<22 { // 白云
                    let x = CGFloat.random(in: 0..<W), y = CGFloat.random(in: 0..<H)
                    UIColor.white.withAlphaComponent(0.55).setFill()
                    cg.fillEllipse(in: CGRect(x: x, y: y, width: CGFloat.random(in: 30...90), height: CGFloat.random(in: 14...34)))
                }

            case .mars:
                vGradient(cg, [c[1], c[0], c[1]], W, H)
                for _ in 0..<60 {
                    let x = CGFloat.random(in: 0..<W), y = CGFloat.random(in: 0..<H)
                    c[0].withAlphaComponent(0.5).setFill()
                    cg.fillEllipse(in: CGRect(x: x, y: y, width: CGFloat.random(in: 20...70), height: CGFloat.random(in: 14...44)))
                }
                c[2].setFill() // 极冠
                cg.fillEllipse(in: CGRect(x: W*0.5 - 70, y: -30, width: 140, height: 70))
                cg.fillEllipse(in: CGRect(x: W*0.5 - 60, y: H-40, width: 120, height: 70))

            case .gasBands:
                let bandCount = 22
                for i in 0..<bandCount {
                    let y = H / CGFloat(bandCount) * CGFloat(i)
                    let col = c[i % c.count]
                    col.setFill()
                    cg.fill(CGRect(x: 0, y: y, width: W, height: H / CGFloat(bandCount) + 1))
                }
                // 柔化条纹
                for i in 0..<bandCount {
                    let y = H / CGFloat(bandCount) * CGFloat(i)
                    UIColor.white.withAlphaComponent(0.06).setFill()
                    cg.fill(CGRect(x: 0, y: y, width: W, height: 2))
                }
                if p.id == "jupiter" { // 大红斑
                    UIColor(hex: "C0492B").setFill()
                    cg.fillEllipse(in: CGRect(x: W*0.62, y: H*0.58, width: 120, height: 70))
                    UIColor(hex: "E07B5A").withAlphaComponent(0.6).setFill()
                    cg.fillEllipse(in: CGRect(x: W*0.64, y: H*0.60, width: 80, height: 44))
                }

            case .iceGiant:
                vGradient(cg, [c[2], c[0], c[1]], W, H)
                for i in 0..<10 {
                    let y = H / 10 * CGFloat(i)
                    c[1].withAlphaComponent(0.25).setFill()
                    cg.fill(CGRect(x: 0, y: y, width: W, height: 4))
                }
            }
        }
    }

    /// 土星 / 天王星 的环贴图（径向条纹）
    static func ringTexture(width: Int = 512, height: Int = 64,
                            base: String = "D9C9A0") -> UIImage {
        let r = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return r.image { ctx in
            let cg = ctx.cgContext
            for x in stride(from: 0, to: width, by: 1) {
                let t = CGFloat(x) / CGFloat(width)
                let alpha = 0.35 + 0.5 * abs(sin(t * 22))
                UIColor(hex: base).withAlphaComponent(alpha).setFill()
                cg.fill(CGRect(x: x, y: 0, width: 1, height: height))
            }
        }
    }

    static func starfield(width: Int = 2048, height: Int = 1024) -> UIImage {
        let r = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return r.image { ctx in
            let cg = ctx.cgContext
            vGradient(cg, [UIColor(hex: "04050C"), UIColor(hex: "0A1024"), UIColor(hex: "04050C")],
                      CGFloat(width), CGFloat(height))
            for _ in 0..<900 {
                let x = CGFloat.random(in: 0..<CGFloat(width))
                let y = CGFloat.random(in: 0..<CGFloat(height))
                let s = CGFloat.random(in: 0.4...1.8)
                UIColor.white.withAlphaComponent(CGFloat.random(in: 0.3...1)).setFill()
                cg.fillEllipse(in: CGRect(x: x, y: y, width: s, height: s))
            }
            for _ in 0..<40 {
                let x = CGFloat.random(in: 0..<CGFloat(width))
                let y = CGFloat.random(in: 0..<CGFloat(height))
                UIColor(hex: "FFE9A8").withAlphaComponent(0.9).setFill()
                cg.fillEllipse(in: CGRect(x: x, y: y, width: 2.6, height: 2.6))
            }
        }
    }

    static func labelImage(_ text: String) -> UIImage {
        let font = UIFont.systemFont(ofSize: 46, weight: .bold)
        let attr: [NSAttributedString.Key: Any] = [
            .font: font, .foregroundColor: UIColor.white
        ]
        let str = text as NSString
        let textSize = str.size(withAttributes: attr)
        let pad: CGFloat = 26
        let size = CGSize(width: textSize.width + pad * 2, height: textSize.height + pad)
        let r = UIGraphicsImageRenderer(size: size)
        return r.image { ctx in
            let cg = ctx.cgContext
            let rect = CGRect(origin: .zero, size: size)
            UIColor.black.withAlphaComponent(0.45).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: size.height / 2).fill()
            UIColor.white.withAlphaComponent(0.25).setStroke()
            let bp = UIBezierPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: size.height/2)
            bp.lineWidth = 3; bp.stroke()
            cg.flush()
            str.draw(at: CGPoint(x: pad, y: pad/2 - 2), withAttributes: attr)
        }
    }

    // MARK: helpers
    private static func vGradient(_ cg: CGContext, _ colors: [UIColor], _ w: CGFloat, _ h: CGFloat) {
        let locs: [CGFloat] = colors.count == 3 ? [0, 0.5, 1] :
            (0..<colors.count).map { CGFloat($0) / CGFloat(colors.count - 1) }
        if let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                 colors: colors.map { $0.cgColor } as CFArray, locations: locs) {
            cg.drawLinearGradient(grad, start: .zero, end: CGPoint(x: 0, y: h), options: [])
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(red: CGFloat((v >> 16) & 0xFF) / 255,
                  green: CGFloat((v >> 8) & 0xFF) / 255,
                  blue: CGFloat(v & 0xFF) / 255, alpha: 1)
    }
}
