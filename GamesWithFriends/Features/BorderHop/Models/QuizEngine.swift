import Foundation

struct CountryFunFact: Codable {
    let id: String
    let name: String
    let funFacts: [String]
}

struct QuizQuestion {
    let countryId: String      // The country being quizzed (tapped country)
    let correctFact: String    // The true fact for this country
    let choices: [String]      // 4 fun fact strings, shuffled, includes correctFact
}

class QuizEngine {
    private var funFacts: [String: [String]] = [:] // countryId -> facts
    private var usedFacts: [String: Set<Int>] = [:]

    init() {
        loadFunFacts()
    }

    private func loadFunFacts() {
        guard let url = Bundle.main.url(forResource: "country_fun_facts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([CountryFunFact].self, from: data) else {
            return
        }
        for entry in entries {
            funFacts[entry.id] = entry.funFacts
        }
    }

    func resetUsedFacts() {
        usedFacts.removeAll()
    }

    /// Generate a quiz question for a target country.
    /// Returns nil if the country has no fun facts (caller should skip quiz).
    func generateQuestion(
        correctCountryId: String,
        frontierCountryIds: [String],
        graph: CountryGraph
    ) -> QuizQuestion? {
        guard let facts = funFacts[correctCountryId], !facts.isEmpty else {
            return nil
        }

        // Pick an unused fact for the correct country
        let correctFact = pickFact(for: correctCountryId, from: facts)

        // Build distractor facts from other countries
        let distractorFacts = buildDistractorFacts(
            correctId: correctCountryId,
            correctFact: correctFact,
            frontierIds: frontierCountryIds,
            graph: graph
        )

        // Combine and shuffle
        var choices = [correctFact] + distractorFacts
        choices.shuffle()

        return QuizQuestion(
            countryId: correctCountryId,
            correctFact: correctFact,
            choices: choices
        )
    }

    private func pickFact(for countryId: String, from facts: [String]) -> String {
        var used = usedFacts[countryId] ?? []

        // Reset if all facts have been used
        if used.count >= facts.count {
            used = []
        }

        let available = facts.indices.filter { !used.contains($0) }
        let index = available.randomElement() ?? 0

        usedFacts[countryId, default: []].insert(index)
        return facts[index]
    }

    /// Pick 3 distractor facts from other countries.
    /// Prefers frontier countries, then neighbors-of-frontier, then any country.
    private func buildDistractorFacts(
        correctId: String,
        correctFact: String,
        frontierIds: [String],
        graph: CountryGraph
    ) -> [String] {
        var distractorCountries: [String] = []

        // 1. Other frontier countries that have facts
        let otherFrontier = frontierIds.filter { $0 != correctId && funFacts[$0] != nil }.shuffled()
        distractorCountries.append(contentsOf: otherFrontier)

        // 2. Neighbors-of-frontier for padding
        if distractorCountries.count < 3 {
            var neighborPad: Set<String> = []
            let frontierSet = Set(frontierIds)
            for fId in frontierIds {
                for nId in graph.neighborIds(of: fId) {
                    if nId != correctId && !frontierSet.contains(nId) && funFacts[nId] != nil {
                        neighborPad.insert(nId)
                    }
                }
            }
            distractorCountries.append(contentsOf: neighborPad.shuffled())
        }

        // 3. Any country with facts as final fallback
        if distractorCountries.count < 3 {
            let used = Set(distractorCountries + [correctId])
            let remaining = funFacts.keys.filter { !used.contains($0) }.shuffled()
            distractorCountries.append(contentsOf: remaining)
        }

        // Deduplicate and pick one random fact from each distractor country
        var seen: Set<String> = [correctId]
        var facts: [String] = []
        for countryId in distractorCountries {
            guard !seen.contains(countryId) else { continue }
            seen.insert(countryId)

            if let countryFacts = funFacts[countryId], !countryFacts.isEmpty,
               let fact = countryFacts.randomElement(), fact != correctFact {
                facts.append(fact)
            }
            if facts.count >= 3 { break }
        }

        return facts
    }
}
