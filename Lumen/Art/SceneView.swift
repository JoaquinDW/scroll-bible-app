import SwiftUI

/// The layered world: sky, clouds, light, sea, hills, meadow, flowers.
/// Each layer is an `ArtLayer`, so final paintings replace placeholders one by one.
struct SceneView: View {
    var config: SceneConfig
    /// Small horizontal shift (-1...1) used for parallax while swiping.
    var parallax: CGFloat = 0
    /// 0...1 extra glow, used for reward moments.
    var glow: CGFloat = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false
    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                if Art.exists(config.name) {
                    paintedScene(w: w, h: h)
                } else {
                    layeredScene(w: w, h: h)
                }

                if config.milestones.contains(.goldenEvening), !isDark {
                    LinearGradient(colors: [Brand.Palette.gold.opacity(0.22), .clear], startPoint: .top, endPoint: .center)
                        .blendMode(.softLight)
                        .allowsHitTesting(false)
                }

                // Reward bloom
                RadialGradient(colors: [Brand.Palette.goldSoft.opacity(0.75 * Double(glow)), .clear],
                               center: UnitPoint(x: 0.5, y: 0.55), startRadius: 10, endRadius: w * 0.8)
                    .allowsHitTesting(false)

                if !Art.exists(config.name) {
                    ArtLayer(name: Art.paperGrain) { PaperGrainPlaceholder() }
                        .blendMode(.multiply)
                        .opacity(0.5)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: w, height: h)
            .clipped()
        }
        .accessibilityHidden(true)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) { drift = true }
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    /// A finished painting (scene_meadow_day_01...) replaces the placeholder layers.
    /// The light beam stays on top so the streak still brightens the scene, and
    /// milestone unlocks show once their own paintings are in the catalog.
    @ViewBuilder
    private func paintedScene(w: CGFloat, h: CGFloat) -> some View {
        Image(config.name)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: w * 1.1, height: h)
            .offset(x: parallax * 10)

        if config.milestones.contains(.rainbow), config.mood != .night, Art.exists(Art.milestoneRainbow) {
            Image(Art.milestoneRainbow)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: w * 1.1, height: h * 0.5)
                .position(x: w * 0.5 + parallax * 10, y: h * 0.32)
                .opacity(config.mood == .dusk ? 0.25 : 0.6)
                .blendMode(.softLight)
        }

        if config.lightLevel > 0 {
            ArtLayer(name: Art.lightBeam(config.lightLevel)) {
                LightBeamPlaceholder(level: config.lightLevel)
            }
            .frame(width: w, height: h * 0.85)
            .position(x: w * 0.5, y: h * 0.42)
            .opacity((pulse ? 0.7 : 0.55) + Double(glow) * 0.3)
            .scaleEffect(x: 1 + glow * 0.35, y: 1, anchor: .top)
            .blendMode(.softLight)
            .allowsHitTesting(false)
        }

        if config.milestones.contains(.floweringTree), Art.exists(Art.milestoneFloweringTree) {
            Image(Art.milestoneFloweringTree)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: w * 0.36, height: h * 0.3)
                .position(x: w * 0.14 + parallax * 38, y: h * 0.6)
        }

        if config.milestones.contains(.stillPond), Art.exists(Art.milestoneStillPond) {
            Image(Art.milestoneStillPond)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: w * 0.42, height: h * 0.08)
                .position(x: w * 0.78 + parallax * 44, y: h * 0.8)
        }
    }

    @ViewBuilder
    private func layeredScene(w: CGFloat, h: CGFloat) -> some View {
            sky
                .frame(width: w * 1.2, height: h)
                .offset(x: parallax * 6)

            if config.milestones.contains(.rainbow), config.mood != .night {
                ArtLayer(name: Art.milestoneRainbow, contentMode: .fit) { RainbowPlaceholder() }
                    .frame(width: w * 1.1, height: h * 0.5)
                    .position(x: w * 0.5 + parallax * 10, y: h * 0.42)
                    .opacity(config.mood == .dusk ? 0.25 : 0.55)
            }

            clouds(w: w, h: h)
                .offset(x: parallax * 14)

            if config.lightLevel > 0 {
                ArtLayer(name: Art.lightBeam(config.lightLevel)) {
                    LightBeamPlaceholder(level: config.lightLevel)
                }
                .frame(width: w, height: h * 0.85)
                .position(x: w * 0.5, y: h * 0.42)
                .opacity((pulse ? 1.0 : 0.82) + Double(glow) * 0.3)
                .scaleEffect(x: 1 + glow * 0.35, y: 1, anchor: .top)
                .blendMode(.softLight)
                .allowsHitTesting(false)
            }

            if config.terrain == .sea || config.terrain == .meadow {
                ArtLayer(name: Art.seaMist) { SeaPlaceholder(mood: config.mood) }
                    .frame(width: w * 1.3, height: h * (config.terrain == .sea ? 0.26 : 0.14))
                    .position(x: w * 0.5 + parallax * 22, y: h * (config.terrain == .sea ? 0.55 : 0.56))
            }

            ArtLayer(name: Art.hillsFar) {
                HillShape(peaks: config.terrain == .hills || config.terrain == .valley ? 0.55 : 0.25, phase: 0.3)
                    .fill(groundColors.far)
            }
            .frame(width: w * 1.3, height: h * 0.34)
            .position(x: w * 0.5 + parallax * 30, y: h * (config.terrain == .sea ? 0.74 : 0.66))

            if config.milestones.contains(.floweringTree) {
                ArtLayer(name: Art.milestoneFloweringTree, contentMode: .fit) { TreePlaceholder(dim: isDark) }
                    .frame(width: w * 0.36, height: h * 0.3)
                    .position(x: w * 0.16 + parallax * 38, y: h * 0.6)
            }

            ArtLayer(name: Art.ground(config.terrain, config.mood)) {
                HillShape(peaks: 0.12, phase: 1.4)
                    .fill(LinearGradient(colors: [groundColors.near, groundColors.nearDeep], startPoint: .top, endPoint: .bottom))
            }
            .frame(width: w * 1.3, height: h * 0.46)
            .position(x: w * 0.5 + parallax * 44, y: h * 0.8)

            if config.milestones.contains(.stillPond) {
                ArtLayer(name: Art.milestoneStillPond, contentMode: .fit) {
                    Ellipse().fill(LinearGradient(colors: [Brand.Palette.aqua, Brand.Palette.teal.opacity(0.7)], startPoint: .top, endPoint: .bottom))
                }
                .frame(width: w * 0.42, height: h * 0.05)
                .position(x: w * 0.76 + parallax * 44, y: h * 0.78)
                .opacity(isDark ? 0.5 : 0.9)
            }

            ArtLayer(name: Art.wildflowers) {
                FlowersPlaceholder(count: config.bloom, sway: drift, dim: isDark, sand: config.terrain == .desert)
            }
            .frame(width: w, height: h * 0.4)
            .position(x: w * 0.5 + parallax * 52, y: h * 0.82)

            if config.bloom > 12, !isDark {
                ArtLayer(name: Art.butterflies) { ButterfliesPlaceholder(flutter: drift) }
                    .frame(width: w, height: h * 0.3)
                    .position(x: w * 0.5, y: h * 0.62)
            }
    }

    private var isDark: Bool { config.mood == .night || config.mood == .dusk }

    private var sky: some View {
        let name: String
        let colors: [Color]
        switch config.mood {
        case .day:
            name = Art.skyDay
            colors = [Brand.Palette.aqua, Color(hex: 0xF9E6D2), Brand.Palette.blush]
        case .dawn:
            name = Art.skyDawn
            colors = [Color(hex: 0xF7DCC8), Color(hex: 0xFAEACB), Color(hex: 0xD3E8E1)]
        case .golden:
            name = Art.skyGolden
            colors = [Color(hex: 0xF4D595), Color(hex: 0xF8DFBB), Color(hex: 0xF3CDBB)]
        case .dusk:
            name = Art.skyDusk
            colors = [Brand.Palette.dusk, Color(hex: 0xB495AB), Color(hex: 0xE6B9A5)]
        case .night:
            name = Art.skyNight
            colors = [Brand.Palette.night, Color(hex: 0x4D5A80), Color(hex: 0x8C89A8)]
        }
        return ArtLayer(name: name) {
            ZStack {
                LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
                if config.mood == .night { StarsPlaceholder() }
            }
        }
    }

    private func clouds(w: CGFloat, h: CGFloat) -> some View {
        let tint: Color = isDark ? Color(hex: 0xC9BFD3).opacity(0.45) : Brand.Palette.paper.opacity(0.85)
        return ArtLayer(name: Art.cloudsSoft) {
            ZStack {
                CloudPlaceholder(tint: tint)
                    .frame(width: w * 0.62, height: h * 0.11)
                    .position(x: w * 0.2 + (drift ? 16 : -10), y: h * 0.13)
                CloudPlaceholder(tint: tint.opacity(0.8))
                    .frame(width: w * 0.5, height: h * 0.09)
                    .position(x: w * 0.84 + (drift ? -14 : 8), y: h * 0.2)
                CloudPlaceholder(tint: tint)
                    .frame(width: w * 0.7, height: h * 0.1)
                    .position(x: w * 0.5 + (drift ? 8 : -8), y: h * 0.33)
            }
        }
        .frame(width: w, height: h)
    }

    private var groundColors: (far: Color, near: Color, nearDeep: Color) {
        switch (config.terrain, config.mood) {
        case (.desert, .night), (.desert, .dusk):
            return (Color(hex: 0x8D7F86), Color(hex: 0x9C8A7C), Color(hex: 0x7C6C66))
        case (.desert, _):
            return (Color(hex: 0xE3C9A3), Color(hex: 0xEBD3A6), Color(hex: 0xD9B983))
        case (_, .night):
            return (Color(hex: 0x4C6470), Color(hex: 0x46635F), Color(hex: 0x38504F))
        case (_, .dusk):
            return (Color(hex: 0x70838C), Color(hex: 0x6C8A7C), Color(hex: 0x557166))
        case (_, .golden):
            return (Color(hex: 0xBFC79A), Color(hex: 0xB9C98F), Color(hex: 0x93AE74))
        default:
            return (Brand.Palette.sage.opacity(0.9), Brand.Palette.sage, Brand.Palette.grass)
        }
    }
}

