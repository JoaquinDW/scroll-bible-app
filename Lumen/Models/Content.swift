import Foundation

/// A piece of copy in every supported language.
struct LText: Codable, Hashable {
    let en: String
    let es: String

    init(_ en: String, _ es: String) {
        self.en = en
        self.es = es
    }

    func callAsFunction(_ language: AppLanguage) -> String {
        language == .es ? es : en
    }

    /// Same as calling the value directly. Handy after optional chaining: `title?.t(lang)`.
    func t(_ language: AppLanguage) -> String { self(language) }

    /// Fills `%@` / `%d` placeholders.
    func f(_ language: AppLanguage, _ args: CVarArg...) -> String {
        String(format: self(language), arguments: args)
    }
}

struct VerseRef: Codable, Hashable {
    let book: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int

    func display(_ language: AppLanguage) -> String {
        let name = BibleBooks.name(for: book, language)
        let verses = verseStart == verseEnd ? "\(verseStart)" : "\(verseStart)-\(verseEnd)"
        return "\(name) \(chapter):\(verses)"
    }
}

enum CardKind: String, Codable {
    case verse, choice, missingWord, order
}

struct Blank: Codable, Hashable {
    let prompt: String
    let answer: String
    let options: [String]
}

/// One card in a session. `type` decides which optional fields are present.
struct SessionCard: Codable, Hashable {
    let type: CardKind
    let ref: VerseRef?
    // verse
    let scene: String?
    /// Scripture text keyed by translation id ("KJV", "WEB", "RV1909", later "NIV"...).
    let text: [String: String]?
    let explain: LText?
    let context: LText?
    let apply: LText?
    // choice
    let question: LText?
    let options: [LText]?
    let answer: Int?
    let note: LText?
    // missing word, keyed by translation id
    let blanks: [String: Blank]?
    // order, each piece keyed by translation id
    let pieces: [[String: String]]?

    var isCheck: Bool { type != .verse }

    func verseText(_ translationID: String) -> String {
        text?[translationID] ?? text?["KJV"] ?? ""
    }
}

struct JourneyDay: Codable, Hashable {
    let day: Int
    let title: LText
    let summary: LText
    /// Index of the verse card offered to save or share at the end.
    let keyCard: Int
    let cards: [SessionCard]
}

struct Journey: Codable, Identifiable, Hashable {
    let id: String
    let asset: String
    let terrain: String
    let seeded: Bool
    let title: LText
    let subtitle: LText
    let books: [String]
    let totalDays: Int
    let days: [JourneyDay]
}

struct Translation: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let language: String
    /// "publicDomain" today. Licensed translations plug in with another value.
    let license: String
}

struct ContentBundle: Codable {
    let version: Int
    let translations: [Translation]
    let journeys: [Journey]
}

/// Loads seeded content from `content.json` (built by tools/build_content.py).
/// A remote or licensed text provider can replace this later without touching views.
final class ContentStore {
    static let shared = ContentStore()

    let bundle: ContentBundle

    private init() {
        if let url = Bundle.main.url(forResource: "content", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(ContentBundle.self, from: data) {
            bundle = decoded
        } else {
            assertionFailure("content.json is missing or malformed")
            bundle = ContentBundle(version: 0, translations: [], journeys: [])
        }
    }

    var journeys: [Journey] { bundle.journeys }

    func journey(_ id: String) -> Journey? {
        bundle.journeys.first { $0.id == id }
    }

    func translations(for language: AppLanguage) -> [Translation] {
        bundle.translations.filter { $0.language == language.rawValue }
    }

    func translation(_ id: String) -> Translation? {
        bundle.translations.first { $0.id == id }
    }
}
