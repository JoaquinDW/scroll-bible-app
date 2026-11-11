import SwiftUI
import SwiftData

/// Reading plans as quests: an illustrated path the sheep walks, one session per node.
struct JourneysView: View {
    @Bindable var profile: UserProfile
    @Environment(Router.self) private var router
    @Environment(\.lang) private var lang
    @Query(sort: \SessionRecord.completedAt) private var records: [SessionRecord]
    @State private var selectedID: String?

    private var journeys: [Journey] { ContentStore.shared.journeys }
    private var journey: Journey? {
        ContentStore.shared.journey(selectedID ?? profile.currentJourneyID) ?? journeys.first
    }

    var body: some View {
        VStack(spacing: 0) {
            SectionTitle(text: Copy.journeysTitle(lang))
                .padding(.horizontal, Brand.Metrics.padding)
                .padding(.top, 12)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(journeys) { item in
                        let isSelected = item.id == journey?.id
                        Button {
                            selectedID = item.id
                        } label: {
                            HStack(spacing: 6) {
                                if !item.seeded { Image(systemName: "hourglass").font(.caption) }
                                Text(item.title(lang)).font(Brand.Fonts.callout)
                            }
                            .foregroundStyle(Brand.Palette.petrol)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 40)
                            .background(Capsule().fill(isSelected ? Brand.Palette.goldSoft : Brand.Palette.paper))
                            .overlay(Capsule().stroke(Brand.Palette.gold.opacity(isSelected ? 0.8 : 0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                    }
                }
                .padding(.horizontal, Brand.Metrics.padding)
                .padding(.vertical, 12)
            }
            if let journey {
                ScrollView {
                    VStack(spacing: 14) {
                        journeyHeader(journey)
                        JourneyMap(journey: journey,
                                   completed: JourneyProgress.completedDays(journey.id, in: records),
                                   currentDay: currentDay(journey),
                                   sheepName: profile.displaySheepName,
                                   isActive: journey.id == profile.currentJourneyID,
                                   onTap: { tap(journey, $0) })
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .background(Brand.Palette.ivory.ignoresSafeArea())
    }

    private func currentDay(_ journey: Journey) -> Int? {
        let done = JourneyProgress.completedDays(journey.id, in: records)
        return (1...max(1, journey.totalDays)).first { !done.contains($0) }
    }

    private func journeyHeader(_ journey: Journey) -> some View {
        let done = JourneyProgress.completedDays(journey.id, in: records).count
        return VStack(alignment: .leading, spacing: 10) {
            Text(journey.title(lang))
                .font(Brand.Fonts.title)
                .foregroundStyle(Brand.Palette.petrol)
            Text(journey.subtitle(lang))
                .font(Brand.Fonts.body)
                .foregroundStyle(Brand.Palette.petrolSoft)
            ProgressBar(value: Double(done) / Double(max(1, journey.totalDays)), tint: Brand.Palette.grass)
            Text(Copy.journeyProgress.f(lang, min(done, journey.totalDays), journey.totalDays))
                .font(Brand.Fonts.caption)
                .foregroundStyle(Brand.Palette.petrolSoft)
            if !journey.seeded {
                Label(Copy.journeyComingSoon(lang), systemImage: "hourglass")
                    .font(Brand.Fonts.callout)
                    .foregroundStyle(Brand.Palette.petrol)
            } else if journey.id != profile.currentJourneyID {
                Button(Copy.journeyMakeCurrent(lang)) { profile.currentJourneyID = journey.id }
                    .buttonStyle(.quiet)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
        .padding(.horizontal, Brand.Metrics.padding)
    }

    private func tap(_ journey: Journey, _ day: Int) {
        guard journey.seeded, journey.id == profile.currentJourneyID else { return }
        let done = JourneyProgress.completedDays(journey.id, in: records)
        if done.contains(day) {
            router.reviewDay = day
            router.showSession = true
        } else if day == currentDay(journey) {
            switch profile.status {
            case .lost: router.showLostSheep = true
            case .ready:
                router.reviewDay = nil
                router.showSession = true
            case .doneToday: break
            }
        }
    }
}

struct JourneyMap: View {
    let journey: Journey
    let completed: Set<Int>
    let currentDay: Int?
    let sheepName: String
    let isActive: Bool
    var onTap: (Int) -> Void

    @Environment(\.lang) private var lang
    private let spacing: CGFloat = 112

    private var terrain: Terrain { Terrain(rawValue: journey.terrain) ?? .meadow }
    private var height: CGFloat { CGFloat(journey.totalDays) * spacing + 120 }

    private func point(_ day: Int, width: CGFloat) -> CGPoint {
        let i = CGFloat(day - 1)
        return CGPoint(x: width * (0.5 + 0.27 * sin(i * 1.15)), y: 80 + i * spacing)
    }

    private var groundColors: [Color] {
        switch terrain {
        case .sea: return [Brand.Palette.aqua, Brand.Palette.teal.opacity(0.55), Brand.Palette.sage]
        case .desert: return [Color(hex: 0xF5E3C0), Color(hex: 0xEBD3A6), Color(hex: 0xE2C392)]
        case .hills, .valley: return [Brand.Palette.sage, Color(hex: 0xC9D6B4), Brand.Palette.peach.opacity(0.7)]
        case .meadow: return [Color(hex: 0xDCE8CC), Brand.Palette.sage, Brand.Palette.grass.opacity(0.8)]
        }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                ArtLayer(name: Art.journeyCover(journey.asset)) {
                    ZStack {
                        LinearGradient(colors: groundColors, startPoint: .top, endPoint: .bottom)
                        PaperGrainPlaceholder()
                    }
                }
                .frame(width: w, height: height)

                // The path
                Path { path in
                    for day in 1...max(1, journey.totalDays) {
                        let p = point(day, width: w)
                        if day == 1 { path.move(to: p) } else {
                            let prev = point(day - 1, width: w)
                            path.addCurve(to: p,
                                          control1: CGPoint(x: prev.x, y: prev.y + spacing * 0.5),
                                          control2: CGPoint(x: p.x, y: p.y - spacing * 0.5))
                        }
                    }
                }
                .stroke(Brand.Palette.paper.opacity(0.9), style: StrokeStyle(lineWidth: 14, lineCap: .round, dash: [2, 22]))

                ForEach(1...max(1, journey.totalDays), id: \.self) { day in
                    let p = point(day, width: w)
                    node(day)
                        .position(p)
                    if day == currentDay, isActive {
                        SheepView(state: .idle, size: 64, name: sheepName)
                            .position(x: p.x + (p.x > w / 2 ? -62 : 62), y: p.y - 6)
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Metrics.corner, style: .continuous))
        .padding(.horizontal, Brand.Metrics.padding)
    }

    private func node(_ day: Int) -> some View {
        let isDone = completed.contains(day)
        let isCurrent = day == currentDay && journey.seeded
        let state = isDone ? "done" : (isCurrent ? "current" : "locked")
        let item = SheepItem.all.first { $0.journeyID == journey.id && $0.unlockDay == day }
        let title = journey.days.first { $0.day == day }?.title.t(lang)
        return Button {
            onTap(day)
        } label: {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    ArtLayer(name: Art.journeyNode(journey.asset, state: state), contentMode: .fit) {
                        Circle()
                            .fill(isDone ? Brand.Palette.goldSoft : (isCurrent ? Brand.Palette.paper : Brand.Palette.cream.opacity(0.85)))
                            .overlay(Circle().stroke(isCurrent ? Brand.Palette.gold : Brand.Palette.paper, lineWidth: isCurrent ? 4 : 2))
                            .overlay(
                                Image(systemName: isDone ? "checkmark" : (isCurrent ? "sun.max.fill" : "lock.fill"))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(isDone || isCurrent ? Brand.Palette.petrol : Brand.Palette.petrolSoft.opacity(0.6))
                            )
                    }
                    .frame(width: 58, height: 58)
                    .shadow(color: Brand.Palette.brown.opacity(0.12), radius: 8, y: 4)
                    if let item {
                        Image(systemName: isDone ? item.symbol : "gift.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Brand.Palette.petrol)
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Brand.Palette.blush))
                            .offset(x: 8, y: -6)
                    }
                }
                Text(title ?? Copy.dayN.f(lang, day))
                    .font(Brand.Fonts.caption)
                    .foregroundStyle(Brand.Palette.petrol)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Brand.Palette.ivory.opacity(0.88)))
            }
            .frame(width: 150)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(Copy.dayN.f(lang, day)). \(title ?? ""). \(isDone ? Copy.a11yNodeDone(lang) : (isCurrent ? Copy.a11yNodeCurrent(lang) : Copy.a11yNodeLocked(lang)))"))
    }
}
