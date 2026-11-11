import SwiftUI
import SwiftData

struct SessionPlan: Hashable {
    let journey: Journey
    let day: JourneyDay
    /// True when today's reading was already done: a calm re-read with a small flat reward.
    let isExtra: Bool
    let isReview: Bool
}

/// Today's session: a short, finite stack of Scripture cards with a quick check every few cards.
/// It always ends. There is no feed.
struct SessionFlow: View {
    @Bindable var profile: UserProfile
    @Environment(Router.self) private var router
    @Environment(\.lang) private var lang
    @Environment(\.modelContext) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \SessionRecord.completedAt) private var records: [SessionRecord]

    @State private var plan: SessionPlan?
    @State private var index = 0
    @State private var drag: CGFloat = 0
    @State private var checkResults: [Int: Bool] = [:]
    @State private var savedCards: Set<Int> = []
    @State private var showUnderstand = false
    @State private var needsAnswerHint = false
    @State private var result: CompletionResult?

    var body: some View {
        ZStack {
            Brand.Palette.ivory.ignoresSafeArea()
            if let plan {
                if let result {
                    CompletionView(profile: profile, plan: plan, result: result) {
                        router.showSession = false
                    }
                    .transition(.opacity)
                } else {
                    reader(plan)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.6), value: result)
        .onAppear(perform: resolvePlan)
    }

    // MARK: Plan

    private func resolvePlan() {
        guard plan == nil, let journey = ContentStore.shared.journey(profile.currentJourneyID) ?? ContentStore.shared.journeys.first(where: { $0.seeded }) else { return }
        let doneToday = profile.status == .doneToday
        if let reviewDay = router.reviewDay, let day = journey.days.first(where: { $0.day == reviewDay }) {
            plan = SessionPlan(journey: journey, day: day, isExtra: doneToday, isReview: true)
        } else if doneToday, let last = records.last(where: { $0.journeyID == journey.id }),
                  let day = journey.days.first(where: { $0.day == last.day }) {
            plan = SessionPlan(journey: journey, day: day, isExtra: true, isReview: true)
        } else if let next = JourneyProgress.nextDay(for: journey, in: records) {
            plan = SessionPlan(journey: journey, day: next.day, isExtra: doneToday, isReview: next.isReview)
        }
        router.reviewDay = nil
    }

    // MARK: Reader

    private func reader(_ plan: SessionPlan) -> some View {
        let cards = plan.day.cards
        let card = cards[min(index, cards.count - 1)]
        return ZStack {
            SceneView(config: sceneConfig(cards), parallax: parallaxValue)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.9), value: index)

            VStack(spacing: 0) {
                topBar(count: cards.count, title: plan.day.title(lang))
                Spacer(minLength: 10)
                ViewThatFits(in: .vertical) {
                    cardView(card, at: index)
                    ScrollView { cardView(card, at: index).padding(.vertical, 8) }
                }
                    .padding(.horizontal, Brand.Metrics.padding)
                    .id(index)
                    .transition(cardTransition)
                    .offset(y: reduceMotion ? 0 : drag * 0.5)
                Spacer(minLength: 10)
                bottomBar(card, isLast: index == cards.count - 1)
            }
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 24)
                .onChanged { drag = $0.translation.height }
                .onEnded { value in
                    if value.translation.height < -70 { goNext(cards) }
                    else if value.translation.height > 70 { goBack() }
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { drag = 0 }
                }
        )
        .sheet(isPresented: $showUnderstand) {
            UnderstandSheet(card: card, translationID: profile.translationID)
                .environment(\.lang, lang)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var cardTransition: AnyTransition {
        reduceMotion ? AnyTransition.opacity : AnyTransition.opacity.combined(with: .scale(scale: 0.96))
    }

    private var parallaxValue: CGFloat {
        let phase = CGFloat((index % 5) - 2) * 0.35
        return phase + max(-1, min(1, drag / 300))
    }

    private func sceneConfig(_ cards: [SessionCard]) -> SceneConfig {
        var name = "scene_meadow_day_01"
        var i = min(index, cards.count - 1)
        while i >= 0 {
            if let scene = cards[i].scene { name = scene; break }
            i -= 1
        }
        return SceneConfig.named(name, lightLevel: max(1, profile.lightLevel), bloom: profile.bloom)
    }

    private func topBar(count: Int, title: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                CloseButton { router.showSession = false }
                HStack(spacing: 5) {
                    ForEach(0..<count, id: \.self) { i in
                        Capsule()
                            .fill(i <= index ? Brand.Palette.gold : Brand.Palette.paper.opacity(0.75))
                            .frame(height: 6)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(Copy.a11yCardProgress.f(lang, index + 1, count)))
                StreakPill(streak: profile.shownStreak, dimmed: profile.isLost)
            }
            Text(title)
                .font(Brand.Fonts.caption)
                .textCase(.uppercase)
                .foregroundStyle(Brand.Palette.petrol)
                .ivoryScrim(12)
        }
        .padding(.horizontal, Brand.Metrics.padding)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func cardView(_ card: SessionCard, at i: Int) -> some View {
        switch card.type {
        case .verse:
            Button {
                showUnderstand = true
            } label: {
                VersePanel(reference: card.ref?.display(lang) ?? "",
                           text: card.verseText(profile.translationID),
                           translation: profile.translationID,
                           rotation: i % 2 == 0 ? -1.2 : 1.0)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(Copy.a11yTapToUnderstand(lang)))
        case .choice:
            ChoiceCheck(question: card.question?.t(lang) ?? "",
                        options: (card.options ?? []).map { $0(lang) },
                        answer: card.answer ?? 0,
                        note: card.note?.t(lang) ?? "",
                        completed: checkResults[i] != nil) { answered(i, $0) }
        case .missingWord:
            if let blank = card.blanks?[profile.translationID] ?? card.blanks?["KJV"] {
                MissingWordCheck(reference: card.ref?.display(lang) ?? "", blank: blank,
                                 completed: checkResults[i] != nil) { answered(i, $0) }
            }
        case .order:
            OrderCheck(reference: card.ref?.display(lang) ?? "",
                       pieces: (card.pieces ?? []).map { $0[profile.translationID] ?? $0["KJV"] ?? "" },
                       completed: checkResults[i] != nil) { answered(i, $0) }
        }
    }

    private func bottomBar(_ card: SessionCard, isLast: Bool) -> some View {
        VStack(spacing: 10) {
            if card.type == .verse {
                HStack(spacing: 10) {
                    Button {
                        toggleSave(card)
                    } label: {
                        Image(systemName: savedCards.contains(index) ? "heart.fill" : "heart")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(savedCards.contains(index) ? Brand.Palette.gentle : Brand.Palette.petrol)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Brand.Palette.paper.opacity(0.92)))
                    }
                    .accessibilityLabel(Text(Copy.saveVerse(lang)))
                    ShareLink(item: shareText(card)) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Brand.Palette.petrol)
                            .frame(width: 50, height: 50)
                            .background(Circle().fill(Brand.Palette.paper.opacity(0.92)))
                    }
                    .accessibilityLabel(Text(Copy.shareVerse(lang)))
                    Button {
                        showUnderstand = true
                    } label: {
                        Label(Copy.understandIt(lang), systemImage: "lightbulb.fill")
                    }
                    .buttonStyle(.quiet)
                }
            } else if needsAnswerHint && checkResults[index] == nil {
                Text(Copy.answerFirst(lang))
                    .font(Brand.Fonts.callout)
                    .foregroundStyle(Brand.Palette.petrol)
                    .ivoryScrim(12)
            }
            Button {
                if let plan { goNext(plan.day.cards) }
            } label: {
                Label(isLast ? Copy.finish(lang) : Copy.continueLabel(lang), systemImage: isLast ? "sun.max.fill" : "chevron.up")
            }
            .buttonStyle(.primary)
            .opacity(card.isCheck && checkResults[index] == nil ? 0.5 : 1)
            .accessibilityHint(Text(Copy.a11ySwipeHint(lang)))
        }
        .padding(.horizontal, Brand.Metrics.padding)
        .padding(.bottom, 12)
    }

    // MARK: Actions

    private func answered(_ i: Int, _ firstTry: Bool) {
        guard checkResults[i] == nil else { return }
        checkResults[i] = firstTry
        needsAnswerHint = false
    }

    private func goNext(_ cards: [SessionCard]) {
        guard index < cards.count else { return }
        if cards[index].isCheck && checkResults[index] == nil {
            withAnimation { needsAnswerHint = true }
            return
        }
        if index == cards.count - 1 {
            finish(cards)
        } else {
            withAnimation(.easeInOut(duration: 0.45)) { index += 1 }
        }
    }

    private func goBack() {
        guard index > 0 else { return }
        withAnimation(.easeInOut(duration: 0.45)) { index -= 1 }
    }

    private func shareText(_ card: SessionCard) -> String {
        "\(card.ref?.display(lang) ?? "")\n\(card.verseText(profile.translationID)) (\(profile.translationID))"
    }

    private func toggleSave(_ card: SessionCard) {
        guard !savedCards.contains(index) else { return }
        savedCards.insert(index)
        context.insert(SavedVerse(reference: card.ref?.display(lang) ?? "", text: card.verseText(profile.translationID), translationID: profile.translationID))
    }

    private func finish(_ cards: [SessionCard]) {
        guard result == nil, let plan else { return }
        var xp = Rules.xpCompletionBonus
        if !plan.isExtra {
            xp += cards.filter { $0.type == .verse }.count * Rules.xpPerVerse
            xp += checkResults.values.reduce(0) { $0 + ($1 ? Rules.xpCheckFirstTry : Rules.xpCheckRetry) }
        }
        let outcome = profile.completeSession(xpEarned: xp, journeyID: plan.journey.id, journeyDay: plan.day.day, isReview: plan.isReview)
        let books = Set(cards.compactMap { $0.ref?.book }).sorted().joined(separator: ",")
        context.insert(SessionRecord(journeyID: plan.journey.id, day: plan.day.day, completedAt: profile.now, xpEarned: xp, bookCodes: books))
        FocusService.shared.sync(with: profile)
        NotificationService.refresh(for: profile)
        result = outcome
    }
}

