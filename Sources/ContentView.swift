import SwiftUI

// MARK: - 儿童 UI 主题（7–9 岁）

enum KidUI {
    static let skyTop = Color(hex: "1A0B3A")
    static let candy = Color(hex: "FF6BCB")
    static let mint = Color(hex: "5CFFB0")
    static let lemon = Color(hex: "FFE566")
    static let sky = Color(hex: "6EC8FF")
    static let grape = Color(hex: "A78BFA")
    static let cream = Color(hex: "FFF8E7")
    static let softCard = Color.white.opacity(0.16)
    static let softStroke = Color.white.opacity(0.35)

    static func kidFont(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

struct ContentView: View {
    @Environment(\.horizontalSizeClass) private var hSize
    @Environment(\.verticalSizeClass) private var vSize

    @State private var speed: Double = 1.0
    @State private var paused = false
    /// 打开信息卡/猜猜看前的暂停状态，关闭后恢复。
    @State private var pausedBeforeOverlay: Bool? = nil
    @State private var showOrbits = true
    @State private var showLabels = true
    @State private var selected: Planet? = nil
    @State private var resetToken = 0
    @State private var quizMode = false
    @State private var quiz: QuizQuestion? = nil
    @State private var quizFeedback: String? = nil
    @State private var quizScore = 0
    @State private var quizAsked = 0
    /// 小提示只在首次展示；点「知道啦」后不再出现。
    @AppStorage("kid.tip.dismissed") private var tipDismissed = false

    /// iPhone 竖屏 / 窄宽度
    private var isCompact: Bool { hSize == .compact }
    /// iPhone 横屏矮高度
    private var isShort: Bool { vSize == .compact }

    /// 信息卡或猜猜看打开时自动暂停公转，方便看清。
    private var orbitsShouldPause: Bool { paused || selected != nil || quizMode }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "12082A"), .black, Color(hex: "0A1628")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            SpaceView(speed: speed, paused: orbitsShouldPause,
                      showOrbits: showOrbits, showLabels: showLabels,
                      selectedID: selected?.id,
                      resetToken: resetToken,
                      onTapPlanet: { p in
                          beginOverlayPause()
                          withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
                              selected = p
                              quizMode = false
                          }
                      },
                      onReset: {
                          clearSelectionLikePanorama()
                      })
            .ignoresSafeArea()

            // iPhone：信息卡打开时半透明遮罩，方便阅读
            if isCompact && selected != nil && !quizMode {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, isCompact ? 12 : 18)
                    .padding(.top, isCompact ? 6 : 12)

                if !tipDismissed && selected == nil && !quizMode && !isShort {
                    tipBanner
                        .padding(.horizontal, isCompact ? 12 : 18)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                Spacer(minLength: 0)

                // 信息卡打开时（尤其 iPhone）藏起底部条，避免挡卡片
                let hideChrome = isCompact && (selected != nil || quizMode)
                if !quizMode && !hideChrome {
                    planetPicker
                        .padding(.horizontal, isCompact ? 8 : 14)
                }
                if !hideChrome {
                    controlBar
                        .padding(.horizontal, isCompact ? 10 : 18)
                        .padding(.bottom, isCompact ? 10 : 18)
                } else {
                    // 留一点底部安全区给信息卡
                    Color.clear.frame(height: 4)
                }
            }

