import Foundation

// MARK: - Levels

struct Level: Identifiable, Hashable {
    let index: Int
    let name: LText
    let minXP: Int
    var id: Int { index }

    static let all: [Level] = [
        Level(index: 1, name: LText("Seeker", "Buscador"), minXP: 0),
        Level(index: 2, name: LText("Listener", "Oyente"), minXP: 150),
        Level(index: 3, name: LText("Follower", "Seguidor"), minXP: 400),
        Level(index: 4, name: LText("Disciple", "Discípulo"), minXP: 800),
        Level(index: 5, name: LText("Shepherd's Friend", "Amigo del Pastor"), minXP: 1500),
        Level(index: 6, name: LText("Lamplighter", "Portador de luz"), minXP: 2500),
    ]

    static func forXP(_ xp: Int) -> Level {
        all.last { xp >= $0.minXP } ?? all[0]
    }

    var next: Level? {
        Level.all.first { $0.index == index + 1 }
    }
}

// MARK: - Milestones (permanent scene changes)

enum Milestone: Int, CaseIterable, Identifiable, Hashable {
    case rainbow = 7
    case floweringTree = 30
    case stillPond = 100
    case goldenEvening = 365

    var id: Int { rawValue }
    var days: Int { rawValue }

    var asset: String {
        switch self {
        case .rainbow: return Art.milestoneRainbow
        case .floweringTree: return Art.milestoneFloweringTree
        case .stillPond: return Art.milestoneStillPond
        case .goldenEvening: return Art.milestoneGoldenEvening
        }
    }

    var title: LText {
        switch self {
        case .rainbow: return LText("A rainbow", "Un arcoíris")
        case .floweringTree: return LText("A flowering tree", "Un árbol en flor")
        case .stillPond: return LText("A still water pond", "Un estanque de aguas quietas")
        case .goldenEvening: return LText("Golden evening light", "Luz dorada de la tarde")
        }
    }

    var symbol: String {
        switch self {
        case .rainbow: return "rainbow"
        case .floweringTree: return "tree.fill"
        case .stillPond: return "drop.fill"
        case .goldenEvening: return "sun.horizon.fill"
        }
    }
}

// MARK: - Sheep items (journey chapter rewards)

struct SheepItem: Identifiable, Hashable {
    let id: String
    let name: LText
    let symbol: String
    let journeyID: String
    let unlockDay: Int

    static let all: [SheepItem] = [
        SheepItem(id: Art.itemBell, name: LText("Little bell", "Campanita"), symbol: "bell.fill", journeyID: "psalms_anxiety", unlockDay: 3),
        SheepItem(id: Art.itemDaisy, name: LText("Daisy behind the ear", "Margarita en la oreja"), symbol: "camera.macro", journeyID: "psalms_anxiety", unlockDay: 5),
        SheepItem(id: Art.itemScarf, name: LText("Woven scarf", "Bufanda tejida"), symbol: "wind", journeyID: "psalms_anxiety", unlockDay: 7),
    ]
}

// MARK: - Session result

struct CompletionResult: Hashable {
    var xpEarned: Int = 0
    var newStreak: Int = 0
    var wasLost: Bool = false
    var streakRestored: Bool = false
    var countedForStreak: Bool = false
    var leveledUpTo: Level? = nil
    var milestone: Milestone? = nil
    var earnedFreeze: Bool = false
    var item: SheepItem? = nil
}

enum DayStatus {
    case ready      // today's session is waiting
    case doneToday  // finished, come back tomorrow
    case lost       // a day was missed and no freeze covered it
}

// MARK: - Rules

enum Rules {
    static let xpPerVerse = 10
    static let xpCheckFirstTry = 15
    static let xpCheckRetry = 5
    static let xpCompletionBonus = 20
    static let xpPerFreeze = 300
    static let maxFreezes = 2
}

