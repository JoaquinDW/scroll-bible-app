import SwiftUI

/// The reward moment: the light swells, XP counts up, the sheep is glad.
struct CompletionView: View {
    @Bindable var profile: UserProfile
    let plan: SessionPlan
    let result: CompletionResult
    var onDone: () -> Void

    @Environment(\.lang) private var lang
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glow: CGFloat = 0
    @State private var shownXP = 0
    @State private var sheep: SheepState = .celebrating
    @State private var saved = false

    private var keyCard: SessionCard? {
        let cards = plan.day.cards
        if cards.indices.contains(plan.day.keyCard), cards[plan.day.keyCard].type == .verse { return cards[plan.day.keyCard] }
        return cards.first { $0.type == .verse }
    }

    private var title: String {
        if result.wasLost { return Copy.doneFoundTitle.f(lang, profile.displaySheepName) }
        return result.countedForStreak ? Copy.doneTitle(lang) : Copy.doneExtraTitle(lang)
    }

    var body: some View {
        ZStack {
            SceneView(config: SceneConfig(name: "scene_meadow_day_01",
                                          mood: profile.milestones.contains(.goldenEvening) ? .golden : .day,
                                          lightLevel: max(1, profile.lightLevel), bloom: profile.bloom, milestones: profile.milestones),
                      glow: glow)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    StreakPill(streak: result.newStreak)
                }
                .padding(.horizontal, Brand.Metrics.padding)
                .padding(.top, 8)
                Spacer(minLength: 8)
                SheepView(state: sheep, size: 170, name: profile.displaySheepName)
                    .padding(.bottom, 10)

                ScrollView {
                    VStack(spacing: 14) {
                        Text(title)
                            .font(Brand.Fonts.title)
                            .foregroundStyle(Brand.Palette.petrol)
                            .multilineTextAlignment(.center)
                            .accessibilityAddTraits(.isHeader)
                        Text("+\(shownXP) XP")
                            .font(Brand.Fonts.number)
                            .foregroundStyle(Brand.Palette.gold.blended(with: Brand.Palette.brown, amount: 0.35))
                            .contentTransition(.numericText())
                            .accessibilityLabel(Text(Copy.a11yXP.f(lang, result.xpEarned)))
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(notes, id: \.text) { note in
                                Label(note.text, systemImage: note.symbol)
                                    .font(Brand.Fonts.callout)
                                    .foregroundStyle(Brand.Palette.petrol)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        if let keyCard {
                            VersePanel(reference: keyCard.ref?.display(lang) ?? "",
                                       text: keyCard.verseText(profile.translationID),
                                       translation: profile.translationID, rotation: 0)
                                .padding(.top, 4)
                            HStack(spacing: 10) {
                                Button {
                                    save(keyCard)
                                } label: {
                                    Label(saved ? Copy.saved(lang) : Copy.saveVerse(lang), systemImage: saved ? "heart.fill" : "heart")
                                }
                                .buttonStyle(.quiet)
                                .disabled(saved)
                                ShareLink(item: "\(keyCard.ref?.display(lang) ?? "")\n\(keyCard.verseText(profile.translationID)) (\(profile.translationID))") {
                                    Label(Copy.shareVerse(lang), systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.quiet)
                            }
                        }
                    }
                    .softCard()
                    .padding(.horizontal, Brand.Metrics.padding)
                    .padding(.bottom, 8)
                }
                .scrollBounceBehavior(.basedOnSize)

                Button(Copy.doneCTA(lang), action: onDone)
                    .buttonStyle(.primary)
                    .padding(.horizontal, Brand.Metrics.padding)
                    .padding(.vertical, 12)
            }
        }
        .onAppear(perform: play)
    }

    private struct Note {
        let symbol: String
        let text: String
    }

    private var notes: [Note] {
        var list: [Note] = []
        if result.streakRestored {
            list.append(Note(symbol: "sun.max.fill", text: Copy.doneRestored.f(lang, result.newStreak)))
        } else if result.wasLost {
            list.append(Note(symbol: "sunrise.fill", text: Copy.doneNewLight(lang)))
        } else if result.countedForStreak {
            list.append(Note(symbol: "sun.max.fill", text: Copy.doneStreak.f(lang, result.newStreak)))
        }
        if let level = result.leveledUpTo {
            list.append(Note(symbol: "arrow.up.circle.fill", text: Copy.doneLevel.f(lang, level.name(lang))))
        }
        if let milestone = result.milestone {
            list.append(Note(symbol: milestone.symbol, text: Copy.doneMilestone.f(lang, milestone.title(lang))))
        }
        if let item = result.item {
            list.append(Note(symbol: item.symbol, text: Copy.doneItem.f(lang, profile.displaySheepName, item.name(lang))))
        }
        if result.earnedFreeze {
            list.append(Note(symbol: "snowflake", text: Copy.doneFreeze(lang)))
        }
        if profile.focusEnabled {
            list.append(Note(symbol: "lock.open.fill", text: Copy.doneUnlocked(lang)))
        }
        return list
    }

    private func save(_ card: SessionCard) {
        context.insert(SavedVerse(reference: card.ref?.display(lang) ?? "", text: card.verseText(profile.translationID), translationID: profile.translationID))
        saved = true
    }

    private func play() {
        sheep = result.wasLost ? .returned : .celebrating
        if reduceMotion {
            glow = 0.5
            shownXP = result.xpEarned
            return
        }
        withAnimation(.easeInOut(duration: 1.8)) { glow = 1 }
        withAnimation(.easeInOut(duration: 2.5).delay(2)) { glow = 0.45 }
        Task { @MainActor in
            let steps = 24
            for step in 1...steps {
                try? await Task.sleep(nanoseconds: 45_000_000)
                withAnimation(.easeOut(duration: 0.12)) { shownXP = result.xpEarned * step / steps }
            }
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if sheep == .celebrating { sheep = .happy }
        }
    }
}