// MARK: - Placeholders (replace with painted assets)

struct HillShape: Shape {
    var peaks: CGFloat
    var phase: CGFloat

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let top = rect.height * 0.35
        p.move(to: CGPoint(x: 0, y: rect.height))
        p.addLine(to: CGPoint(x: 0, y: top))
        let steps = 24
        for i in 0...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let y = top - sin(t * .pi * 2.2 + phase) * rect.height * peaks * 0.5 - sin(t * .pi * 5 + phase * 2) * rect.height * peaks * 0.12
            p.addLine(to: CGPoint(x: t * rect.width, y: y))
        }
        p.addLine(to: CGPoint(x: rect.width, y: rect.height))
        p.closeSubpath()
        return p
    }
}

struct LightBeamPlaceholder: View {
    let level: Int

    var body: some View {
        GeometryReader { geo in
            let spread = 0.2 + CGFloat(level) * 0.11
            Path { p in
                let w = geo.size.width, h = geo.size.height
                p.move(to: CGPoint(x: w * 0.44, y: 0))
                p.addLine(to: CGPoint(x: w * 0.56, y: 0))
                p.addLine(to: CGPoint(x: w * (0.5 + spread), y: h))
                p.addLine(to: CGPoint(x: w * (0.5 - spread), y: h))
                p.closeSubpath()
            }
            .fill(LinearGradient(colors: [Brand.Palette.goldSoft.opacity(0.25 + Double(level) * 0.12), Brand.Palette.goldSoft.opacity(0.05)],
                                 startPoint: .top, endPoint: .bottom))
            .blur(radius: 18)
        }
    }
}

