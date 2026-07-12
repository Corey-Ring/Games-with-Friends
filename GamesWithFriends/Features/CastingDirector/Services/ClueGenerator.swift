import Foundation

/// Generates ordered clues for a target actor by querying MovieChainDatabase
final class ClueGenerator {
    private let database = MovieChainDatabase.shared

    // MARK: - Big Actor Pool

    /// Cached list of qualifying actor nconst IDs (5+ movies, 3+ with 50k+ votes)
    private static var qualifiedActorIds: [String]?
    private static var usedActorIdsThisSession: Set<String> = []

    /// Build or return the cached pool of "big actors"
    func getQualifiedActors() -> [String] {
        if let cached = Self.qualifiedActorIds {
            return cached
        }

        // Check UserDefaults cache first
        if let cached = UserDefaults.standard.array(forKey: "casting_director_qualified_actors") as? [String], !cached.isEmpty {
            Self.qualifiedActorIds = cached
            return cached
        }

        // Query the database for qualifying actors
        let ids = buildQualifiedActorPool()
        Self.qualifiedActorIds = ids
        UserDefaults.standard.set(ids, forKey: "casting_director_qualified_actors")
        return ids
    }

    private func buildQualifiedActorPool() -> [String] {
        guard database.isLoaded else { return [] }

        // Single efficient SQL query: actors with 5+ movies, 3+ having 50k+ votes
        let qualified = database.getQualifiedActorIds(minMovies: 5, minHighVoteMovies: 3, minVotes: 50000)
        print("ClueGenerator: Found \(qualified.count) qualified actors")
        return qualified
    }

    /// Reset session tracking (call when starting a new game session)
    func resetSession() {
        Self.usedActorIdsThisSession.removeAll()
    }

    /// Median filmography year per actor, cached for the app session — era
    /// probes are a years-only query the first time and free afterward.
    private static var medianYearCache: [String: Int] = [:]

    /// True when the last pick had to ignore the requested era because no
    /// matching actor was found. The ViewModel surfaces this to the player
    /// instead of silently serving a wrong-era actor.
    private(set) var lastPickIgnoredEra = false

    /// Pick a random actor from the qualified pool, avoiding recent repeats.
    /// When an era is selected, walk the shuffled pool until one's career fits
    /// (falling back to any actor — with `lastPickIgnoredEra` set — only when
    /// no candidate in the walk matches).
    func pickRandomActor(era: CastingDirectorEra = .allEras) -> Actor? {
        lastPickIgnoredEra = false

        let pool = getQualifiedActors()
        let available = pool.filter { !Self.usedActorIdsThisSession.contains($0) }

        // If we've used all actors, reset
        let candidates = (available.isEmpty ? pool : available).shuffled()

        if era != .allEras {
            // 400 cached-median probes make an all-miss astronomically
            // unlikely for any populated era, while bounding first-round cost
            // if an era bucket is genuinely empty.
            for id in candidates.prefix(400) {
                if matchesEra(actorId: id, era: era), let actor = database.getActor(byId: id) {
                    Self.usedActorIdsThisSession.insert(id)
                    return actor
                }
            }
            // No era match found — fall back to any actor rather than a dead
            // Start button, but tell the caller so the UI can say so.
            lastPickIgnoredEra = true
        }

        guard let randomId = candidates.first else { return nil }
        Self.usedActorIdsThisSession.insert(randomId)
        return database.getActor(byId: randomId)
    }

    /// An actor "belongs" to an era when the median release year of their
    /// filmography falls inside it.
    private func matchesEra(actorId: String, era: CastingDirectorEra) -> Bool {
        guard let median = medianYear(for: actorId) else { return false }

        switch era {
        case .allEras: return true
        case .classic: return median < 1990
        case .modern: return (1990..<2010).contains(median)
        case .recent: return median >= 2010
        }
    }

    private func medianYear(for actorId: String) -> Int? {
        if let cached = Self.medianYearCache[actorId] {
            return cached == 0 ? nil : cached
        }

        let years = database.getMovieYears(forActorId: actorId).sorted()
        guard !years.isEmpty else {
            Self.medianYearCache[actorId] = 0 // sentinel: no dated films
            return nil
        }

        let median = years[years.count / 2]
        Self.medianYearCache[actorId] = median
        return median
    }

    // MARK: - Clue Generation

    /// Generate an ordered array of clues for the given actor, respecting difficulty settings.
    func generateClues(for actor: Actor, difficulty: CastingDirectorDifficulty) -> [Clue] {
        let movies = database.getMoviesWithActor(actorId: actor.nconst)
        guard !movies.isEmpty else { return [] }

        let tuning = ClueTuning.default
        let qualifiedPool = Set(getQualifiedActors())

        // Fetch raw directors and co-stars per movie (the only DB-touching step).
        var directorsByMovie: [String: [Director]] = [:]
        var coStarsByMovie: [String: [Actor]] = [:]
        for movie in movies {
            directorsByMovie[movie.tconst] = database.getDirectorsOfMovie(movieId: movie.tconst)
            if (movie.votes ?? 0) >= tuning.coStarMinMovieVotes {
                coStarsByMovie[movie.tconst] = database.getActorsInMovie(movieId: movie.tconst)
            }
        }

        let facts = ActorFacts(actor: actor,
                               movies: movies,
                               directorsByMovie: directorsByMovie,
                               coStarsByMovie: coStarsByMovie,
                               qualifiedPool: qualifiedPool,
                               tuning: tuning)

        return ClueLadderAssembler.assemble(facts: facts, difficulty: difficulty, tuning: tuning)
    }
}
