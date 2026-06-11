import Foundation

struct CountryFunFact: Codable {
    let id: String
    let name: String
    let funFacts: [String]
}

struct QuizQuestion {
    let type: QuizType
    let countryId: String           // alpha-3 code of the country being quizzed

    // String-answer fields (type == .funFact or .export).
    // For fun facts: the correct short fact + 4 shuffled fact choices.
    // For exports: the country's #1 export commodity + 4 shuffled commodity choices.
    let correctFact: String?
    let factChoices: [String]?

    // Country-answer fields (type == .flagIdentification or .capital):
    // 4 shuffled alpha-3 country IDs rendered as flag emoji / capital city names.
    let countryChoices: [String]?
}

class QuizEngine {
    private var funFacts: [String: [String]] = [:] // countryId -> facts
    private var usedFacts: [String: Set<Int>] = [:]
    private var typeSelector = QuizTypeSelector()

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

    func resetTypeSelector() {
        typeSelector.reset()
    }

    // MARK: - Public Generation

    /// Generate a quiz question for a target country.
    /// Returns nil only if both quiz types are completely unavailable (extremely rare).
    func generateQuestion(
        correctCountryId: String,
        frontierCountryIds: [String],
        graph: CountryGraph
    ) -> QuizQuestion? {
        let type = typeSelector.nextType()

        switch type {
        case .flagIdentification:
            // Try flag first, fall back to fact
            return generateFlagQuestion(correctCountryId: correctCountryId, graph: graph)
                ?? generateFactQuestion(correctCountryId: correctCountryId, frontierCountryIds: frontierCountryIds, graph: graph)
        case .funFact:
            // Try fact first, fall back to flag
            return generateFactQuestion(correctCountryId: correctCountryId, frontierCountryIds: frontierCountryIds, graph: graph)
                ?? generateFlagQuestion(correctCountryId: correctCountryId, graph: graph)
        case .export:
            // Try export first, fall back to fact, then flag
            return generateExportQuestion(correctCountryId: correctCountryId)
                ?? generateFactQuestion(correctCountryId: correctCountryId, frontierCountryIds: frontierCountryIds, graph: graph)
                ?? generateFlagQuestion(correctCountryId: correctCountryId, graph: graph)
        case .capital:
            // Try capital first, fall back to fact, then flag
            return generateCapitalQuestion(correctCountryId: correctCountryId, graph: graph)
                ?? generateFactQuestion(correctCountryId: correctCountryId, frontierCountryIds: frontierCountryIds, graph: graph)
                ?? generateFlagQuestion(correctCountryId: correctCountryId, graph: graph)
        }
    }

    // MARK: - Fun Fact Generation

    private func generateFactQuestion(
        correctCountryId: String,
        frontierCountryIds: [String],
        graph: CountryGraph
    ) -> QuizQuestion? {
        guard let facts = funFacts[correctCountryId], !facts.isEmpty else {
            return nil
        }

        let correctFact = pickFact(for: correctCountryId, from: facts)
        let distractorFacts = buildDistractorFacts(
            correctId: correctCountryId,
            correctFact: correctFact,
            frontierIds: frontierCountryIds,
            graph: graph
        )

        var choices = [correctFact] + distractorFacts
        choices.shuffle()

        return QuizQuestion(
            type: .funFact,
            countryId: correctCountryId,
            correctFact: correctFact,
            factChoices: choices,
            countryChoices: nil
        )
    }

    private func pickFact(for countryId: String, from facts: [String]) -> String {
        var used = usedFacts[countryId] ?? []

        if used.count >= facts.count {
            used = []
        }

        let available = facts.indices.filter { !used.contains($0) }
        let index = available.randomElement() ?? 0

        usedFacts[countryId, default: []].insert(index)
        return facts[index]
    }

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

        // Pick one random fact from each distractor country
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

    // MARK: - Flag Generation

    private func generateFlagQuestion(
        correctCountryId: String,
        graph: CountryGraph
    ) -> QuizQuestion? {
        // Correct country must have a mappable flag emoji
        guard CountryFlagProvider.flag(for: correctCountryId) != nil else {
            return nil
        }

        let distractors = buildFlagDistractors(
            correctId: correctCountryId,
            graph: graph
        )

        guard !distractors.isEmpty else { return nil }

        var choices = [correctCountryId] + distractors
        choices.shuffle()

        return QuizQuestion(
            type: .flagIdentification,
            countryId: correctCountryId,
            correctFact: nil,
            factChoices: nil,
            countryChoices: choices
        )
    }

