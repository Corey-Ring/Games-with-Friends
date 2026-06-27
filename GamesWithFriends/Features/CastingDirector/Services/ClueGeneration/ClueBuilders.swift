import Foundation

/// Pure builders. Each returns a clue only when its distinctiveness gate passes.
/// `orderNumber` is a placeholder (0); the assembler renumbers.
enum ClueBuilders {

    private static func clue(_ text: String, _ type: ClueType, _ tier: ClueTier) -> Clue {
        Clue(text: text, type: type, tier: tier, orderNumber: 0)
    }

    // MARK: Vague

    static func genreIdentity(_ f: ActorFacts) -> Clue? {
        guard let top = f.sortedGenres.first, f.topGenreShare >= f.tuning.genreIdentityShare else { return nil }
        if f.sortedGenres.count >= 2 {
            let second = f.sortedGenres[1]
            return clue("Best known for \(top.genre) and \(second.genre)", .genreIdentity, .vague)
        }
        return clue("Best known for \(top.genre)", .genreIdentity, .vague)
    }

    static func breakout(_ f: ActorFacts) -> Clue? {
        guard let decade = f.breakoutDecade else { return nil }
        return clue("First gained recognition in the \(decade)s", .decade, .vague)
    }

    static func longevity(_ f: ActorFacts) -> Clue? {
        guard f.careerSpanYears >= f.tuning.longevitySpanYears else { return nil }
        let rounded = (f.careerSpanYears / 10) * 10
        return clue("Has been working for over \(rounded) years", .longevity, .vague)
    }

    static func prolificOrSelective(_ f: ActorFacts) -> Clue? {
        if f.totalCredits >= f.tuning.prolificThreshold {
            return clue("A remarkably prolific actor", .movieCount, .vague)
        }
        if f.totalCredits <= f.tuning.selectiveMaxCredits && f.acclaimedFilms.count >= 3 {
            return clue("A selective actor with a small but acclaimed body of work", .movieCount, .vague)
        }
        return nil
    }

    static func blockbuster(_ f: ActorFacts) -> Clue? {
        guard f.blockbusterFilms.count >= f.tuning.blockbusterCount else { return nil }
        return clue("Star of several blockbusters", .blockbuster, .vague)
    }

    // MARK: Narrowing

    static func franchiseUnnamed(_ f: ActorFacts) -> Clue? {
        guard !f.franchises.isEmpty else { return nil }
        return clue("Has a recurring role in a major franchise", .franchise, .narrowing)
    }

    static func anchoredFilm(_ f: ActorFacts) -> Clue? {
        // Prefer a recognizable, acclaimed film with a year and genre.
        let candidate = f.signatureFilms.first { $0.year != nil && $0.genres != nil }
        guard let movie = candidate, let year = movie.year else { return nil }
        let genre = movie.genres?.components(separatedBy: ",").first?
            .trimmingCharacters(in: .whitespaces).lowercased() ?? "film"
        let acclaimed = (movie.rating ?? 0) >= f.tuning.acclaimRating
        let lead = acclaimed ? "Led an acclaimed" : "Appeared in a"
        return clue("\(lead) \(year) \(genre) film", .movieYearGenre, .narrowing)
    }

    static func acclaim(_ f: ActorFacts) -> Clue? {
        guard f.acclaimedFilms.count >= f.tuning.acclaimCount else { return nil }
        let threshold = String(format: "%.1f", f.tuning.acclaimRating)
        return clue("Has several films rated above \(threshold)", .rating, .narrowing)
    }

    // MARK: Strong

    static func frequentDirector(_ f: ActorFacts) -> Clue? {
        guard let top = f.directorsByFrequency.first, top.count >= f.tuning.frequentDirectorCount else { return nil }
        return clue("A regular in \(top.director.name)'s films", .director, .strongSignal)
    }

    /// Named directors other than the top-ranked one (the top director is covered by
    /// `frequentDirector` or `combinedDirectorFilm`), excluding any frequent collaborators.
    static func namedDirectors(_ f: ActorFacts, limit: Int = 2) -> [Clue] {
        f.directorsByFrequency
            .enumerated()
            .filter { index, credit in index != 0 && credit.count < f.tuning.frequentDirectorCount }
            .prefix(limit)
            .map { clue("Worked with director \($0.element.director.name)", .director, .strongSignal) }
    }

    static func namedCoStars(_ f: ActorFacts, limit: Int = 2) -> [Clue] {
        f.coStars.prefix(limit).map { clue("Co-starred with \($0.name)", .coStar, .strongSignal) }
    }

    static func franchiseNamed(_ f: ActorFacts) -> Clue? {
        guard let franchise = f.franchises.first else { return nil }
        return clue("Part of the \(franchise.displayName) franchise", .franchise, .strongSignal)
    }

    static func combinedDirectorFilm(_ f: ActorFacts) -> Clue? {
        guard let top = f.directorsByFrequency.first, let year = top.topMovie.year else { return nil }
        return clue("Appeared in a \(year) film directed by \(top.director.name)", .combined, .strongSignal)
    }

    // MARK: Giveaway

    /// Exact titles spread across fame levels, most famous revealed last.
    static func exactTitles(_ f: ActorFacts, count: Int) -> [Clue] {
        let byFame = f.movies.sorted { ($0.votes ?? 0) < ($1.votes ?? 0) }
        guard count > 0, !byFame.isEmpty else { return [] }

        let selected: [Movie]
        if byFame.count <= count {
            selected = byFame
        } else {
            var picks: [Movie] = []
            let step = max(1, byFame.count / count)
            for i in 0..<count {
                picks.append(byFame[min(i * step, byFame.count - 1)])
            }
            if let mostFamous = byFame.last, picks.last?.tconst != mostFamous.tconst {
                picks[picks.count - 1] = mostFamous
            }
            selected = picks
        }
        return selected.map { clue("Appeared in \"\($0.displayTitle)\"", .movieTitle, .giveaway) }
    }
}
