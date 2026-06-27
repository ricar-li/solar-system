import Foundation

/// 太阳系数据：太阳 + 八大行星（卡通比例，方便小朋友观察）
enum SolarData {

    static let sun = Planet(
        id: "sun", nameCN: "太阳", nameEN: "Sun", emoji: "☀️",
        style: .sun, colors: ["FFF3B0", "FFC93C", "FF8C00"],
        displayRadius: 1.5, orbitRadius: 0, orbitPeriod: 1, spinPeriod: 20,
        axialTilt: 0, hasRing: false,
        orderText: "太阳系的中心",
        diameter: "约 139 万公里", distance: "—",
        dayLength: "约 25 个地球日", yearLength: "—",
        moons: "8 大行星都绕着它转", temperature: "表面约 5500°C",
        blurb: "太阳是一颗巨大的恒星，给我们光和热。",
        funFacts: [
            "太阳里能装下 130 万个地球！",
            "它发出的光要 8 分钟才能到达地球。",
            "太阳是一个燃烧的大火球，主要由氢和氦组成。",
            "没有太阳，地球上就不会有生命。"
        ])

    static let planets: [Planet] = [
        Planet(
            id: "mercury", nameCN: "水星", nameEN: "Mercury", emoji: "🪨",
            style: .rocky, colors: ["9A8B7A", "6E6258", "C2B4A3"],
            displayRadius: 0.20, orbitRadius: 2.7, orbitPeriod: 6, spinPeriod: 8,
            axialTilt: 0.03, hasRing: false,
            orderText: "第 1 颗行星", diameter: "约 4879 公里",
            distance: "离太阳最近，约 5800 万公里",
            dayLength: "约 59 个地球日", yearLength: "约 88 个地球日",
            moons: "没有卫星", temperature: "白天 430°C，夜晚 -180°C",
            blurb: "离太阳最近、最小的行星，表面布满陨石坑。",
            funFacts: [
                "水星上一天比一年还长！",
                "它没有空气，温差特别大。",
                "表面坑坑洼洼，很像月球。"
            ]),
        Planet(
            id: "venus", nameCN: "金星", nameEN: "Venus", emoji: "🌕",
            style: .cloudy, colors: ["E8C97A", "D9A441", "F3E1A6"],
            displayRadius: 0.32, orbitRadius: 3.6, orbitPeriod: 9, spinPeriod: 12,
            axialTilt: 2.6, hasRing: false,
            orderText: "第 2 颗行星", diameter: "约 12104 公里",
            distance: "约 1.08 亿公里",
            dayLength: "约 243 个地球日", yearLength: "约 225 个地球日",
            moons: "没有卫星", temperature: "约 465°C（最热！）",
            blurb: "被厚厚的云层包裹，是太阳系最热的行星。",
            funFacts: [
                "金星是天空中最亮的星星之一，叫「启明星」。",
                "它自转方向和别的行星相反。",
                "厚云像棉被一样把热气全锁住了。"
            ]),
        Planet(
            id: "earth", nameCN: "地球", nameEN: "Earth", emoji: "🌍",
            style: .earth, colors: ["1E6FB5", "2E9E5B", "E9F2FB"],
            displayRadius: 0.34, orbitRadius: 4.6, orbitPeriod: 12, spinPeriod: 6,
            axialTilt: 23.5, hasRing: false,
            orderText: "第 3 颗行星", diameter: "约 12742 公里",
            distance: "约 1.5 亿公里",
            dayLength: "24 小时", yearLength: "365 天",
            moons: "1 颗（月球）", temperature: "平均约 15°C",
            blurb: "我们的家！是已知唯一有生命的行星。",
            funFacts: [
                "地球表面 71% 都是海洋。",
                "它有刚刚好的温度和空气，适合生命居住。",
                "月球是地球唯一的天然卫星。"
            ]),
        Planet(
            id: "mars", nameCN: "火星", nameEN: "Mars", emoji: "🔴",
            style: .mars, colors: ["C1440E", "E27B58", "F0E0D0"],
            displayRadius: 0.26, orbitRadius: 5.7, orbitPeriod: 16, spinPeriod: 6.2,
            axialTilt: 25, hasRing: false,
            orderText: "第 4 颗行星", diameter: "约 6779 公里",
            distance: "约 2.28 亿公里",
            dayLength: "约 24.6 小时", yearLength: "约 687 个地球日",
            moons: "2 颗（火卫一、火卫二）", temperature: "平均约 -63°C",
            blurb: "红色的星球，科学家正在研究能不能住人。",
            funFacts: [
                "火星上有太阳系最高的火山——奥林帕斯山。",
                "它是红色的，因为土里有铁锈。",
                "人类的探测车正在火星上探险！"
            ]),
        Planet(
            id: "jupiter", nameCN: "木星", nameEN: "Jupiter", emoji: "🟠",
            style: .gasBands, colors: ["D8B58A", "B07A4A", "E8D2B0", "8A5A36"],
            displayRadius: 0.95, orbitRadius: 7.5, orbitPeriod: 28, spinPeriod: 4,
            axialTilt: 3, hasRing: false,
            orderText: "第 5 颗行星", diameter: "约 13.98 万公里",
            distance: "约 7.78 亿公里",
            dayLength: "约 10 小时", yearLength: "约 12 个地球年",
            moons: "95 颗以上", temperature: "约 -110°C",
            blurb: "太阳系最大的行星，是个巨大的气态星球。",
            funFacts: [
                "木星大到能装下 1300 个地球！",
                "上面有个「大红斑」，是刮了几百年的大风暴。",
                "它自转最快，一天只有约 10 小时。"
            ]),
        Planet(
            id: "saturn", nameCN: "土星", nameEN: "Saturn", emoji: "🪐",
            style: .gasBands, colors: ["E3CFA0", "C9A86A", "F0E2C0", "B5945C"],
            displayRadius: 0.82, orbitRadius: 9.4, orbitPeriod: 40, spinPeriod: 4.5,
            axialTilt: 26.7, hasRing: true,
            orderText: "第 6 颗行星", diameter: "约 11.65 万公里",
            distance: "约 14.3 亿公里",
            dayLength: "约 10.7 小时", yearLength: "约 29 个地球年",
            moons: "146 颗以上", temperature: "约 -140°C",
            blurb: "拥有最美光环的行星，光环由冰和石块组成。",
            funFacts: [
                "土星的光环又大又薄，是冰块和石头组成的。",
                "它非常轻，如果有够大的水池，土星能浮起来！",
                "光环宽得能并排放下好多个地球。"
            ]),
        Planet(
            id: "uranus", nameCN: "天王星", nameEN: "Uranus", emoji: "🔵",
            style: .iceGiant, colors: ["A6E1E3", "7FC6CC", "C9EEF0"],
            displayRadius: 0.55, orbitRadius: 10.8, orbitPeriod: 55, spinPeriod: 5,
            axialTilt: 98, hasRing: true,
            orderText: "第 7 颗行星", diameter: "约 50724 公里",
            distance: "约 28.7 亿公里",
            dayLength: "约 17 小时", yearLength: "约 84 个地球年",
            moons: "28 颗以上", temperature: "约 -195°C",
            blurb: "淡蓝色的冰巨星，它是「躺着」自转的。",
            funFacts: [
                "天王星几乎是横着躺着转圈圈的！",
                "它是淡淡的青蓝色，因为含有甲烷气体。",
                "这里非常非常冷。"
            ]),
        Planet(
            id: "neptune", nameCN: "海王星", nameEN: "Neptune", emoji: "🌀",
            style: .iceGiant, colors: ["2E5BD8", "3B73E6", "8AB0F0"],
            displayRadius: 0.53, orbitRadius: 12.0, orbitPeriod: 70, spinPeriod: 5.2,
            axialTilt: 28, hasRing: false,
            orderText: "第 8 颗行星", diameter: "约 49244 公里",
            distance: "离太阳最远，约 45 亿公里",
            dayLength: "约 16 小时", yearLength: "约 165 个地球年",
            moons: "16 颗以上", temperature: "约 -200°C",
            blurb: "离太阳最远的行星，是个刮着狂风的深蓝世界。",
            funFacts: [
                "海王星上的风速能超过每小时 2000 公里！",
                "它是用数学计算「算」出来的行星。",
                "从这里看太阳，只是一个亮亮的小点。"
            ])
    ]

    static var all: [Planet] { [sun] + planets }
    static func planet(id: String) -> Planet? { all.first { $0.id == id } }
}