            // 信息卡：iPhone 底部抽屉；iPad 右侧浮层
            if quizMode {
                quizLayer
            } else if let p = selected {
                infoLayer(p)
            }
        }
    }

    @ViewBuilder
    private func infoLayer(_ p: Planet) -> some View {
        GeometryReader { geo in
            if isCompact {
                VStack {
                    Spacer()
                    InfoCard(
                        planet: p, compact: true,
                        onClose: { dismissSelection() },
                        onPrev: { withAnimation { selected = prevPlanet(before: p) } },
                        onNext: { withAnimation { selected = nextPlanet(after: p) } }
                    )
                    .frame(maxHeight: geo.size.height * 0.58)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }
            } else {
                HStack {
                    Spacer()
                    InfoCard(
                        planet: p, compact: false,
                        onClose: { dismissSelection() },
                        onPrev: { withAnimation { selected = prevPlanet(before: p) } },
                        onNext: { withAnimation { selected = nextPlanet(after: p) } }
                    )
                    .frame(maxWidth: min(460, geo.size.width * 0.42))
                    .padding(.trailing, 16)
                    .padding(.top, 64)
                    .padding(.bottom, 20)
                }
            }
        }
        .transition(.opacity)
    }

    private var quizLayer: some View {
        QuizPanel(
            question: quiz,
            feedback: quizFeedback,
            score: quizScore,
            asked: quizAsked,
            compact: isCompact,
            onPick: answerQuiz,
            onNext: nextQuiz,
            onVisitAnswer: visitQuizAnswer,
            onClose: closeQuiz
        )
        .frame(maxWidth: isCompact ? .infinity : 520)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(isCompact ? 12 : 20)
        .transition(.scale(scale: 0.92).combined(with: .opacity))
    }

    // MARK: 顶部
    private var header: some View {
        HStack(alignment: .center, spacing: isCompact ? 8 : 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("🪐 太空小探险")
                    .font(KidUI.kidFont(isCompact ? 24 : 32, .heavy))
                    .foregroundStyle(KidUI.cream)
                    .shadow(color: KidUI.candy.opacity(0.45), radius: 8, y: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if !isCompact {
                    Text("点一颗星球，听听它的故事～")
                        .font(KidUI.kidFont(16, .semibold))
                        .foregroundStyle(KidUI.sky)
                }
            }
            Spacer(minLength: 4)
            Button {
                resetToken += 1
                clearSelectionLikePanorama()
            } label: {
                HStack(spacing: 4) {
                    Text("🏠")
                    Text(isCompact ? "全景" : "看全部")
                        .font(KidUI.kidFont(isCompact ? 13 : 14, .heavy))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, isCompact ? 12 : 14)
                .padding(.vertical, isCompact ? 10 : 12)
                .background(Capsule().fill(KidUI.grape.opacity(0.9)))
            }
            .buttonStyle(BounceButtonStyle())
        }
    }

    private var tipBanner: some View {
        Group {
            if isCompact {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("👋 小提示")
                            .font(KidUI.kidFont(16, .heavy))
                            .foregroundStyle(KidUI.lemon)
                        Spacer()
                        Button("知道啦") {
                            withAnimation { tipDismissed = true }
                        }
                        .font(KidUI.kidFont(13, .heavy))
                        .foregroundStyle(KidUI.skyTop)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(KidUI.lemon))
                    }
                    Text("拖一拖、捏一捏，点星球听故事；也可玩「猜猜看」！")
                        .font(KidUI.kidFont(14, .semibold))
                        .foregroundStyle(.white.opacity(0.95))
                }
            } else {
                HStack(spacing: 12) {
                    Text("👋").font(.system(size: 36))
                    VStack(alignment: .leading, spacing: 4) {
                        Text("小提示")
                            .font(KidUI.kidFont(18, .heavy))
                            .foregroundStyle(KidUI.lemon)
                        Text("用手指拖一拖、捏一捏，点亮星球；也可以玩「猜猜看」！")
                            .font(KidUI.kidFont(15, .semibold))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    Spacer()
                    Button("知道啦") {
                        withAnimation { tipDismissed = true }
                    }
                    .font(KidUI.kidFont(15, .heavy))
                    .foregroundStyle(KidUI.skyTop)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Capsule().fill(KidUI.lemon))
                }
            }
        }
        .padding(isCompact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(hex: "2A1450").opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(KidUI.lemon.opacity(0.55), lineWidth: 2)
                )
        )
    }

    // MARK: 行星条
    private var planetPicker: some View {
        let chipW: CGFloat = isCompact ? 64 : 78
        let chipH: CGFloat = isCompact ? 74 : 88
        let emoji: CGFloat = isCompact ? 28 : 36
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isCompact ? 8 : 12) {
                ForEach(SolarData.all) { p in
                    let on = selected?.id == p.id
                    Button {
                        beginOverlayPause()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selected = p
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Text(p.emoji)
                                .font(.system(size: emoji))
                                .scaleEffect(on ? 1.1 : 1)
                            Text(p.nameCN)
                                .font(KidUI.kidFont(isCompact ? 12 : 15, .heavy))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(width: chipW, height: chipH)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(on ? p.color.opacity(0.55) : KidUI.softCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(on ? KidUI.lemon : KidUI.softStroke, lineWidth: on ? 3 : 2)
                        )
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
        }
        .padding(.bottom, 6)
    }

    // MARK: 控制栏
    private var controlBar: some View {
        VStack(spacing: isCompact ? 8 : 12) {
            HStack(spacing: 8) {
                Text("速度")
                    .font(KidUI.kidFont(isCompact ? 13 : 16, .heavy))
                    .foregroundStyle(KidUI.mint)
                Text("慢").font(KidUI.kidFont(12, .bold)).foregroundStyle(.white.opacity(0.7))
                Slider(value: $speed, in: 0.1...5).tint(KidUI.mint)
                Text("快").font(KidUI.kidFont(12, .bold)).foregroundStyle(.white.opacity(0.7))
            }

            if isCompact {
                // 2×2 网格，适合 iPhone 宽度
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    BigKidButton(emoji: paused ? "▶️" : "⏸️",
                                 title: paused ? "开始转" : "停一下",
                                 fill: paused ? KidUI.mint : KidUI.sky,
                                 compact: true) { paused.toggle() }
                    BigKidToggle(emoji: "⭕", title: "轨道", on: $showOrbits, onColor: KidUI.sky, compact: true)
                    BigKidToggle(emoji: "🔤", title: "名字", on: $showLabels, onColor: KidUI.grape, compact: true)
                    BigKidButton(emoji: "🎯", title: "猜猜看", fill: KidUI.candy, compact: true) { openQuiz() }
                }
            } else {
                HStack(spacing: 10) {
                    BigKidButton(emoji: paused ? "▶️" : "⏸️",
                                 title: paused ? "开始转" : "停一下",
                                 fill: paused ? KidUI.mint : KidUI.sky) { paused.toggle() }
                    BigKidToggle(emoji: "⭕", title: "轨道", on: $showOrbits, onColor: KidUI.sky)
                    BigKidToggle(emoji: "🔤", title: "名字", on: $showLabels, onColor: KidUI.grape)
                    BigKidButton(emoji: "🎯", title: "猜猜看", fill: KidUI.candy) { openQuiz() }
                }
            }
        }
        .padding(isCompact ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: isCompact ? 20 : 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: isCompact ? 20 : 28, style: .continuous)
                        .stroke(KidUI.softStroke, lineWidth: 2)
                )
        )
    }

    // MARK: - 选中 / 暂停辅助

    private func beginOverlayPause() {
        if pausedBeforeOverlay == nil {
            pausedBeforeOverlay = paused
        }
    }

    private func endOverlayPause() {
        if let prev = pausedBeforeOverlay {
            paused = prev
            pausedBeforeOverlay = nil
        }
    }

    private func dismissSelection() {
        withAnimation {
            selected = nil
        }
        endOverlayPause()
    }

    /// 与「全景」按钮一致：清空选中与猜猜看，并恢复公转。
    private func clearSelectionLikePanorama() {
        withAnimation {
            selected = nil
            quizMode = false
            quizFeedback = nil
        }
        endOverlayPause()
    }

    private func nextPlanet(after p: Planet) -> Planet {
        let all = SolarData.all
        guard let i = all.firstIndex(of: p) else { return all[0] }
        return all[(i + 1) % all.count]
    }

    private func prevPlanet(before p: Planet) -> Planet {
        let all = SolarData.all
        guard let i = all.firstIndex(of: p) else { return all[0] }
        return all[(i - 1 + all.count) % all.count]
    }

    private func openQuiz() {
        beginOverlayPause()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            selected = nil
            quizMode = true
            quizFeedback = nil
            quiz = QuizEngine.makeQuestion(avoidID: quiz?.answerID)
        }
    }

    private func closeQuiz() {
        withAnimation {
            quizMode = false
            quizFeedback = nil
        }
        endOverlayPause()
    }

    private func answerQuiz(_ choice: Planet) {
        guard let q = quiz, quizFeedback == nil else { return }
        quizAsked += 1
        if choice.id == q.answerID {
            quizScore += 1
            quizFeedback = "太棒了！🎉 就是 \(choice.emoji)\(choice.nameCN)！"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            let right = SolarData.planet(id: q.answerID)
            quizFeedback = "差一点点～ 答案是 \(right?.emoji ?? "")\(right?.nameCN ?? "")，下次你一定行！"
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func nextQuiz() {
        quizFeedback = nil
        quiz = QuizEngine.makeQuestion(avoidID: quiz?.answerID)
    }

    /// 答完后「去看看它」：关掉猜猜看，飞向正确答案星球。
    private func visitQuizAnswer() {
        guard let q = quiz, let p = SolarData.planet(id: q.answerID) else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            quizMode = false
            quizFeedback = nil
            selected = p
        }
        // 保持 overlay 暂停（信息卡仍打开）
        if pausedBeforeOverlay == nil {
            pausedBeforeOverlay = paused
        }
    }
}