struct CloudPlaceholder: View {
    var tint: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                Ellipse().fill(tint).frame(width: w * 0.6, height: h * 0.8).position(x: w * 0.35, y: h * 0.6)
                Ellipse().fill(tint).frame(width: w * 0.5, height: h).position(x: w * 0.55, y: h * 0.5)
                Ellipse().fill(tint).frame(width: w * 0.45, height: h * 0.7).position(x: w * 0.75, y: h * 0.65)
            }
            .blur(radius: 10)
        }
    }
}

struct SeaPlaceholder: View {
    var mood: SceneMood

    var body: some View {
        let dark = mood == .night || mood == .dusk
        ZStack {
            LinearGradient(colors: dark ? [Color(hex: 0x7C8FA8), Color(hex: 0x5F7890)] : [Brand.Palette.aqua, Brand.Palette.teal.opacity(0.75)],
                           startPoint: .top, endPoint: .bottom)
            VStack(spacing: 9) {
                ForEach(0..<4, id: \.self) { i in
                    Capsule()
                        .fill(Brand.Palette.paper.opacity(dark ? 0.12 : 0.35))
                        .frame(height: 2)
                        .padding(.horizontal, CGFloat(30 + i * 34))
                }
            }
        }
        .blur(radius: 1.5)
    }
}