// MARK: - Understand it

struct UnderstandSheet: View {
    let card: SessionCard
    let translationID: String
    @Environment(\.lang) private var lang

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(card.ref?.display(lang) ?? "")
                        .font(Brand.Fonts.reference)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                    Text(card.verseText(translationID))
                        .font(Brand.Fonts.verse)
                        .foregroundStyle(Brand.Palette.brown)
                        .lineSpacing(5)
                }
                .accessibilityElement(children: .combine)
                StudyAidTag()
                section(Copy.understandPlain(lang), "text.bubble.fill", card.explain?.t(lang))
                section(Copy.understandContext(lang), "building.columns.fill", card.context?.t(lang))
                section(Copy.understandApply(lang), "figure.walk", card.apply?.t(lang))
                Text(Copy.studyAidNote(lang))
                    .font(Brand.Fonts.caption)
                    .foregroundStyle(Brand.Palette.petrolSoft)
            }
            .padding(Brand.Metrics.padding)
            .padding(.top, 10)
        }
        .background(Brand.Palette.ivory)
    }

    @ViewBuilder
    private func section(_ title: String, _ symbol: String, _ text: String?) -> some View {
        if let text {
            VStack(alignment: .leading, spacing: 6) {
                Label(title, systemImage: symbol)
                    .font(Brand.Fonts.headline)
                    .foregroundStyle(Brand.Palette.petrol)
                Text(text)
                    .font(Brand.Fonts.body)
                    .foregroundStyle(Brand.Palette.petrol)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .softCard(padding: 16)
        }
    }
}