extension UserProfile {
    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .en }
        set { languageRaw = newValue.rawValue }
    }

    var goal: Goal {
        get { Goal(rawValue: goalRaw) ?? .habit }
        set { goalRaw = newValue.rawValue }
    }

    var displaySheepName: String {
        sheepName.trimmingCharacters(in: .whitespaces).isEmpty ? (language == .es ? "Tu oveja" : "Your sheep") : sheepName
    }

    /// "Now", shifted by the simulator helper in Settings.
    var now: Date {
        Calendar.current.date(byAdding: .day, value: debugDayOffset, to: Date()) ?? Date()
    }

    var today: Date { Calendar.current.startOfDay(for: now) }

    private var weekKey: String {
        let c = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        return "\(c.yearForWeekOfYear ?? 0)-\(c.weekOfYear ?? 0)"
    }

    private var daysSinceLast: Int? {
        guard let last = lastCompletedDay else { return nil }
        return Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: last), to: today).day
    }

    var status: DayStatus {
        if isLost { return .lost }
        if daysSinceLast == 0 { return .doneToday }
        return .ready
    }

    var freeRecoveryAvailable: Bool { lastRecoveryWeek != weekKey }

    /// The streak number to show. While lost we show what can still be recovered.
    var shownStreak: Int { isLost ? lostStreak : streak }

    var level: Level { Level.forXP(xp) }

    /// 0...1 progress toward the next level.
    var levelProgress: Double {
        guard let next = level.next else { return 1 }
        let span = Double(next.minXP - level.minXP)
        return span <= 0 ? 1 : min(1, max(0, Double(xp - level.minXP) / span))
    }

    /// 0 = dusk (lost). 1...5 grows warmer and wider with the streak.
    var lightLevel: Int {
        if isLost { return 0 }
        switch streak {
        case ..<3: return 1
        case 3..<7: return 2
        case 7..<30: return 3
        case 30..<100: return 4
        default: return 5
        }
    }

    /// How much the meadow has bloomed (wildflowers, butterflies).
    var bloom: Int { isLost ? 2 : min(30, 3 + streak) }

    var milestones: Set<Milestone> {
        Set(Milestone.allCases.filter { bestStreak >= $0.days })
    }

    /// Back to a fresh install (Settings > Simulator tools).
    func resetEverything() {
        sheepName = ""; languageRaw = "en"; translationID = "KJV"; goalRaw = "habit"
        dailyMinutes = 5; reminderHour = 8; reminderMinute = 0; remindersOn = false
        hasOnboarded = false; hasSeenPaywall = false; isPremium = false; invitedFriend = ""
        xp = 0; currentJourneyID = "psalms_anxiety"
        streak = 0; bestStreak = 0; lastCompletedDay = nil; isLost = false; lostStreak = 0
        lastRecoveryWeek = ""; freezes = 0; freezesEarned = 0
        focusEnabled = false; debugDayOffset = 0
    }

    /// Call when the app becomes active. Applies freezes or marks the sheep as wandered.
    func refreshStreak() {
        guard !isLost, streak > 0, let gap = daysSinceLast, gap >= 2 else { return }
        let missed = gap - 1
        if freezes >= missed {
            freezes -= missed
            lastCompletedDay = Calendar.current.date(byAdding: .day, value: -1, to: today)
        } else {
            isLost = true
            lostStreak = streak
            streak = 0
        }
    }

    /// Applies a finished session. `journeyDay` is used for item rewards.
    func completeSession(xpEarned: Int, journeyID: String, journeyDay: Int, isReview: Bool) -> CompletionResult {
        var result = CompletionResult()
        let levelBefore = level
        let milestonesBefore = milestones

        result.xpEarned = xpEarned
        xp += xpEarned

        if isLost {
            result.wasLost = true
            if freeRecoveryAvailable {
                streak = lostStreak + 1
                lastRecoveryWeek = weekKey
                result.streakRestored = true
            } else {
                streak = 1
            }
            isLost = false
            lostStreak = 0
            result.countedForStreak = true
        } else if daysSinceLast != 0 {
            streak += 1
            result.countedForStreak = true
        }
        lastCompletedDay = now
        bestStreak = max(bestStreak, streak)
        result.newStreak = streak

        // Freezes are earned with XP, never bought.
        let deserved = xp / Rules.xpPerFreeze
        if deserved > freezesEarned {
            freezesEarned = deserved
            if freezes < Rules.maxFreezes {
                freezes += 1
                result.earnedFreeze = true
            }
        }

        if level.index > levelBefore.index { result.leveledUpTo = level }
        result.milestone = milestones.subtracting(milestonesBefore).max { $0.days < $1.days }
        if !isReview {
            result.item = SheepItem.all.first { $0.journeyID == journeyID && $0.unlockDay == journeyDay }
        }
        return result
    }
}

// MARK: - Journey progress

enum JourneyProgress {
    static func completedDays(_ journeyID: String, in records: [SessionRecord]) -> Set<Int> {
        Set(records.filter { $0.journeyID == journeyID }.map(\.day))
    }

    /// The day to read next. Once a journey is finished it loops as review.
    static func nextDay(for journey: Journey, in records: [SessionRecord]) -> (day: JourneyDay, isReview: Bool)? {
        guard !journey.days.isEmpty else { return nil }
        let done = completedDays(journey.id, in: records)
        if let next = journey.days.first(where: { !done.contains($0.day) }) {
            return (next, false)
        }
        let count = records.filter { $0.journeyID == journey.id }.count
        return (journey.days[count % journey.days.count], true)
    }

    static func booksOpened(in records: [SessionRecord]) -> Set<String> {
        Set(records.flatMap { $0.bookCodes.split(separator: ",").map(String.init) })
    }

    static func unlockedItems(in records: [SessionRecord]) -> [SheepItem] {
        SheepItem.all.filter { completedDays($0.journeyID, in: records).contains($0.unlockDay) }
    }

    static func weeklyXP(in records: [SessionRecord], now: Date) -> Int {
        guard let week = Calendar.current.dateInterval(of: .weekOfYear, for: now) else { return 0 }
        return records.filter { week.contains($0.completedAt) }.reduce(0) { $0 + $1.xpEarned }
    }
}
