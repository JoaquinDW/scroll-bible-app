import SwiftUI
import SwiftData

/// Mock flock for the MVP. Replace with a real service later; views only read this shape.
struct FlockMember: Identifiable, Hashable {
    let id: String
    let name: String
    let sheepName: String
    let weeklyXP: Int
    let streak: Int
    let readToday: Bool
    let challengeChapters: Int

    static let sample: [FlockMember] = [
        FlockMember(id: "ana", name: "Ana", sheepName: "Nube", weeklyXP: 430, streak: 21, readToday: true, challengeChapters: 3),
        FlockMember(id: "mateo", name: "Mateo", sheepName: "Trigo", weeklyXP: 310, streak: 9, readToday: true, challengeChapters: 2),
        FlockMember(id: "grace", name: "Grace", sheepName: "Clover", weeklyXP: 220, streak: 4, readToday: false, challengeChapters: 2),
        FlockMember(id: "sam", name: "Sam", sheepName: "Pebble", weeklyXP: 90, streak: 1, readToday: false, challengeChapters: 1),
    ]
}

/// Private flock, weekly league, a shared challenge and gentle nudges.
struct FlockView: View {
    @Bindable var profile: UserProfile
    @Environment(\.lang) private var lang
    @Query(sort: \SessionRecord.completedAt) private var records: [SessionRecord]
    @State private var nudged: Set<String> = []

    private struct Row: Identifiable {
        let id: String
        let name: String
        let sheepName: String
        let xp: Int
        let streak: Int
        let isYou: Bool
    }

    private var myWeeklyXP: Int { JourneyProgress.weeklyXP(in: records, now: profile.now) }

    private var league: [Row] {
        var rows = FlockMember.sample.map { Row(id: $0.id, name: $0.name, sheepName: $0.sheepName, xp: $0.weeklyXP, streak: $0.streak, isYou: false) }
        rows.append(Row(id: "you", name: Copy.you(lang), sheepName: profile.displaySheepName, xp: myWeeklyXP, streak: profile.shownStreak, isYou: true))
        return rows.sorted { $0.xp > $1.xp }
    }

