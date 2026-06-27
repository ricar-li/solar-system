import SwiftUI

struct ContentView: View {
    @State private var speed: Double = 1.0
    @State private var paused = false
    @State private var showOrbits = true
    @State private var showLabels = true
    @State private var selected: Planet? = nil

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SpaceView(speed: speed, paused: paused,
                      showOrbits: showOrbits, showLabels: showLabels,
                      selectedID: selected?.id,
                      onTapPlanet: { p in
                          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                              selected = p
                          }
                      })
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer()
                planetPicker
                controlBar
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            if let p = selected {
                InfoCard(planet: p,
                         onClose: { withAnimation { selected = nil } },
                         onNext: { withAnimation { selected = nextPlanet(after: p) } })
                    .frame(maxWidth: 460)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.trailing, 20)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }

    // MARK: 顶部标题
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("🪐 太阳系探险")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                Text("Solar System · 点一点星球，发现它的秘密")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.top, 14)
    }

    // MARK: 行星快捷选择条
    private var planetPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(SolarData.all) { p in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { selected = p }
                    } label: {
                        VStack(spacing: 3) {
                            Text(p.emoji).font(.system(size: 26))
                            Text(p.nameCN).font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(selected?.id == p.id ? Color(hex: "2E6BE6").opacity(0.8)
                                                           : Color.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(selected?.id == p.id ? Color(hex: "7FE0FF") : .clear, lineWidth: 2)
                        )
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .padding(.bottom, 10)
    }

    // MARK: 底部控制栏
    private var controlBar: some View {
        HStack(spacing: 18) {
            Button {
                paused.toggle()
            } label: {
                Image(systemName: paused ? "play.circle.fill" : "pause.circle.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.white)
            }

            HStack(spacing: 8) {
                Image(systemName: "tortoise.fill").foregroundStyle(.white.opacity(0.6))
                Slider(value: $speed, in: 0.1...5)
                    .tint(Color(hex: "7FE0FF"))
                    .frame(minWidth: 120)
                Image(systemName: "hare.fill").foregroundStyle(.white.opacity(0.6))
            }

            toggleChip(title: "轨道", systemImage: "circle.dashed", on: $showOrbits)
            toggleChip(title: "名字", systemImage: "textformat", on: $showLabels)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
        )
    }

    private func toggleChip(title: String, systemImage: String, on: Binding<Bool>) -> some View {
        Button { on.wrappedValue.toggle() } label: {
            HStack(spacing: 5) {
                Image(systemName: systemImage)
                Text(title).font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(on.wrappedValue ? Color(hex: "7FE0FF") : .white.opacity(0.5))
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12)
                .fill(on.wrappedValue ? Color(hex: "7FE0FF").opacity(0.15) : Color.white.opacity(0.06)))
        }
    }

    private func nextPlanet(after p: Planet) -> Planet {
        let all = SolarData.all
        guard let i = all.firstIndex(of: p) else { return all[0] }
        return all[(i + 1) % all.count]
    }
}

// MARK: - 信息卡片
struct InfoCard: View {
    let planet: Planet
    let onClose: () -> Void
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(planet.emoji).font(.system(size: 50))
                VStack(alignment: .leading, spacing: 2) {
                    Text(planet.nameCN)
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                    Text("\(planet.nameEN) · \(planet.orderText)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28)).foregroundStyle(.white.opacity(0.6))
                }
            }
            .padding(.bottom, 12)

            Text(planet.blurb)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 14)

            // 数据网格
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                dataPill("📏 直径", planet.diameter)
                dataPill("🌞 距太阳", planet.distance)
                dataPill("🌗 一天", planet.dayLength)
                dataPill("📅 一年", planet.yearLength)
                dataPill("🌙 卫星", planet.moons)
                dataPill("🌡️ 温度", planet.temperature)
            }
            .padding(.bottom, 14)

            Text("✨ 你知道吗")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color(hex: "FFD86B"))
                .padding(.bottom, 6)
            VStack(alignment: .leading, spacing: 7) {
                ForEach(Array(planet.funFacts.enumerated()), id: \.offset) { _, fact in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundStyle(Color(hex: "7FE0FF"))
                        Text(fact).font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.bottom, 16)

            Button(action: onNext) {
                HStack {
                    Text("下一颗星球").font(.system(size: 16, weight: .bold))
                    Image(systemName: "arrow.right.circle.fill")
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color(hex: "2E6BE6")))
            }
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(.ultraThinMaterial)
                .overlay(RoundedRectangle(cornerRadius: 26)
                    .stroke(planet.color.opacity(0.5), lineWidth: 1.5))
        )
        .shadow(color: .black.opacity(0.4), radius: 20, y: 8)
    }

    private func dataPill(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
            Text(value).font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.07)))
    }
}
