import SwiftUI
import SwiftData

/// The sheep in its meadow under today's light, with the next action front and center.
struct HomeView: View {
    @Bindable var profile: UserProfile
    @Environment(Router.self) private var router
    @Environment(\.lang) private var lang
    @Query(sort: \SessionRecord.completedAt) private var records: [SessionRecord]

    private var journey: Journey? { ContentStore.shared.journey(profile.currentJourneyID) }
    private var next: (day: JourneyDay, isReview: Bool)? {
        journey.flatMap { JourneyProgress.nextDay(for: $0, in: records) }
    }

    private var isNight: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 21 || hour < 5
    }

    private var sceneConfig: SceneConfig {
        var config = SceneConfig(name: "scene_meadow_day_01", lightLevel: profile.lightLevel, bloom: profile.bloom, milestones: profile.milestones)
        switch profile.status {
        case .lost:
            config.mood = .dusk
            config.terrain = .hills
        case .doneToday:
            config.mood = isNight ? .night : (profile.milestones.contains(.goldenEvening) ? .golden : .day)
        case .ready:
            config.mood = isNight ? .night : .day
        }
        // Each mood has its own painting, so the day meadow never shows at night.
        switch config.mood {
        case .night: config.name = "scene_night_stars_01"
        case .dusk: config.name = "scene_valley_dusk_01"
        case .golden: config.name = "scene_meadow_golden_01"
        case .day, .dawn: config.name = "scene_meadow_day_01"
        }
        return config
    }

    private var sheepState: SheepState {
        switch profile.status {
        case .lost: return .searching
        case .doneToday: return isNight ? .sleepy : .happy
        case .ready: return isNight ? .sleepy : .idle
        }
    }

    var body: some View {
        ZStack {
            SceneView(config: sceneConfig)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 0) {
                topBar
                Spacer(minLength: 0)
                VStack(spacing: 8) {
                    SheepView(state: sheepState, size: 170, name: profile.displaySheepName)
                        .offset(x: profile.status == .lost ? 60 : 0)
                    Text(profile.displaySheepName)
                        .font(Brand.Fonts.headline)
                        .foregroundStyle(Brand.Palette.petrol)
                        .ivoryScrim(14)
                        .accessibilityHidden(true)
                }
                .padding(.bottom, 14)
                actionCard
                    .padding(.horizontal, Brand.Metrics.padding)
                    .padding(.bottom, 14)
            }
        }
        .background(Brand.Palette.ivory)
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            StreakPill(streak: profile.shownStreak, dimmed: profile.status == .lost)
            if profile.freezes > 0 {
                Label("\(profile.freezes)", systemImage: "snowflake")
                    .font(Brand.Fonts.caption)
                    .foregroundStyle(Brand.Palette.petrol)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Brand.Palette.cream))
                    .accessibilityLabel(Text(Copy.a11yFreezes.f(lang, profile.freezes)))
            }
            Spacer()
            Button {
                router.showFocus = true
            } label: {
                Image(systemName: profile.focusEnabled ? "lock.shield.fill" : "lock.shield")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Brand.Palette.petrol)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Brand.Palette.paper.opacity(0.9)))
            }
            .accessibilityLabel(Text(Copy.focusTitle(lang)))
            Button {
                router.showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Brand.Palette.petrol)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Brand.Palette.paper.opacity(0.9)))
            }
            .accessibilityLabel(Text(Copy.settingsTitle(lang)))
        }
        .padding(.horizontal, Brand.Metrics.padding)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var actionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch profile.status {
            case .lost:
                Text(Copy.lostTitle.f(lang, profile.displaySheepName))
                    .font(Brand.Fonts.title)
                    .foregroundStyle(Brand.Palette.petrol)
                Text(Copy.lostShort(lang))
                    .font(Brand.Fonts.body)
                    .foregroundStyle(Brand.Palette.petrolSoft)
                Button(Copy.lostCTA.f(lang, profile.displaySheepName)) { router.showLostSheep = true }
                    .buttonStyle(.primary)
            case .ready:
                sessionSummary(label: Copy.homeToday(lang))
                Button(Copy.homeStart(lang)) {
                    router.reviewDay = nil
                    router.showSession = true
                }
                .buttonStyle(.primary)
                .disabled(next == nil)
            case .doneToday:
                Label(Copy.homeDoneTitle(lang), systemImage: "checkmark.circle.fill")
                    .font(Brand.Fonts.title)
                    .foregroundStyle(Brand.Palette.petrol)
                Text(Copy.homeDoneBody.f(lang, profile.displaySheepName))
                    .font(Brand.Fonts.body)
                    .foregroundStyle(Brand.Palette.petrolSoft)
                if let next {
                    Text(Copy.homeTomorrow.f(lang, next.day.summary(lang)))
                        .font(Brand.Fonts.callout)
                        .foregroundStyle(Brand.Palette.petrol)
                }
            }
            Divider().overlay(Brand.Palette.petrol.opacity(0.08))
            Button {
                router.tab = 1
            } label: {
                HStack {
                    Image(systemName: "map.fill").foregroundStyle(Brand.Palette.teal)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(Copy.homeJourney(lang))
                            .font(Brand.Fonts.caption)
                            .foregroundStyle(Brand.Palette.petrolSoft)
                        Text(journey?.title.t(lang) ?? "")
                            .font(Brand.Fonts.headline)
                            .foregroundStyle(Brand.Palette.petrol)
                    }
                    Spacer()
                    Text(journeyProgressText)
                        .font(Brand.Fonts.callout)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Brand.Palette.petrolSoft)
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .softCard()
    }

    private var journeyProgressText: String {
        guard let journey else { return "" }
        let done = JourneyProgress.completedDays(journey.id, in: records).count
        return "\(min(done, journey.totalDays))/\(journey.totalDays)"
    }

    @ViewBuilder
    private func sessionSummary(label: String) -> some View {
        if let next {
            Text(label)
                .font(Brand.Fonts.caption)
                .textCase(.uppercase)
                .foregroundStyle(Brand.Palette.petrolSoft)
            Text(next.day.title(lang))
                .font(Brand.Fonts.title)
                .foregroundStyle(Brand.Palette.petrol)
            Text(Copy.homeSessionMeta.f(lang, next.day.summary(lang), next.day.cards.count, profile.dailyMinutes))
                .font(Brand.Fonts.callout)
                .foregroundStyle(Brand.Palette.petrolSoft)
        } else {
            Text(Copy.comingSoon(lang))
                .font(Brand.Fonts.body)
                .foregroundStyle(Brand.Palette.petrolSoft)
        }
    }
}

