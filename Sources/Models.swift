import SwiftUI

/// 行星贴图风格
enum PlanetStyle {
    case sun        // 太阳
    case rocky      // 岩石（水星）
    case cloudy     // 厚云层（金星）
    case earth      // 地球
    case mars       // 火星
    case gasBands   // 气态条纹（木星、土星）
    case iceGiant   // 冰巨星（天王星、海王星）
}

/// 一颗天体的全部数据
struct Planet: Identifiable, Equatable {
    let id: String
    let nameCN: String
    let nameEN: String
    let emoji: String
    let style: PlanetStyle
    let colors: [String]        // 贴图用配色

    // 显示用（卡通比例，并非真实比例）
    let displayRadius: Double
    let orbitRadius: Double     // 距太阳（0 表示太阳本身）
    let orbitPeriod: Double     // 公转一圈秒数（speed=1 时）
    let spinPeriod: Double      // 自转一圈秒数
    let axialTilt: Double       // 自转轴倾角（度）
    let hasRing: Bool

    // 科普信息
    let orderText: String       // 第几颗行星
    let diameter: String
    let distance: String
    let dayLength: String
    let yearLength: String
    let moons: String
    let temperature: String
    let blurb: String
    let funFacts: [String]

    var color: Color { Color(hex: colors.first ?? "FFFFFF") }

    static func == (l: Planet, r: Planet) -> Bool { l.id == r.id }
}

extension Color {
    init(hex: String) {
        let s = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var v: UInt64 = 0
        Scanner(string: s).scanHexInt64(&v)
        self.init(.sRGB,
                  red: Double((v >> 16) & 0xFF) / 255,
                  green: Double((v >> 8) & 0xFF) / 255,
                  blue: Double(v & 0xFF) / 255,
                  opacity: 1)
    }
}
