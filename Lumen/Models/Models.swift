import Foundation
import SwiftData

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case en, es
    var id: String { rawValue }
    var displayName: String { self == .en ? "English" : "Español" }
}

enum Goal: String, CaseIterable, Identifiable {
    case habit, understand, replaceScrolling
    var id: String { rawValue }
}

/// The single local user. Everything the MVP needs to remember lives here.
@Model
final class UserProfile {
    var createdAt: Date = Date()
    var sheepName: String = ""
    var languageRaw: String = "en"
    var translationID: String = "KJV"
    var goalRaw: String = "habit"
    var dailyMinutes: Int = 5
    var reminderHour: Int = 8
    var reminderMinute: Int = 0
    var remindersOn: Bool = false
    var hasOnboarded: Bool = false
    var hasSeenPaywall: Bool = false
    var isPremium: Bool = false
    var invitedFriend: String = ""

    // Progress
    var xp: Int = 0
    var currentJourneyID: String = "psalms_anxiety"

    // The light (streak)
    var streak: Int = 0
    var bestStreak: Int = 0
    var lastCompletedDay: Date? = nil
    var isLost: Bool = false
    var lostStreak: Int = 0
    var lastRecoveryWeek: String = ""
    var freezes: Int = 0
    var freezesEarned: Int = 0

    // Focus Mode
    var focusEnabled: Bool = false

    /// Simulator helper: shifts "today" forward so the streak loop can be demoed.
    var debugDayOffset: Int = 0

    init() {}
}

@Model
final class SessionRecord {
    var journeyID: String = ""
    var day: Int = 0
    var completedAt: Date = Date()
    var xpEarned: Int = 0
    /// Comma separated book codes read in this session, e.g. "PSA".
    var bookCodes: String = ""

    init(journeyID: String, day: Int, completedAt: Date, xpEarned: Int, bookCodes: String) {
        self.journeyID = journeyID
        self.day = day
        self.completedAt = completedAt
        self.xpEarned = xpEarned
        self.bookCodes = bookCodes
    }
}

@Model
final class SavedVerse {
    var reference: String = ""
    var text: String = ""
    var translationID: String = ""
    var savedAt: Date = Date()

    init(reference: String, text: String, translationID: String) {
        self.reference = reference
        self.text = text
        self.translationID = translationID
    }
}