/// Luke 15, gently: the sheep wandered off, and reading brings it home. Never a punishment.
struct LostSheepView: View {
    @Bindable var profile: UserProfile
    @Environment(Router.self) private var router
    @Environment(\.lang) private var lang

    var body: some View {
        ZStack {
            SceneView(config: SceneConfig(name: "scene_valley_dusk_01", mood: .dusk, terrain: .hills, lightLevel: 0, bloom: 2, milestones: profile.milestones))
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    StreakPill(streak: profile.shownStreak, dimmed: true)
                    Spacer()
                    CloseButton { router.showLostSheep = false }
                }
                .padding(.horizontal, Brand.Metrics.padding)
                .padding(.top, 8)
                Spacer()
                SheepView(state: .searching, size: 150, name: profile.displaySheepName)
                    .offset(x: 70, y: -10)
                    .padding(.bottom, 18)
                VStack(alignment: .leading, spacing: 12) {
                    Text(Copy.lostTitle.f(lang, profile.displaySheepName))
                        .font(Brand.Fonts.title)
                        .foregroundStyle(Brand.Palette.petrol)
                        .accessibilityAddTraits(.isHeader)
                    Text(Copy.lostBody(lang))
                        .font(Brand.Fonts.body)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                    Text(Copy.lostVerse(lang))
                        .font(Brand.Fonts.reference)
                        .italic()
                        .foregroundStyle(Brand.Palette.brown)
                    Label(profile.freeRecoveryAvailable ? Copy.lostRecoveryFree.f(lang, profile.lostStreak) : Copy.lostRecoveryUsed(lang),
                          systemImage: profile.freeRecoveryAvailable ? "sun.max.fill" : "sunrise.fill")
                        .font(Brand.Fonts.callout)
                        .foregroundStyle(Brand.Palette.petrol)
                    Button(Copy.lostCTA.f(lang, profile.displaySheepName)) {
                        router.showLostSheep = false
                        router.reviewDay = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            router.showSession = true
                        }
                    }
                    .buttonStyle(.primary)
                }
                .softCard()
                .padding(.horizontal, Brand.Metrics.padding)
                .padding(.bottom, 16)
            }
        }
    }
}
