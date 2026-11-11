import SwiftUI
import UIKit

// MARK: - Language environment

private struct LangKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .en
}

extension EnvironmentValues {
    /// The language chosen in onboarding or Settings.
    var lang: AppLanguage {
        get { self[LangKey.self] }
        set { self[LangKey.self] = newValue }
    }
}

// MARK: - Router

/// App-wide navigation state. Deep links (lumen://session) land here.
@Observable
final class Router {
    var tab: Int = 0
    var showSession = false
    /// When set, the session opens this specific day as a review.
    var reviewDay: Int? = nil
    var showLostSheep = false
    var showSettings = false
    var showFocus = false
    var showPaywall = false
}

// MARK: - Buttons

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.Fonts.button)
            .foregroundStyle(Brand.Palette.petrol)
            .frame(maxWidth: .infinity, minHeight: 54)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: Brand.Metrics.corner, style: .continuous)
                    .fill(LinearGradient(colors: [Brand.Palette.goldSoft, Brand.Palette.gold], startPoint: .top, endPoint: .bottom))
            )
            .shadow(color: Brand.Palette.gold.opacity(0.35), radius: 10, y: 5)
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Brand.Fonts.button)
            .foregroundStyle(Brand.Palette.petrol)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 18)
            .background(
                RoundedRectangle(cornerRadius: Brand.Metrics.corner, style: .continuous)
                    .fill(Brand.Palette.paper.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: Brand.Metrics.corner, style: .continuous)
                    .stroke(Brand.Palette.petrol.opacity(0.18), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: QuietButtonStyle { QuietButtonStyle() }
}

// MARK: - Surfaces

struct SoftCard: ViewModifier {
    var padding: CGFloat = Brand.Metrics.padding

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: Brand.Metrics.cardCorner, style: .continuous)
                    .fill(Brand.Palette.paper)
            )
            .shadow(color: Brand.Palette.brown.opacity(0.08), radius: Brand.Metrics.shadowRadius, y: 6)
    }
}

extension View {
    func softCard(padding: CGFloat = Brand.Metrics.padding) -> some View {
        modifier(SoftCard(padding: padding))
    }

    /// Soft ivory scrim so text stays readable over an illustration.
    func ivoryScrim(_ corner: CGFloat = 16) -> some View {
        padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: corner, style: .continuous).fill(Brand.Palette.ivory.opacity(0.88)))
    }
}

// MARK: - Streak pill (the light)

struct StreakPill: View {
    var streak: Int
    var dimmed: Bool = false
    @Environment(\.lang) private var lang

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: dimmed ? "sun.haze.fill" : "sun.max.fill")
                .foregroundStyle(dimmed ? Brand.Palette.petrolSoft : Brand.Palette.gold)
            Text("\(streak)")
                .font(Brand.Fonts.headline)
                .foregroundStyle(Brand.Palette.petrol)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Capsule().fill(Brand.Palette.cream))
        .overlay(Capsule().stroke(Brand.Palette.gold.opacity(0.45), lineWidth: 1))
        .shadow(color: Brand.Palette.brown.opacity(0.08), radius: 6, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(dimmed ? Copy.a11yStreakDim.f(lang, streak) : Copy.a11yStreak.f(lang, streak)))
    }
}

// MARK: - Verse card

/// Cream paper panel with a thin soft-gold border. Reference first, then the verse.
struct VersePanel: View {
    var reference: String
    var text: String
    var translation: String? = nil
    var large: Bool = false
    var rotation: Double = -1.2

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(reference)
                .font(Brand.Fonts.reference)
                .foregroundStyle(Brand.Palette.gold.blended(with: Brand.Palette.brown))
            Text(text)
                .font(large ? Brand.Fonts.verseLarge : Brand.Fonts.verse)
                .foregroundStyle(Brand.Palette.brown)
                .lineSpacing(5)
                .minimumScaleFactor(0.55)
            if let translation {
                Text(translation)
                    .font(Brand.Fonts.caption)
                    .foregroundStyle(Brand.Palette.petrolSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Brand.Palette.paper))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Brand.Palette.gold.opacity(0.7), lineWidth: 1.2)
                .padding(6)
        )
        .shadow(color: Brand.Palette.brown.opacity(0.14), radius: 16, y: 8)
        .rotationEffect(.degrees(rotation))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(reference). \(text)"))
    }
}

extension Color {
    /// Simple blend that works on iOS 17 (Color.mix arrived in iOS 18).
    func blended(with other: Color, amount: Double = 0.5) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let t = CGFloat(amount)
        return Color(.sRGB, red: Double(r1 + (r2 - r1) * t), green: Double(g1 + (g2 - g1) * t), blue: Double(b1 + (b2 - b1) * t), opacity: 1)
    }
}

// MARK: - Small pieces

struct SectionTitle: View {
    var text: String

    var body: some View {
        Text(text)
            .font(Brand.Fonts.title)
            .foregroundStyle(Brand.Palette.petrol)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(.isHeader)
    }
}

struct ProgressBar: View {
    var value: Double
    var tint: Color = Brand.Palette.gold

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.Palette.cream)
                Capsule().fill(tint).frame(width: max(8, geo.size.width * min(1, max(0, value))))
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

/// Small "Study aid" tag for generated explanations and questions.
struct StudyAidTag: View {
    @Environment(\.lang) private var lang

    var body: some View {
        Label(Copy.studyAid(lang), systemImage: "sparkles")
            .font(Brand.Fonts.caption)
            .foregroundStyle(Brand.Palette.petrolSoft)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Brand.Palette.cream))
    }
}

struct CloseButton: View {
    var action: () -> Void
    @Environment(\.lang) private var lang

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Brand.Palette.petrol)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Brand.Palette.paper.opacity(0.9)))
        }
        .accessibilityLabel(Text(Copy.close(lang)))
    }
}
