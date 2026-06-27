import Foundation

/// A detected franchise: a group of an actor's films sharing a title stem.
struct Franchise: Equatable {
    let stem: String          // normalized key, e.g. "iron man"
    let displayName: String   // human-readable, e.g. "Iron Man"
    let films: [Movie]
}

/// Pure title-stem franchise detection. Conservative by design.
enum FranchiseDetector {
    static func detect(in movies: [Movie], tuning: ClueTuning) -> [Franchise] {
        // Group films by normalized stem, keeping the shortest original title as the name.
        var groups: [String: [Movie]] = [:]
        for movie in movies {
            let stem = normalize(movie.title)
            guard !stem.isEmpty else { continue }
            groups[stem, default: []].append(movie)
        }

        var result: [Franchise] = []
        for (stem, films) in groups {
            guard films.count >= tuning.franchiseMinFilms else { continue }
            let combinedVotes = films.reduce(0) { $0 + ($1.votes ?? 0) }
            guard combinedVotes >= tuning.franchiseMinCombinedVotes else { continue }
            let display = displayName(for: films)
            result.append(Franchise(stem: stem, displayName: display, films: films))
        }
        // Stable order: most-voted franchise first.
        return result.sorted {
            $0.films.reduce(0) { $0 + ($1.votes ?? 0) } > $1.films.reduce(0) { $0 + ($1.votes ?? 0) }
        }
    }

    /// Lowercase, drop subtitle after a colon, strip trailing sequel markers.
    static func normalize(_ title: String) -> String {
        var s = title.lowercased()
        if let colon = s.firstIndex(of: ":") {
            s = String(s[..<colon])
        }
        s = s.trimmingCharacters(in: .whitespaces)
        // Strip a trailing "part N", roman numerals, or plain digits.
        let patterns = [#"\s+part\s+[ivxlcdm0-9]+$"#, #"\s+[ivxlcdm]+$"#, #"\s+\d+$"#]
        for pattern in patterns {
            if let range = s.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                s = String(s[..<range.lowerBound])
            }
        }
        return s.trimmingCharacters(in: .whitespaces)
    }

    private static func displayName(for films: [Movie]) -> String {
        // Use the normalized stem of the shortest title, title-cased from the original.
        let shortest = films.min { $0.title.count < $1.title.count } ?? films[0]
        let stem = normalize(shortest.title)
        return stem.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