// MARK: - Checks

private struct CheckContainer<Content: View>: View {
    var title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StudyAidTag()
            Text(title)
                .font(Brand.Fonts.title)
                .foregroundStyle(Brand.Palette.petrol)
                .fixedSize(horizontal: false, vertical: true)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}

private struct AnswerRow: View {
    var text: String
    var state: Int // 0 idle, 1 correct, 2 not quite

    var body: some View {
        HStack {
            Text(text)
                .font(Brand.Fonts.body)
                .foregroundStyle(Brand.Palette.petrol)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 8)
            if state == 1 { Image(systemName: "checkmark.circle.fill").foregroundStyle(Brand.Palette.correct) }
            if state == 2 { Image(systemName: "arrow.uturn.backward.circle").foregroundStyle(Brand.Palette.gentle) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(state == 1 ? Brand.Palette.correct.opacity(0.22) : (state == 2 ? Brand.Palette.gentle.opacity(0.16) : Brand.Palette.cream.opacity(0.7)))
        )
    }
}

struct ChoiceCheck: View {
    let question: String
    let options: [String]
    let answer: Int
    let note: String
    let completed: Bool
    var onAnswer: (Bool) -> Void

    @Environment(\.lang) private var lang
    @State private var solved = false
    @State private var wrong: Set<Int> = []

    var body: some View {
        CheckContainer(title: question) {
            ForEach(options.indices, id: \.self) { i in
                Button {
                    pick(i)
                } label: {
                    AnswerRow(text: options[i], state: (solved || completed) && i == answer ? 1 : (wrong.contains(i) ? 2 : 0))
                }
                .buttonStyle(.plain)
                .disabled(solved || completed)
            }
            if solved || completed {
                Text(note).font(Brand.Fonts.callout).foregroundStyle(Brand.Palette.petrolSoft)
            } else if !wrong.isEmpty {
                Text(Copy.notQuite(lang)).font(Brand.Fonts.callout).foregroundStyle(Brand.Palette.petrolSoft)
            }
        }
    }

