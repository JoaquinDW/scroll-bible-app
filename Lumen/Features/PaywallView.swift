import SwiftUI

/// Soft paywall. The daily session stays free and "Continue for free" is always one tap away.
/// Purchases are placeholders: wire StoreKit products where `choose` is called.
struct PaywallView: View {
    @Bindable var profile: UserProfile
    var onClose: () -> Void
    @Environment(\.lang) private var lang
    @State private var annual = true

    var body: some View {
        ZStack {
            Brand.Palette.ivory.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        Spacer()
                        CloseButton(action: onClose)
                    }
                    SheepView(state: .happy, size: 130, name: profile.displaySheepName)
                    Text(Copy.paywallTitle.f(lang, Brand.name))
                        .font(Brand.Fonts.title)
                        .foregroundStyle(Brand.Palette.petrol)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Label(Copy.paywallFree(lang), systemImage: "checkmark.seal.fill")
                        .font(Brand.Fonts.callout)
                        .foregroundStyle(Brand.Palette.deepGrass)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(Brand.Palette.sage.opacity(0.3)))

                    VStack(alignment: .leading, spacing: 14) {
                        PlanRow(symbol: "lock.shield.fill", text: Copy.paywallBenefitFocus(lang))
                        PlanRow(symbol: "map.fill", text: Copy.paywallBenefitJourneys(lang))
                        PlanRow(symbol: "person.3.fill", text: Copy.paywallBenefitFlock(lang))
                        PlanRow(symbol: "books.vertical.fill", text: Copy.paywallBenefitStudy(lang))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .softCard()

                    VStack(spacing: 12) {
                        OptionRow(title: Copy.planAnnual(lang), subtitle: Copy.planAnnualPrice.f(lang, Brand.Pricing.annual),
                                  symbol: "sun.max.fill", selected: annual) { annual = true }
                        OptionRow(title: Copy.planWeekly(lang), subtitle: Copy.planWeeklyPrice.f(lang, Brand.Pricing.weekly),
                                  symbol: "calendar", selected: !annual) { annual = false }
                    }

                    Button(Copy.paywallCTA(lang)) { choose() }
                        .buttonStyle(.primary)
                    Button(Copy.paywallNotNow(lang), action: onClose)
                        .buttonStyle(.quiet)
                    Text(Copy.paywallFinePrint(lang))
                        .font(Brand.Fonts.caption)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(Brand.Metrics.padding)
            }
        }
    }

    private func choose() {
        // Placeholder purchase. Replace with a StoreKit 2 purchase of the selected product.
        profile.isPremium = true
        onClose()
    }
}
