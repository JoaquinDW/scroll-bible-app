import SwiftUI
import UIKit
import SwiftData

/// Focus Mode setup (optional, premium): pick apps to keep closed until today's reading is done.
struct FocusSetupView: View {
    @Bindable var profile: UserProfile
    @Environment(Router.self) private var router
    @Environment(\.lang) private var lang
    @State private var focus = FocusService.shared
    @State private var showPicker = false
    @State private var showShield = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    SheepView(state: .reading, size: 120, name: profile.displaySheepName)
                    Text(Copy.focusHeadline(lang))
                        .font(Brand.Fonts.title)
                        .foregroundStyle(Brand.Palette.petrol)
                        .multilineTextAlignment(.center)
                    Text(Copy.focusBody(lang))
                        .font(Brand.Fonts.body)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                        .multilineTextAlignment(.center)

                    if !profile.isPremium {
                        VStack(spacing: 12) {
                            Label(Copy.focusPremium(lang), systemImage: "sparkles")
                                .font(Brand.Fonts.callout)
                                .foregroundStyle(Brand.Palette.petrol)
                            Button(Copy.focusSeePlans(lang)) {
                                router.showFocus = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { router.showPaywall = true }
                            }
                            .buttonStyle(.primary)
                        }
                        .softCard()
                    } else {
                        controls
                    }

                    Button {
                        showShield = true
                    } label: {
                        Label(Copy.focusPreviewShield(lang), systemImage: "eye.fill")
                    }
                    .buttonStyle(.quiet)

                    Text(Copy.focusFootnote(lang))
                        .font(Brand.Fonts.caption)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(Brand.Metrics.padding)
            }
            .background(Brand.Palette.ivory.ignoresSafeArea())
            .navigationTitle(Copy.focusTitle(lang))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Copy.done(lang)) { router.showFocus = false }
                }
            }
        }
        .modifier(FocusPickerModifier(isPresented: $showPicker))
        .fullScreenCover(isPresented: $showShield) {
            ShieldPreviewView(profile: profile) { openSession in
                showShield = false
                if openSession {
                    router.showFocus = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        if let url = URL(string: "\(Brand.urlScheme)://session") { UIApplication.shared.open(url) }
                    }
                }
            }
            .environment(\.lang, lang)
        }
        .onChange(of: focus.selectedCount) { _, _ in focus.sync(with: profile) }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Toggle(Copy.focusToggle(lang), isOn: Binding(
                get: { profile.focusEnabled },
                set: { on in
                    profile.focusEnabled = on
                    if on {
                        Task {
                            await focus.requestAuthorization()
                            // If permission could not be granted, switch back off instead of
                            // leaving a toggle that looks on but blocks nothing.
                            if !focus.isAuthorized { profile.focusEnabled = false }
                            focus.sync(with: profile)
                        }
                    } else {
                        focus.sync(with: profile)
                    }
                }))
                .font(Brand.Fonts.headline)
                .foregroundStyle(Brand.Palette.petrol)
                .tint(Brand.Palette.gold)

            if profile.focusEnabled && focus.isAuthorized {
                Button {
                    showPicker = true
                } label: {
                    Label(focus.selectedCount == 0 ? Copy.focusChoose(lang) : Copy.focusChosen.f(lang, focus.selectedCount),
                          systemImage: "square.grid.2x2.fill")
                }
                .buttonStyle(.quiet)
                Label(profile.status == .doneToday ? Copy.focusOpen(lang) : Copy.focusLocked(lang),
                      systemImage: profile.status == .doneToday ? "lock.open.fill" : "lock.fill")
                    .font(Brand.Fonts.callout)
                    .foregroundStyle(Brand.Palette.petrolSoft)
            } else if let failure = focus.lastFailure {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(Brand.Palette.teal)
                    Text(failure.message(lang))
                        .font(Brand.Fonts.callout)
                        .foregroundStyle(Brand.Palette.petrol)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Brand.Palette.cream.opacity(0.8)))
                if failure == .denied {
                    Button(Copy.focusAllow(lang)) {
                        Task {
                            await focus.requestAuthorization()
                            if focus.isAuthorized { profile.focusEnabled = true }
                            focus.sync(with: profile)
                        }
                    }
                    .buttonStyle(.quiet)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}

/// In-app preview of the shield a blocked app shows. The real shield is drawn by the
/// ShieldConfiguration extension (see /Extensions) using the same copy and colors.
struct ShieldPreviewView: View {
    @Bindable var profile: UserProfile
    /// Called with true when the user taps "Read to unlock".
    var onClose: (Bool) -> Void
    @Environment(\.lang) private var lang
    @Query(sort: \SessionRecord.completedAt) private var records: [SessionRecord]

    private var todaysVerse: SessionCard? {
        guard let journey = ContentStore.shared.journey(profile.currentJourneyID),
              let next = JourneyProgress.nextDay(for: journey, in: records) else { return nil }
        let cards = next.day.cards
        if cards.indices.contains(next.day.keyCard), cards[next.day.keyCard].type == .verse { return cards[next.day.keyCard] }
        return cards.first { $0.type == .verse }
    }

    var body: some View {
        ZStack {
            SceneView(config: SceneConfig(name: "scene_meadow_day_01", lightLevel: max(1, profile.lightLevel), bloom: profile.bloom, milestones: profile.milestones))
                .ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Text(Copy.shieldPreviewTag(lang))
                        .font(Brand.Fonts.caption)
                        .foregroundStyle(Brand.Palette.petrol)
                        .ivoryScrim(12)
                    Spacer()
                    CloseButton { onClose(false) }
                }
                Spacer()
                SheepView(state: .reading, size: 130, name: profile.displaySheepName)
                Text(Copy.shieldTitle.f(lang, profile.displaySheepName))
                    .font(Brand.Fonts.title)
                    .foregroundStyle(Brand.Palette.petrol)
                    .multilineTextAlignment(.center)
                    .ivoryScrim()
                if let verse = todaysVerse {
                    VersePanel(reference: verse.ref?.display(lang) ?? "", text: verse.verseText(profile.translationID), translation: profile.translationID)
                }
                Button {
                    onClose(true)
                } label: {
                    Label(Copy.shieldCTA(lang), systemImage: "book.fill")
                }
                .buttonStyle(.primary)
                .padding(.bottom, 12)
            }
            .padding(.horizontal, Brand.Metrics.padding)
        }
    }
}
