import Foundation

/// Assembles builder output into the final, budget-respecting clue ladder.
enum ClueLadderAssembler {

    static func assemble(facts: ActorFacts,
                         difficulty: CastingDirectorDifficulty,
                         tuning: ClueTuning) -> [Clue] {
        // 1. Run builders by tier.
        let vague: [Clue] = [
            ClueBuilders.genreIdentity(facts),
            ClueBuilders.breakout(facts),
            ClueBuilders.longevity(facts),
            ClueBuilders.prolificOrSelective(facts),
            ClueBuilders.blockbuster(facts)
        ].compactMap { $0 }

        let narrowing: [Clue] = [
            ClueBuilders.franchiseUnnamed(facts),
            ClueBuilders.anchoredFilm(facts),
            ClueBuilders.acclaim(facts)
        ].compactMap { $0 }

        var strong: [Clue] = []
        if let freq = ClueBuilders.frequentDirector(facts) { strong.append(freq) }
        strong.append(contentsOf: ClueBuilders.namedDirectors(facts))
        if let named = ClueBuilders.franchiseNamed(facts) { strong.append(named) }
        if let combined = ClueBuilders.combinedDirectorFilm(facts) { strong.append(combined) }

        let coStarClues = ClueBuilders.namedCoStars(facts)

        // 2. Co-star placement by difficulty.
        var giveawayCoStars: [Clue] = []
        if difficulty.showCoStarsEarly {
            strong.append(contentsOf: coStarClues)
        } else {
            // Hard: relocate a single co-star to the giveaway tier.
            giveawayCoStars = coStarClues.prefix(1).map {
                Clue(text: $0.text, type: .coStar, tier: .giveaway, orderNumber: 0)
            }
        }

        // 3. Giveaway titles + relocated co-stars (reserved).
        let titles = ClueBuilders.exactTitles(facts, count: difficulty.movieTitleCluesCount)
        let reserved = giveawayCoStars + titles

        // 4. Budget: reserve giveaway slots first, then fill earlier tiers.
        let budget = difficulty.maxClues
        let reservedCount = min(reserved.count, budget)
        let earlyBudget = max(0, budget - reservedCount)
        let early = Array((vague + narrowing + strong).prefix(earlyBudget))
        var ladder = early + Array(reserved.prefix(reservedCount))

        // 5. Renumber sequentially.
        ladder = ladder.enumerated().map { index, clue in
            Clue(text: clue.text, type: clue.type, tier: clue.tier, orderNumber: index + 1)
        }
        return ladder
    }
}