// MARK: - 按钮

struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.55), value: configuration.isPressed)
    }
}

struct BigKidButton: View {
    let emoji: String
    let title: String
    var fill: Color = KidUI.sky
    var compact: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: compact ? 2 : 4) {
                Text(emoji).font(.system(size: compact ? 22 : 26))
                Text(title)
                    .font(KidUI.kidFont(compact ? 12 : 14, .heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 56 : 68)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(fill.opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(.white.opacity(0.4), lineWidth: 2)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

struct BigKidToggle: View {
    let emoji: String
    let title: String
    @Binding var on: Bool
    var onColor: Color = KidUI.sky
    var compact: Bool = false

    var body: some View {
        Button { on.toggle() } label: {
            VStack(spacing: compact ? 2 : 4) {
                Text(emoji).font(.system(size: compact ? 22 : 26))
                Text(title).font(KidUI.kidFont(compact ? 12 : 14, .heavy))
            }
            .foregroundStyle(on ? .white : .white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 56 : 68)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(on ? onColor.opacity(0.85) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(on ? .white.opacity(0.5) : .white.opacity(0.2), lineWidth: 2)
            )
        }
        .buttonStyle(BounceButtonStyle())
    }
}

// MARK: - 信息卡片

struct InfoCard: View {
    let planet: Planet
    var compact: Bool = false
    let onClose: () -> Void
    let onPrev: () -> Void
    let onNext: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Text(planet.emoji)
                        .font(.system(size: compact ? 40 : 56))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(planet.nameCN)
                            .font(KidUI.kidFont(compact ? 24 : 32, .heavy))
                            .foregroundStyle(KidUI.cream)
                        Text(planet.orderText)
                            .font(KidUI.kidFont(compact ? 13 : 16, .semibold))
                            .foregroundStyle(KidUI.lemon)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Text("关闭")
                            .font(KidUI.kidFont(compact ? 13 : 15, .heavy))
                            .foregroundStyle(KidUI.skyTop)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(KidUI.cream))
                    }
                }
                .padding(.bottom, 10)

                Text(planet.blurb)
                    .font(KidUI.kidFont(compact ? 15 : 18, .semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 12)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                          spacing: compact ? 8 : 10) {
                    dataPill("多大呀", planet.diameter, KidUI.sky)
                    dataPill("离太阳", planet.distance, KidUI.lemon)
                    dataPill("一天多长", planet.dayLength, KidUI.mint)
                    dataPill("一年多长", planet.yearLength, KidUI.grape)
                    dataPill("小月亮", planet.moons, KidUI.candy)
                    dataPill("冷不冷", planet.temperature, Color(hex: "FF9F6B"))
                }
                .padding(.bottom, 12)

                Text("🌟 好玩小知识")
                    .font(KidUI.kidFont(compact ? 15 : 18, .heavy))
                    .foregroundStyle(KidUI.lemon)
                    .padding(.bottom, 6)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(planet.funFacts.enumerated()), id: \.offset) { _, fact in
                        HStack(alignment: .top, spacing: 6) {
                            Text("⭐️")
                            Text(fact)
                                .font(KidUI.kidFont(compact ? 14 : 16, .semibold))
                                .foregroundStyle(.white.opacity(0.95))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.bottom, 14)

                HStack(spacing: 10) {
                    Button(action: onPrev) {
                        Text("⬅️ 上一颗")
                            .font(KidUI.kidFont(compact ? 15 : 17, .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, compact ? 12 : 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(KidUI.grape.opacity(0.9)))
                    }
                    .buttonStyle(BounceButtonStyle())
                    Button(action: onNext) {
                        Text("下一颗 ➡️")
                            .font(KidUI.kidFont(compact ? 15 : 17, .heavy))
                            .foregroundStyle(KidUI.skyTop)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, compact ? 12 : 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(KidUI.lemon))
                    }
                    .buttonStyle(BounceButtonStyle())
                }
            }
            .padding(compact ? 14 : 22)
        }
        .background(
            RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous)
                .fill(Color(hex: "1B0F38").opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 22 : 28, style: .continuous)
                        .stroke(planet.color.opacity(0.75), lineWidth: 3)
                )
        )
        .shadow(color: planet.color.opacity(0.35), radius: 16, y: 8)
    }

    private func dataPill(_ title: String, _ value: String, _ accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(KidUI.kidFont(compact ? 11 : 13, .heavy))
                .foregroundStyle(accent)
            Text(value)
                .font(KidUI.kidFont(compact ? 13 : 15, .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(accent.opacity(0.18))
        )
    }
}

