import SwiftUI
import SwiftData

/// Levels, the 66-book map, unlocked scenes and saved verses.
struct ProgressScreen: View {
    @Bindable var profile: UserProfile
    @Environment(Router.self) private var router
    @Environment(\.lang) private var lang
    @Query(sort: \SessionRecord.completedAt) private var records: [SessionRecord]
    @Query(sort: \SavedVerse.savedAt, order: .reverse) private var savedVerses: [SavedVerse]

    private var opened: Set<String> { JourneyProgress.booksOpened(in: records) }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    SectionTitle(text: Copy.progressTitle(lang))
                    Button {
                        router.showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Brand.Palette.petrol)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(Text(Copy.settingsTitle(lang)))
                }
                levelCard
                statsRow
                scenesCard
                itemsCard
                booksCard
                savedCard
            }
            .padding(.horizontal, Brand.Metrics.padding)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Brand.Palette.ivory.ignoresSafeArea())
    }

    private var levelCard: some View {
        HStack(spacing: 16) {
            SheepView(state: .happy, size: 84, name: profile.displaySheepName)
            VStack(alignment: .leading, spacing: 8) {
                Text(Copy.levelN.f(lang, profile.level.index))
                    .font(Brand.Fonts.caption)
                    .textCase(.uppercase)
                    .foregroundStyle(Brand.Palette.petrolSoft)
                Text(profile.level.name(lang))
                    .font(Brand.Fonts.title)
                    .foregroundStyle(Brand.Palette.petrol)
                ProgressBar(value: profile.levelProgress)
                if let next = profile.level.next {
                    Text(Copy.levelNext.f(lang, max(0, next.minXP - profile.xp), next.name(lang)))
                        .font(Brand.Fonts.caption)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
        .accessibilityElement(children: .combine)
    }

    private var statsRow: some View {
        HStack(spacing: 10) {
            StatTile(value: "\(profile.xp)", label: "XP", symbol: "sparkles")
            StatTile(value: "\(profile.shownStreak)", label: Copy.statLight(lang), symbol: "sun.max.fill")
            StatTile(value: "\(profile.bestStreak)", label: Copy.statBest(lang), symbol: "sunrise.fill")
            StatTile(value: "\(profile.freezes)", label: Copy.statFreezes(lang), symbol: "snowflake")
        }
    }

    private var scenesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.scenesTitle(lang)).font(Brand.Fonts.headline).foregroundStyle(Brand.Palette.petrol)
            ForEach(Milestone.allCases) { milestone in
                let unlocked = profile.milestones.contains(milestone)
                HStack(spacing: 12) {
                    Image(systemName: unlocked ? milestone.symbol : "lock.fill")
                        .foregroundStyle(unlocked ? Brand.Palette.gold : Brand.Palette.petrolSoft.opacity(0.5))
                        .frame(width: 28)
                    Text(milestone.title(lang))
                        .font(Brand.Fonts.body)
                        .foregroundStyle(Brand.Palette.petrol)
                    Spacer()
                    Text(Copy.daysN.f(lang, milestone.days))
                        .font(Brand.Fonts.caption)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                }
                .opacity(unlocked ? 1 : 0.7)
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }

    private var itemsCard: some View {
        let unlocked = Set(JourneyProgress.unlockedItems(in: records).map(\.id))
        return VStack(alignment: .leading, spacing: 12) {
            Text(Copy.itemsTitle.f(lang, profile.displaySheepName)).font(Brand.Fonts.headline).foregroundStyle(Brand.Palette.petrol)
            HStack(spacing: 10) {
                ForEach(SheepItem.all) { item in
                    let has = unlocked.contains(item.id)
                    VStack(spacing: 6) {
                        ArtLayer(name: item.id, contentMode: .fit) {
                            Image(systemName: has ? item.symbol : "lock.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(has ? Brand.Palette.petrol : Brand.Palette.petrolSoft.opacity(0.5))
                        }
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(has ? Brand.Palette.blush.opacity(0.6) : Brand.Palette.cream))
                        Text(item.name(lang))
                            .font(Brand.Fonts.caption)
                            .foregroundStyle(Brand.Palette.petrol)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity)
                    .opacity(has ? 1 : 0.7)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }

    private var booksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Copy.booksTitle(lang)).font(Brand.Fonts.headline).foregroundStyle(Brand.Palette.petrol)
                Spacer()
                Text("\(opened.count)/66").font(Brand.Fonts.callout).foregroundStyle(Brand.Palette.petrolSoft)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(BibleBooks.all) { book in
                    let filled = opened.contains(book.code)
                    Text(book.short(lang))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(filled ? Brand.Palette.petrol : Brand.Palette.petrolSoft.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(filled ? (book.isOldTestament ? Brand.Palette.goldSoft : Brand.Palette.aqua) : Brand.Palette.cream.opacity(0.7))
                        )
                        .accessibilityLabel(Text("\(book.name(lang)), \(filled ? Copy.a11yBookOpened(lang) : Copy.a11yBookNotYet(lang))"))
                }
            }
            Text(Copy.booksNote(lang))
                .font(Brand.Fonts.caption)
                .foregroundStyle(Brand.Palette.petrolSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }

    private var savedCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Copy.savedTitle(lang)).font(Brand.Fonts.headline).foregroundStyle(Brand.Palette.petrol)
            if savedVerses.isEmpty {
                Text(Copy.savedEmpty(lang))
                    .font(Brand.Fonts.body)
                    .foregroundStyle(Brand.Palette.petrolSoft)
            } else {
                ForEach(savedVerses.prefix(8)) { verse in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verse.reference).font(Brand.Fonts.reference).foregroundStyle(Brand.Palette.petrolSoft)
                        Text(verse.text).font(Brand.Fonts.callout).foregroundStyle(Brand.Palette.brown)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}

struct StatTile: View {
    var value: String
    var label: String
    var symbol: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).foregroundStyle(Brand.Palette.gold)
            Text(value).font(Brand.Fonts.headline).foregroundStyle(Brand.Palette.petrol)
            Text(label).font(Brand.Fonts.caption).foregroundStyle(Brand.Palette.petrolSoft).lineLimit(1).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Brand.Palette.paper))
        .accessibilityElement(children: .combine)
    }
}
