import Foundation

struct Country: Identifiable, Codable, Hashable, Equatable {
    let id: UUID
    let name: String
    let alternateNames: [String]

    init(name: String, alternateNames: [String] = []) {
        self.id = UUID()
        self.name = name
        self.alternateNames = alternateNames
    }

    var firstLetter: String {
        String(name.prefix(1)).uppercased()
    }

    /// Whole-string match against the display name or any alternate, after
    /// both sides go through `normalize`. Deliberately exact: fuzzy matching
    /// on a 195-entry list produces false credits (e.g. "Niger" vs "Nigeria").
    func matches(_ input: String) -> Bool {
        let normalized = Country.normalize(input)
        guard !normalized.isEmpty else { return false }

        if normalized == Country.normalize(name) {
            return true
        }

        return alternateNames.contains { normalized == Country.normalize($0) }
    }

    /// Lowercases, strips diacritics and punctuation (so "Côte d’Ivoire",
    /// "Cote d'Ivoire" and "cote d ivoire" collapse together), collapses
    /// whitespace, and drops a leading "the".
    static func normalize(_ text: String) -> String {
        var result = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove diacritics
        result = result.folding(options: .diacriticInsensitive, locale: .current)

        // Remove non-alphanumeric characters except spaces
        result = result.components(separatedBy: CharacterSet.alphanumerics.union(.whitespaces).inverted).joined(separator: " ")

        // Collapse multiple spaces
        result = result.components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")

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
