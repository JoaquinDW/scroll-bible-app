import Foundation

struct BibleBook: Identifiable, Hashable {
    let code: String
    let name: LText
    let isOldTestament: Bool
    var id: String { code }

    /// Short label for the 66-tile map.
    func short(_ language: AppLanguage) -> String {
        let n = name(language)
        let parts = n.split(separator: " ")
        if parts.count == 2, let first = parts.first, first.count == 1 {
            return String(first) + String(parts[1].prefix(2))
        }
        return String(n.prefix(3))
    }
}

enum BibleBooks {
    static let all: [BibleBook] = [
        BibleBook(code: "GEN", name: LText("Genesis", "Génesis"), isOldTestament: true),
        BibleBook(code: "EXO", name: LText("Exodus", "Éxodo"), isOldTestament: true),
        BibleBook(code: "LEV", name: LText("Leviticus", "Levítico"), isOldTestament: true),
        BibleBook(code: "NUM", name: LText("Numbers", "Números"), isOldTestament: true),
        BibleBook(code: "DEU", name: LText("Deuteronomy", "Deuteronomio"), isOldTestament: true),
        BibleBook(code: "JOS", name: LText("Joshua", "Josué"), isOldTestament: true),
        BibleBook(code: "JDG", name: LText("Judges", "Jueces"), isOldTestament: true),
        BibleBook(code: "RUT", name: LText("Ruth", "Rut"), isOldTestament: true),
        BibleBook(code: "1SA", name: LText("1 Samuel", "1 Samuel"), isOldTestament: true),
        BibleBook(code: "2SA", name: LText("2 Samuel", "2 Samuel"), isOldTestament: true),
        BibleBook(code: "1KI", name: LText("1 Kings", "1 Reyes"), isOldTestament: true),
        BibleBook(code: "2KI", name: LText("2 Kings", "2 Reyes"), isOldTestament: true),
        BibleBook(code: "1CH", name: LText("1 Chronicles", "1 Crónicas"), isOldTestament: true),
        BibleBook(code: "2CH", name: LText("2 Chronicles", "2 Crónicas"), isOldTestament: true),
        BibleBook(code: "EZR", name: LText("Ezra", "Esdras"), isOldTestament: true),
        BibleBook(code: "NEH", name: LText("Nehemiah", "Nehemías"), isOldTestament: true),
        BibleBook(code: "EST", name: LText("Esther", "Ester"), isOldTestament: true),
        BibleBook(code: "JOB", name: LText("Job", "Job"), isOldTestament: true),
        BibleBook(code: "PSA", name: LText("Psalms", "Salmos"), isOldTestament: true),
        BibleBook(code: "PRO", name: LText("Proverbs", "Proverbios"), isOldTestament: true),
        BibleBook(code: "ECC", name: LText("Ecclesiastes", "Eclesiastés"), isOldTestament: true),
        BibleBook(code: "SNG", name: LText("Song of Songs", "Cantares"), isOldTestament: true),
        BibleBook(code: "ISA", name: LText("Isaiah", "Isaías"), isOldTestament: true),
        BibleBook(code: "JER", name: LText("Jeremiah", "Jeremías"), isOldTestament: true),
        BibleBook(code: "LAM", name: LText("Lamentations", "Lamentaciones"), isOldTestament: true),
        BibleBook(code: "EZK", name: LText("Ezekiel", "Ezequiel"), isOldTestament: true),
        BibleBook(code: "DAN", name: LText("Daniel", "Daniel"), isOldTestament: true),
        BibleBook(code: "HOS", name: LText("Hosea", "Oseas"), isOldTestament: true),
        BibleBook(code: "JOL", name: LText("Joel", "Joel"), isOldTestament: true),
        BibleBook(code: "AMO", name: LText("Amos", "Amós"), isOldTestament: true),
        BibleBook(code: "OBA", name: LText("Obadiah", "Abdías"), isOldTestament: true),
        BibleBook(code: "JON", name: LText("Jonah", "Jonás"), isOldTestament: true),
        BibleBook(code: "MIC", name: LText("Micah", "Miqueas"), isOldTestament: true),
        BibleBook(code: "NAM", name: LText("Nahum", "Nahúm"), isOldTestament: true),
        BibleBook(code: "HAB", name: LText("Habakkuk", "Habacuc"), isOldTestament: true),
        BibleBook(code: "ZEP", name: LText("Zephaniah", "Sofonías"), isOldTestament: true),
        BibleBook(code: "HAG", name: LText("Haggai", "Hageo"), isOldTestament: true),
        BibleBook(code: "ZEC", name: LText("Zechariah", "Zacarías"), isOldTestament: true),
        BibleBook(code: "MAL", name: LText("Malachi", "Malaquías"), isOldTestament: true),
        BibleBook(code: "MAT", name: LText("Matthew", "Mateo"), isOldTestament: false),
        BibleBook(code: "MRK", name: LText("Mark", "Marcos"), isOldTestament: false),
        BibleBook(code: "LUK", name: LText("Luke", "Lucas"), isOldTestament: false),
        BibleBook(code: "JHN", name: LText("John", "Juan"), isOldTestament: false),
        BibleBook(code: "ACT", name: LText("Acts", "Hechos"), isOldTestament: false),
        BibleBook(code: "ROM", name: LText("Romans", "Romanos"), isOldTestament: false),
        BibleBook(code: "1CO", name: LText("1 Corinthians", "1 Corintios"), isOldTestament: false),
        BibleBook(code: "2CO", name: LText("2 Corinthians", "2 Corintios"), isOldTestament: false),
        BibleBook(code: "GAL", name: LText("Galatians", "Gálatas"), isOldTestament: false),
        BibleBook(code: "EPH", name: LText("Ephesians", "Efesios"), isOldTestament: false),
        BibleBook(code: "PHP", name: LText("Philippians", "Filipenses"), isOldTestament: false),
        BibleBook(code: "COL", name: LText("Colossians", "Colosenses"), isOldTestament: false),
        BibleBook(code: "1TH", name: LText("1 Thessalonians", "1 Tesalonicenses"), isOldTestament: false),
        BibleBook(code: "2TH", name: LText("2 Thessalonians", "2 Tesalonicenses"), isOldTestament: false),
        BibleBook(code: "1TI", name: LText("1 Timothy", "1 Timoteo"), isOldTestament: false),
        BibleBook(code: "2TI", name: LText("2 Timothy", "2 Timoteo"), isOldTestament: false),
        BibleBook(code: "TIT", name: LText("Titus", "Tito"), isOldTestament: false),
        BibleBook(code: "PHM", name: LText("Philemon", "Filemón"), isOldTestament: false),
        BibleBook(code: "HEB", name: LText("Hebrews", "Hebreos"), isOldTestament: false),
        BibleBook(code: "JAS", name: LText("James", "Santiago"), isOldTestament: false),
        BibleBook(code: "1PE", name: LText("1 Peter", "1 Pedro"), isOldTestament: false),
        BibleBook(code: "2PE", name: LText("2 Peter", "2 Pedro"), isOldTestament: false),
        BibleBook(code: "1JN", name: LText("1 John", "1 Juan"), isOldTestament: false),
        BibleBook(code: "2JN", name: LText("2 John", "2 Juan"), isOldTestament: false),
        BibleBook(code: "3JN", name: LText("3 John", "3 Juan"), isOldTestament: false),
        BibleBook(code: "JUD", name: LText("Jude", "Judas"), isOldTestament: false),
        BibleBook(code: "REV", name: LText("Revelation", "Apocalipsis"), isOldTestament: false),
    ]

    static func name(for code: String, _ language: AppLanguage) -> String {
        all.first { $0.code == code }?.name(language) ?? code
    }
}