// MARK: - 猜猜看

struct QuizPanel: View {
    let question: QuizQuestion?
    let feedback: String?
    let score: Int
    let asked: Int
    var compact: Bool = false
    let onPick: (Planet) -> Void
    let onNext: () -> Void
    let onVisitAnswer: () -> Void
    let onClose: () -> Void

    private let choiceColors: [Color] = [KidUI.sky, KidUI.mint, KidUI.candy]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: compact ? 12 : 18) {
                HStack {
                    Text("🎯 星球猜猜看")
                        .font(KidUI.kidFont(compact ? 20 : 28, .heavy))
                        .foregroundStyle(KidUI.cream)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    // 还没答题时不显示 0/1 之类的迷惑分数
                    Text(asked == 0 ? "加油呀！" : "答对 \(score) 题")
                        .font(KidUI.kidFont(compact ? 14 : 18, .heavy))
                        .foregroundStyle(KidUI.skyTop)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(KidUI.lemon))
                    Button(action: onClose) {
                        Text("退出")
                            .font(KidUI.kidFont(13, .heavy))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.white.opacity(0.2)))
                    }
                }

                if let q = question {
                    Text(q.prompt)
                        .font(KidUI.kidFont(compact ? 16 : 20, .semibold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.1)))

                    VStack(spacing: compact ? 8 : 12) {
                        ForEach(Array(q.choices.enumerated()), id: \.element.id) { i, c in
                            Button { onPick(c) } label: {
                                HStack(spacing: 10) {
                                    Text(c.emoji).font(.system(size: compact ? 30 : 40))
                                    Text(c.nameCN)
                                        .font(KidUI.kidFont(compact ? 18 : 24, .heavy))
                                    Spacer()
                                    Text(["A", "B", "C"][min(i, 2)])
                                        .font(KidUI.kidFont(compact ? 14 : 18, .heavy))
                                        .foregroundStyle(KidUI.skyTop)
                                        .frame(width: 32, height: 32)
                                        .background(Circle().fill(.white.opacity(0.9)))
                                }
                                .foregroundStyle(.white)
                                .padding(compact ? 12 : 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(choiceColors[min(i, 2)].opacity(feedback == nil ? 0.75 : 0.4))
                                )
                            }
                            .buttonStyle(BounceButtonStyle())
                            .disabled(feedback != nil)
                        }
                    }

                    if let feedback {
                        Text(feedback)
                            .font(KidUI.kidFont(compact ? 16 : 20, .heavy))
                            .foregroundStyle(KidUI.lemon)

                        VStack(spacing: compact ? 8 : 10) {
                            Button(action: onVisitAnswer) {
                                Text("🔭 去看看它")
                                    .font(KidUI.kidFont(compact ? 16 : 20, .heavy))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, compact ? 12 : 16)
                                    .background(RoundedRectangle(cornerRadius: 18).fill(KidUI.sky))
                            }
                            .buttonStyle(BounceButtonStyle())

                            Button(action: onNext) {
                                Text("再来一题 ➡️")
                                    .font(KidUI.kidFont(compact ? 16 : 20, .heavy))
                                    .foregroundStyle(KidUI.skyTop)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, compact ? 12 : 16)
                                    .background(RoundedRectangle(cornerRadius: 18).fill(KidUI.mint))
                            }
                            .buttonStyle(BounceButtonStyle())
                        }
                    }
                }
            }
            .padding(compact ? 14 : 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(hex: "1B0F38").opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(KidUI.candy.opacity(0.7), lineWidth: 3)
                )
        )
    }
}