    /// Build 3 distractor country IDs for a flag quiz.
    /// Priority: similar flags → same region → random (never includes direct neighbors).
    private func buildFlagDistractors(
        correctId: String,
        graph: CountryGraph
    ) -> [String] {
        let neighbors = graph.neighborIds(of: correctId)
        let correctRegion = graph.country(for: correctId)?.region
        let allIds = Set(graph.allCountryIds)

        var distractors: [String] = []
        var seen: Set<String> = [correctId]
        seen.formUnion(neighbors) // never use direct neighbors as distractors

        // Tier 1: Visually similar flags
        let similar = CountryFlagProvider.similarCountries(to: correctId)
            .filter { allIds.contains($0) && !seen.contains($0) && CountryFlagProvider.flag(for: $0) != nil }
            .shuffled()
        for id in similar {
            if distractors.count >= 2 { break } // up to 2 from similar-flag group
            distractors.append(id)
            seen.insert(id)
        }

        // Tier 2: Same region countries
        if distractors.count < 3, let region = correctRegion {
            let sameRegion = graph.allCountries
                .filter {
                    $0.region == region &&
                    !seen.contains($0.id) &&
                    CountryFlagProvider.flag(for: $0.id) != nil
                }
                .map { $0.id }
                .shuffled()
            for id in sameRegion {
                if distractors.count >= 3 { break }
                distractors.append(id)
                seen.insert(id)
            }
        }

        // Tier 3: Any remaining country
        if distractors.count < 3 {
            let fallback = allIds
                .filter { !seen.contains($0) && CountryFlagProvider.flag(for: $0) != nil }
                .shuffled()
            for id in fallback {
                if distractors.count >= 3 { break }
                distractors.append(id)
                seen.insert(id)
            }
        }

        return distractors
    }

    // MARK: - Export Generation

    /// "What's {country}'s #1 export?" — one glanceable commodity per choice,
    /// instead of the old four lists of five commodities each.
    private func generateExportQuestion(
        correctCountryId: String
    ) -> QuizQuestion? {
        guard let exports = CountryExportProvider.exports(for: correctCountryId),
              let topExport = exports.first else {
            return nil
        }

        let distractors = CountryExportProvider.distractorExports(
            excluding: correctCountryId,
            count: 3
        )
        guard distractors.count >= 3 else { return nil }

        var choices = [topExport] + distractors
        choices.shuffle()

        return QuizQuestion(
            type: .export,
            countryId: correctCountryId,
            correctFact: topExport,
            factChoices: choices,
            countryChoices: nil
        )
    }

    // MARK: - Capital Generation

    private func generateCapitalQuestion(
        correctCountryId: String,
        graph: CountryGraph
    ) -> QuizQuestion? {
        // Correct country must have a non-empty capital
        guard let correct = graph.country(for: correctCountryId),
              !correct.capital.isEmpty else {
            return nil
        }

        let distractors = buildCapitalDistractors(
            correctId: correctCountryId,
            graph: graph
        )

        guard distractors.count >= 3 else { return nil }

        var choices = [correctCountryId] + distractors
        choices.shuffle()

        return QuizQuestion(
            type: .capital,
            countryId: correctCountryId,
            correctFact: nil,
            factChoices: nil,
            countryChoices: choices
        )
    }

    /// Build 3 distractor country IDs for a capital quiz.
    /// Priority: same region → random (never includes direct neighbors).
    /// Only countries with non-empty capitals are eligible.
    private func buildCapitalDistractors(
        correctId: String,
        graph: CountryGraph
    ) -> [String] {
        let neighbors = graph.neighborIds(of: correctId)
        let correctRegion = graph.country(for: correctId)?.region

        var distractors: [String] = []
        var seen: Set<String> = [correctId]
        seen.formUnion(neighbors) // never use direct neighbors as distractors

        // Tier 1: Same region countries
        if let region = correctRegion {
            let sameRegion = graph.allCountries
                .filter {
                    $0.region == region &&
                    !seen.contains($0.id) &&
                    !$0.capital.isEmpty
                }
                .map { $0.id }
                .shuffled()
            for id in sameRegion {
                if distractors.count >= 3 { break }
                distractors.append(id)
                seen.insert(id)
            }
        }

        // Tier 2: Any remaining country with a capital
        if distractors.count < 3 {
            let fallback = graph.allCountries
                .filter { !seen.contains($0.id) && !$0.capital.isEmpty }
                .map { $0.id }
                .shuffled()
            for id in fallback {
                if distractors.count >= 3 { break }
                distractors.append(id)
                seen.insert(id)
            }
        }

        return distractors
    }
}
