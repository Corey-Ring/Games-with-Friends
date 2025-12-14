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

    func matches(_ input: String) -> Bool {
        let normalized = normalizeInput(input)
        let normalizedName = normalizeInput(name)

        if normalized == normalizedName {
            return true
        }

        for alt in alternateNames {
            if normalized == normalizeInput(alt) {
                return true
            }
        }

        return false
    }

    private func normalizeInput(_ text: String) -> String {
        var result = text.lowercased().trimmingCharacters(in: .whitespaces)

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
