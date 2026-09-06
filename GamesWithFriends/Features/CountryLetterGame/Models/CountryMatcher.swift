import Foundation

/// Anything a player can name by one of several labels.
protocol NameMatchable {
    var labels: [String] { get }
}

extension Country: NameMatchable {}

/// Resolves a typed guess to a single entry, forgiving the slips a real
/// keyboard produces without handing out false credit.
///
/// Three passes, first hit wins:
/// 1. Exact label match after `Country.normalize` (case, accents, punctuation).
/// 2. Leading words: the guess is the first word(s) of exactly one label
///    ("Dominican" → Dominican Republic). Ambiguous prefixes ("South") fail.
/// 3. Spelling slips: closest label by edit distance, one slip on names of 5–7
///    letters and two on longer ones, first letter fixed. In multi-word names
///    each word must also stay within its own budget, so "South America" can
///    never turn into South Africa. A guess equally close to two entries
///    ("Nigera") fails rather than guess.
///
/// Names of four letters or fewer must be spelled exactly — a one-letter slip
/// there is as likely to be a different word as a typo.
enum CountryMatcher {
    static func resolve<T: NameMatchable & Equatable>(_ input: String, in candidates: [T]) -> T? {
        let query = Country.normalize(input)
        guard !query.isEmpty else { return nil }

        if let exact = candidates.first(where: { candidate in
            candidate.labels.contains { Country.normalize($0) == query }
        }) {
            return exact
        }

        if query.count >= minimumPrefixLength {
            let prefix = query + " "
            let hits = candidates.filter { candidate in
                candidate.labels.contains { Country.normalize($0).hasPrefix(prefix) }
            }
            if hits.count == 1 { return hits[0] }
            if hits.count > 1 { return nil }
        }

        return closest(to: query, in: candidates)
    }

    // MARK: - Spelling slips

    private static let minimumPrefixLength = 4

    /// Edits tolerated for a normalized guess of the given length.
    static func allowedEdits(forLength length: Int) -> Int {
        switch length {
        case ..<5: return 0
        case 5..<8: return 1
        default: return 2
        }
    }

    private static func closest<T: NameMatchable & Equatable>(to query: String, in candidates: [T]) -> T? {
        let allowed = allowedEdits(forLength: query.count)
        guard allowed > 0 else { return nil }

        var best: (candidate: T, distance: Int)?
        var tied = false

        for candidate in candidates {
            for label in candidate.labels {
                let normalized = Country.normalize(label)
                guard normalized.first == query.first,
                      abs(normalized.count - query.count) <= allowed else { continue }

                let distance = editDistance(query, normalized, limit: allowed)
                guard distance <= allowed, wordsStayClose(query, normalized) else { continue }

                if let current = best {
                    if distance < current.distance {
                        best = (candidate, distance)
                        tied = false
                    } else if distance == current.distance, current.candidate != candidate {
                        tied = true
                    }
                } else {
                    best = (candidate, distance)
                }
            }
        }

        return tied ? nil : best?.candidate
    }

    /// For guesses with the same number of words as the label, every word
    /// must be within its own slip budget (at least one, so "Rico" can still
    /// become "Rica"). Stops a whole-word swap from riding the total budget.
    private static func wordsStayClose(_ query: String, _ label: String) -> Bool {
        let queryWords = query.split(separator: " ")
        let labelWords = label.split(separator: " ")
        guard queryWords.count == labelWords.count, queryWords.count > 1 else { return true }

        return zip(queryWords, labelWords).allSatisfy { queryWord, labelWord in
            let budget = max(1, allowedEdits(forLength: labelWord.count))
            return editDistance(String(queryWord), String(labelWord), limit: budget) <= budget
        }
    }

    /// Optimal string alignment distance: insertions, deletions,
    /// substitutions and adjacent transpositions each cost one. Returns
    /// `limit + 1` early once no alignment can come in under `limit`.
    static func editDistance(_ a: String, _ b: String, limit: Int) -> Int {
        let s = Array(a), t = Array(b)
        if abs(s.count - t.count) > limit { return limit + 1 }
        if s.isEmpty { return t.count }
        if t.isEmpty { return s.count }

        var twoAgo = [Int](repeating: 0, count: t.count + 1)
        var previous = Array(0...t.count)
        var current = [Int](repeating: 0, count: t.count + 1)

        for i in 1...s.count {
            current[0] = i
            var rowMinimum = current[0]
            for j in 1...t.count {
                let cost = s[i - 1] == t[j - 1] ? 0 : 1
                var value = min(previous[j] + 1,          // deletion
                                current[j - 1] + 1,       // insertion
                                previous[j - 1] + cost)   // substitution
                if i > 1, j > 1, s[i - 1] == t[j - 2], s[i - 2] == t[j - 1] {
                    value = min(value, twoAgo[j - 2] + 1) // transposition
                }
                current[j] = value
                rowMinimum = min(rowMinimum, value)
            }
            if rowMinimum > limit { return limit + 1 }
            (twoAgo, previous, current) = (previous, current, twoAgo)
        }
        return previous[t.count]
    }
}
