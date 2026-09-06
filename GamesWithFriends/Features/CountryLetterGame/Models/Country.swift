import Foundation

struct Country: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let name: String
    let alternateNames: [String]
    /// Overrides the letter the country is filed under when players don't
    /// think of it by its official first word (the DRC lives under C).
    let indexLetter: String?

    init(name: String, indexLetter: String? = nil, alternateNames: [String] = []) {
        self.id = UUID()
        self.name = name
        self.indexLetter = indexLetter
        self.alternateNames = alternateNames
    }

    var firstLetter: String {
        indexLetter ?? String(name.prefix(1)).uppercased()
    }

    /// Every label a player may use for this country: the name plus alternates.
    var labels: [String] {
        [name] + alternateNames
    }

    /// Whole-string match against the display name or any alternate, after
    /// both sides go through `normalize`. Deliberately exact: fuzzy matching
    /// on a 195-entry list produces false credits (e.g. "Niger" vs "Nigeria").
    func matches(_ input: String) -> Bool {
        let normalized = Country.normalize(input)
        guard !normalized.isEmpty else { return false }

        return labels.contains { normalized == Country.normalize($0) }
    }

    /// Lowercases, strips diacritics and punctuation (so "Côte d’Ivoire",
    /// "Cote d'Ivoire" and "cote d ivoire" collapse together), spells out
    /// "&" and "St.", collapses whitespace, and drops a leading "the".
    static func normalize(_ text: String) -> String {
        var result = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove diacritics
        result = result.folding(options: .diacriticInsensitive, locale: .current)

        // "&" reads as "and" — it would otherwise vanish with the punctuation.
        result = result.replacingOccurrences(of: "&", with: " and ")

        // Remove non-alphanumeric characters except spaces
        result = result.components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted).joined(separator: " ")

        // Collapse multiple spaces and spell out the "St." abbreviation.
        result = result.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .map { $0 == "st" ? "saint" : $0 }
            .joined(separator: " ")

        // Remove leading "the "
        if result.hasPrefix("the ") {
            result = String(result.dropFirst(4))
        }

        return result
    }

    static func == (lhs: Country, rhs: Country) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