struct RainbowPlaceholder: View {
    private let bands: [Color] = [Brand.Palette.blush, Brand.Palette.peach, Brand.Palette.goldSoft, Brand.Palette.sage, Brand.Palette.aqua]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(Array(bands.enumerated()), id: \.offset) { i, color in
                    Circle()
                        .trim(from: 0.5, to: 1)
                        .stroke(color, lineWidth: 9)
                        .frame(width: geo.size.width * 0.9 - CGFloat(i) * 18, height: geo.size.width * 0.9 - CGFloat(i) * 18)
                        .position(x: geo.size.width / 2, y: geo.size.height)
                }
            }
            .blur(radius: 3)
        }
    }
}

struct TreePlaceholder: View {
    var dim: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 4).fill(Color(hex: 0x8A6E55).opacity(dim ? 0.6 : 1))
                    .frame(width: w * 0.08, height: h * 0.45).position(x: w * 0.5, y: h * 0.76)
                Circle().fill(Brand.Palette.blush.opacity(dim ? 0.45 : 0.95)).frame(width: w * 0.6).position(x: w * 0.38, y: h * 0.4)
                Circle().fill(Brand.Palette.peach.opacity(dim ? 0.4 : 0.9)).frame(width: w * 0.55).position(x: w * 0.62, y: h * 0.36)
                Circle().fill(Brand.Palette.blush.opacity(dim ? 0.4 : 0.85)).frame(width: w * 0.5).position(x: w * 0.5, y: h * 0.24)
            }
        }
    }
}

struct FlowersPlaceholder: View {
    var count: Int
    var sway: Bool
    var dim: Bool
    var sand: Bool

    var body: some View {
        GeometryReader { geo in
            let palette: [Color] = [Brand.Palette.paper, Brand.Palette.blush, Brand.Palette.goldSoft, Brand.Palette.peach]
            ZStack {
                ForEach(0..<max(0, count), id: \.self) { i in
                    let spot = FlowersPlaceholder.spot(i)
                    VStack(spacing: 0) {
                        Circle()
                            .fill(palette[i % palette.count].opacity(dim ? 0.55 : 1))
                            .frame(width: 7 + CGFloat(i % 3) * 2, height: 7 + CGFloat(i % 3) * 2)
                            .overlay(Circle().fill(Brand.Palette.gold.opacity(dim ? 0.4 : 0.9)).frame(width: 3, height: 3))
                        Capsule()
                            .fill((sand ? Color(hex: 0xA9A06C) : Brand.Palette.deepGrass).opacity(dim ? 0.5 : 0.9))
                            .frame(width: 1.5, height: 10 + CGFloat(i % 4) * 4)
                    }
                    .rotationEffect(.degrees(sway ? 3 : -3), anchor: .bottom)
                    .position(x: spot.x * geo.size.width, y: (0.25 + spot.y * 0.7) * geo.size.height)
                }
            }
        }
    }

    static func spot(_ index: Int) -> (x: CGFloat, y: CGFloat) {
        var random = SeededRandom(seed: index + 7)
        var x = CGFloat(random.next())
        let y = CGFloat(random.next())
        // Keep the center clear for the sheep.
        if x > 0.36 && x < 0.64 { x = x < 0.5 ? x - 0.3 : x + 0.3 }
        return (x, y)
    }
}

struct ButterfliesPlaceholder: View {
    var flutter: Bool

    var body: some View {
        GeometryReader { geo in
            let xs: [CGFloat] = [0.18, 0.78, 0.66]
            let ys: [CGFloat] = [0.5, 0.35, 0.7]
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: "leaf.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(i == 1 ? Brand.Palette.blush : Brand.Palette.goldSoft)
                    .rotationEffect(.degrees(flutter ? 20 : -25))
                    .position(x: geo.size.width * xs[i] + (flutter ? 10 : -8),
                              y: geo.size.height * ys[i] + (flutter ? -8 : 6))
            }
        }
    }
}

struct StarsPlaceholder: View {
    var body: some View {
        Canvas { context, size in
            var random = SeededRandom(seed: 99)
            for _ in 0..<40 {
                let x = CGFloat(random.next()) * size.width
                let y = CGFloat(random.next()) * size.height * 0.5
                let r = 0.6 + CGFloat(random.next()) * 1.2
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                             with: .color(Brand.Palette.paper.opacity(0.7)))
            }
        }
    }
}

/// Faint speckle that hints at paper grain until the real texture arrives.
struct PaperGrainPlaceholder: View {
    var body: some View {
        Canvas { context, size in
            var random = SeededRandom(seed: 3)
            for _ in 0..<420 {
                let x = CGFloat(random.next()) * size.width
                let y = CGFloat(random.next()) * size.height
                context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 1.4, height: 1.4)),
                             with: .color(Brand.Palette.brown.opacity(0.05)))
            }
        }
    }
}
