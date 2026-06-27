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

    /// Pick a random actor from the qualified pool, avoiding recent repeats
    func pickRandomActor() -> Actor? {
        let pool = getQualifiedActors()
        let available = pool.filter { !Self.usedActorIdsThisSession.contains($0) }

        // If we've used all actors, reset
        let candidates = available.isEmpty ? pool : available

        guard let randomId = candidates.randomElement() else { return nil }
        Self.usedActorIdsThisSession.insert(randomId)
        return database.getActor(byId: randomId)
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