    private var daysLeftInWeek: Int {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: profile.now) else { return 7 }
        return max(1, Calendar.current.dateComponents([.day], from: profile.now, to: week.end).day ?? 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack {
                    SectionTitle(text: Copy.flockTitle(lang))
                    Text(Copy.flockSample(lang))
                        .font(Brand.Fonts.caption)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Brand.Palette.cream))
                }
                pasture
                leagueCard
                challengeCard
                nudgeCard
                ShareLink(item: Copy.inviteMessage.f(lang, Brand.name)) {
                    Label(Copy.inviteFriend(lang), systemImage: "person.badge.plus")
                }
                .buttonStyle(.quiet)
            }
            .padding(.horizontal, Brand.Metrics.padding)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(Brand.Palette.ivory.ignoresSafeArea())
    }

    /// Friends graze in your pasture as other sheep.
    private var pasture: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let spots: [CGPoint] = [CGPoint(x: 0.16, y: 0.62), CGPoint(x: 0.84, y: 0.6), CGPoint(x: 0.3, y: 0.84), CGPoint(x: 0.72, y: 0.86)]
            ZStack {
                SceneView(config: SceneConfig(name: "scene_meadow_day_01", lightLevel: max(1, profile.lightLevel), bloom: profile.bloom, milestones: profile.milestones))
                ForEach(Array(FlockMember.sample.enumerated()), id: \.element.id) { i, member in
                    VStack(spacing: 2) {
                        SheepView(state: member.readToday ? .happy : .idle, size: 58, name: member.sheepName)
                        Text(member.name)
                            .font(Brand.Fonts.caption)
                            .foregroundStyle(Brand.Palette.petrol)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Brand.Palette.ivory.opacity(0.88)))
                    }
                    .position(x: w * spots[i % spots.count].x, y: 230 * spots[i % spots.count].y)
                }
                SheepView(state: profile.isLost ? .searching : .idle, size: 84, name: profile.displaySheepName)
                    .position(x: w * 0.5, y: 230 * 0.66)
            }
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: Brand.Metrics.corner, style: .continuous))
    }

    private var leagueCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(Copy.leagueTitle(lang)).font(Brand.Fonts.headline).foregroundStyle(Brand.Palette.petrol)
                Spacer()
                Label(Copy.daysLeft.f(lang, daysLeftInWeek), systemImage: "clock")
                    .font(Brand.Fonts.caption)
                    .foregroundStyle(Brand.Palette.petrolSoft)
            }
            ForEach(Array(league.enumerated()), id: \.element.id) { rank, row in
                HStack(spacing: 12) {
                    Text("\(rank + 1)")
                        .font(Brand.Fonts.headline)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                        .frame(width: 22)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name).font(Brand.Fonts.headline).foregroundStyle(Brand.Palette.petrol)
                        Text(row.sheepName).font(Brand.Fonts.caption).foregroundStyle(Brand.Palette.petrolSoft)
                    }
                    Spacer()
                    Label("\(row.streak)", systemImage: "sun.max.fill")
                        .font(Brand.Fonts.caption)
                        .foregroundStyle(Brand.Palette.petrolSoft)
                    Text("\(row.xp) XP")
                        .font(Brand.Fonts.callout)
                        .foregroundStyle(Brand.Palette.petrol)
                        .frame(minWidth: 64, alignment: .trailing)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(row.isYou ? Brand.Palette.goldSoft.opacity(0.5) : Color.clear))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(Copy.a11yLeagueRow.f(lang, rank + 1, row.name, row.xp)))
            }
            Text(Copy.leagueNote(lang))
                .font(Brand.Fonts.caption)
                .foregroundStyle(Brand.Palette.petrolSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }

    private var challengeCard: some View {
        let total = FlockMember.sample.count * 4
        let read = FlockMember.sample.reduce(0) { $0 + $1.challengeChapters }
        return VStack(alignment: .leading, spacing: 10) {
            Label(Copy.challengeTitle(lang), systemImage: "book.fill")
                .font(Brand.Fonts.headline)
                .foregroundStyle(Brand.Palette.petrol)
            Text(Copy.challengeBody(lang))
                .font(Brand.Fonts.body)
                .foregroundStyle(Brand.Palette.petrolSoft)
            ProgressBar(value: Double(read) / Double(max(1, total)), tint: Brand.Palette.grass)
            Text(Copy.challengeProgress.f(lang, read, total))
                .font(Brand.Fonts.caption)
                .foregroundStyle(Brand.Palette.petrolSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }

    private var nudgeCard: some View {
        let waiting = FlockMember.sample.filter { !$0.readToday }
        return VStack(alignment: .leading, spacing: 12) {
            Text(Copy.nudgeTitle(lang)).font(Brand.Fonts.headline).foregroundStyle(Brand.Palette.petrol)
            ForEach(waiting) { member in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(member.name).font(Brand.Fonts.body).foregroundStyle(Brand.Palette.petrol)
                        Text(Copy.nudgeWaiting.f(lang, member.sheepName)).font(Brand.Fonts.caption).foregroundStyle(Brand.Palette.petrolSoft)
                    }
                    Spacer()
                    Button(nudged.contains(member.id) ? Copy.nudgeSent(lang) : Copy.nudgeCTA(lang)) {
                        withAnimation { _ = nudged.insert(member.id) }
                    }
                    .font(Brand.Fonts.callout)
                    .foregroundStyle(Brand.Palette.petrol)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 40)
                    .background(Capsule().fill(nudged.contains(member.id) ? Brand.Palette.sage.opacity(0.4) : Brand.Palette.goldSoft))
                    .disabled(nudged.contains(member.id))
                }
            }
            Text(Copy.nudgeNote(lang))
                .font(Brand.Fonts.caption)
                .foregroundStyle(Brand.Palette.petrolSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .softCard()
    }
}
