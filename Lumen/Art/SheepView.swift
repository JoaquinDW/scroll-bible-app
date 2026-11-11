import SwiftUI

/// Every state of the companion. Each one is a separate swappable asset.
enum SheepState: String, CaseIterable, Identifiable {
    case idle, happy, celebrating, reading, sleepy, searching, returned
    var id: String { rawValue }
    var asset: String { "sheep_\(rawValue)" }

    var label: LText {
        switch self {
        case .idle: return LText("resting in the meadow", "descansando en el prado")
        case .happy: return LText("smiling up at the light", "sonriendo hacia la luz")
        case .celebrating: return LText("hopping with joy", "saltando de alegría")
        case .reading: return LText("reading a scroll", "leyendo un rollo")
        case .sleepy: return LText("getting sleepy", "con sueño")
        case .searching: return LText("a little lost on the hillside", "un poco perdida en la colina")
        case .returned: return LText("home again and relieved", "de vuelta en casa, aliviada")
        }
    }
}

/// The little sheep. Shows `sheep_<state>` from the asset catalog when present,
/// otherwise a soft painted placeholder with the same silhouette.
struct SheepView: View {
    var state: SheepState = .idle
    var size: CGFloat = 160
    var name: String? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.lang) private var lang
    @State private var breathe = false
    @State private var hop = false
    @State private var twitch = false

    var body: some View {
        ArtLayer(name: state.asset, contentMode: .fit) {
            SheepPlaceholder(state: state, twitch: twitch)
                .frame(width: 120, height: 110)
                .scaleEffect(size / 120)
                .frame(width: size, height: size * 0.92)
        }
        .frame(width: size, height: size * 0.92)
        .scaleEffect(x: 1, y: breathe ? 1.025 : 1, anchor: .bottom)
        .offset(y: hop ? -size * 0.12 : 0)
        .accessibilityElement()
        .accessibilityLabel(Text("\(name ?? Copy.sheepGeneric(lang)), \(state.label(lang))"))
        .accessibilityAddTraits(.isImage)
        .onAppear { start() }
        .onChange(of: state) { _, _ in start() }
    }

    private func start() {
        hop = false
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { breathe = true }
        withAnimation(.easeInOut(duration: 0.5).delay(2).repeatForever(autoreverses: true)) { twitch = true }
        if state == .celebrating {
            withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) { hop = true }
        }
    }
}

/// Placeholder painting, drawn in a 120 x 110 box.
struct SheepPlaceholder: View {
    var state: SheepState
    var twitch: Bool

    private var dim: Bool { state == .searching || state == .sleepy }
    private var eyesClosed: Bool { state != .searching && state != .reading }
    private var headTilt: Double {
        switch state {
        case .happy, .celebrating: return -14
        case .reading: return 12
        case .sleepy: return 8
        case .searching: return -4
        case .returned: return 6
        case .idle: return 0
        }
    }

    var body: some View {
        ZStack {
            // Soft ground shadow
            Ellipse().fill(Brand.Palette.brown.opacity(0.12)).frame(width: 78, height: 10).position(x: 58, y: 104)

            // Legs
            ForEach(0..<4, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Brand.Palette.face)
                    .frame(width: 7, height: 22)
                    .position(x: [34, 46, 66, 78][i], y: 92)
            }

            // Wool body, loose overlapping strokes with a golden rim
            wool
                .shadow(color: Brand.Palette.gold.opacity(dim ? 0.15 : 0.75), radius: 2.5, x: 0, y: -1)

            // Head
            head
                .rotationEffect(.degrees(headTilt), anchor: UnitPoint(x: 0.4, y: 0.7))
                .position(x: 84, y: 44)

            if state == .reading {
                // A small scroll
                RoundedRectangle(cornerRadius: 3)
                    .fill(Brand.Palette.paper)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(Brand.Palette.gold, lineWidth: 1))
                    .frame(width: 26, height: 18)
                    .rotationEffect(.degrees(-8))
                    .position(x: 100, y: 78)
            }
            if state == .sleepy {
                Text("z z")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(Brand.Palette.paper.opacity(0.9))
                    .position(x: 106, y: 16)
            }
            if state == .returned {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Brand.Palette.blush)
                    .position(x: 106, y: 18)
            }
        }
        .frame(width: 120, height: 110)
        .saturation(dim ? 0.75 : 1)
        .brightness(dim ? -0.06 : 0)
    }

    private var wool: some View {
        let puffs: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
            (38, 62, 21), (56, 54, 23), (74, 62, 20), (46, 74, 19), (66, 76, 19), (28, 72, 14), (58, 66, 22),
        ]
        return ZStack {
            ForEach(0..<puffs.count, id: \.self) { i in
                Circle()
                    .fill(RadialGradient(colors: [Brand.Palette.wool, Brand.Palette.woolShade],
                                         center: UnitPoint(x: 0.4, y: 0.3), startRadius: 2, endRadius: puffs[i].r * 1.5))
                    .frame(width: puffs[i].r * 2, height: puffs[i].r * 2)
                    .position(x: puffs[i].x, y: puffs[i].y)
            }
            // Tail
            Circle().fill(Brand.Palette.wool).frame(width: 11, height: 11).position(x: 17, y: 66)
        }
        .frame(width: 120, height: 110)
    }

    private var head: some View {
        ZStack {
            // Ears with pink inside
            ear.rotationEffect(.degrees(twitch ? -28 : -20)).position(x: 6, y: 20)
            ear.rotationEffect(.degrees(24)).position(x: 44, y: 18)
            // Top tuft
            Circle().fill(Brand.Palette.wool).frame(width: 22, height: 18).position(x: 24, y: 9)
                .shadow(color: Brand.Palette.gold.opacity(0.6), radius: 1.5, y: -1)
            // Face
            Ellipse().fill(Brand.Palette.face).frame(width: 32, height: 36).position(x: 25, y: 26)
            // Eyes
            if eyesClosed {
                SmileArc().stroke(Brand.Palette.nose, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                    .frame(width: 7, height: 3).rotationEffect(.degrees(180)).position(x: 18, y: 24)
                SmileArc().stroke(Brand.Palette.nose, style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
                    .frame(width: 7, height: 3).rotationEffect(.degrees(180)).position(x: 32, y: 24)
            } else {
                Circle().fill(Brand.Palette.nose).frame(width: 3.5, height: 3.5).position(x: 18, y: 24)
                Circle().fill(Brand.Palette.nose).frame(width: 3.5, height: 3.5).position(x: 32, y: 24)
            }
            // Nose and gentle smile
            Ellipse().fill(Brand.Palette.nose).frame(width: 6, height: 4).position(x: 25, y: 33)
            SmileArc().stroke(Brand.Palette.nose, style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
                .frame(width: 10, height: state == .searching ? 1.5 : 4).position(x: 25, y: 38)
        }
        .frame(width: 50, height: 46)
    }

    private var ear: some View {
        Ellipse()
            .fill(Brand.Palette.face)
            .overlay(Ellipse().fill(Brand.Palette.earPink).padding(2.5))
            .frame(width: 18, height: 9)
    }
}

/// A shallow upward-curving arc, used for the smile and (flipped) the closed eyes.
struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 2))
        return p
    }
}