    private func pick(_ i: Int) {
        if i == answer {
            withAnimation { solved = true }
            onAnswer(wrong.isEmpty)
        } else {
            withAnimation { _ = wrong.insert(i) }
        }
    }
}

struct MissingWordCheck: View {
    let reference: String
    let blank: Blank
    let completed: Bool
    var onAnswer: (Bool) -> Void

    @Environment(\.lang) private var lang
    @State private var solved = false
    @State private var wrong: Set<String> = []

    private var done: Bool { solved || completed }

    var body: some View {
        CheckContainer(title: Copy.checkMissingTitle(lang)) {
            VStack(alignment: .leading, spacing: 6) {
                Text(reference)
                    .font(Brand.Fonts.reference)
                    .foregroundStyle(Brand.Palette.petrolSoft)
                Text(done ? blank.prompt.replacingOccurrences(of: "_____", with: blank.answer) : blank.prompt)
                    .font(Brand.Fonts.verse)
                    .foregroundStyle(Brand.Palette.brown)
                    .minimumScaleFactor(0.6)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(blank.options, id: \.self) { option in
                    Button {
                        pick(option)
                    } label: {
                        AnswerRow(text: option, state: done && option == blank.answer ? 1 : (wrong.contains(option) ? 2 : 0))
                    }
                    .buttonStyle(.plain)
                    .disabled(done)
                }
            }
            if !done && !wrong.isEmpty {
                Text(Copy.notQuite(lang)).font(Brand.Fonts.callout).foregroundStyle(Brand.Palette.petrolSoft)
            }
        }
    }

    private func pick(_ option: String) {
        if option == blank.answer {
            withAnimation { solved = true }
            onAnswer(wrong.isEmpty)
        } else {
            withAnimation { _ = wrong.insert(option) }
        }
    }
}

struct OrderCheck: View {
    let reference: String
    /// Pieces in their correct order.
    let pieces: [String]
    let completed: Bool
    var onAnswer: (Bool) -> Void

    @Environment(\.lang) private var lang
    @State private var placed = 0
    @State private var mistakes = 0
    @State private var lastWrong: Int? = nil

    /// A fixed, gentle shuffle so the layout does not jump between renders.
    private var displayOrder: [Int] {
        let n = pieces.count
        guard n > 1 else { return Array(0..<n) }
        return (0..<n).map { ($0 + n - 1) % n }.reversed()
    }

    private var placedCount: Int { completed ? pieces.count : placed }

    var body: some View {
        CheckContainer(title: Copy.checkOrderTitle(lang)) {
            Text(reference)
                .font(Brand.Fonts.reference)
                .foregroundStyle(Brand.Palette.petrolSoft)
            ForEach(displayOrder, id: \.self) { i in
                Button {
                    tap(i)
                } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Text(i < placedCount ? "\(i + 1)" : " ")
                            .font(Brand.Fonts.caption)
                            .foregroundStyle(Brand.Palette.petrol)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(i < placedCount ? Brand.Palette.goldSoft : Brand.Palette.paper))
                            .overlay(Circle().stroke(Brand.Palette.gold.opacity(0.6), lineWidth: 1))
                        Text(pieces[i])
                            .font(Brand.Fonts.callout)
                            .foregroundStyle(Brand.Palette.petrol)
                            .multilineTextAlignment(.leading)
                            .lineLimit(4)
                        Spacer(minLength: 0)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(i < placedCount ? Brand.Palette.correct.opacity(0.2) : (lastWrong == i ? Brand.Palette.gentle.opacity(0.16) : Brand.Palette.cream.opacity(0.7)))
                    )
                }
                .buttonStyle(.plain)
                .disabled(i < placedCount)
            }
            if lastWrong != nil && placedCount < pieces.count {
                Text(Copy.notQuite(lang)).font(Brand.Fonts.callout).foregroundStyle(Brand.Palette.petrolSoft)
            }
        }
    }

    private func tap(_ i: Int) {
        if i == placed {
            withAnimation {
                placed += 1
                lastWrong = nil
            }
            if placed == pieces.count { onAnswer(mistakes == 0) }
        } else {
            mistakes += 1
            withAnimation { lastWrong = i }
        }
    }
}
