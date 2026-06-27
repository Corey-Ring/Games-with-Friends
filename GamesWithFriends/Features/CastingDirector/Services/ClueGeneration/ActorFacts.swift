import Foundation

struct GenreCount: Equatable {
    let genre: String
    let count: Int
}

struct DirectorCredit: Equatable {
    let director: Director
    let count: Int
    let topMovie: Movie   // their highest-vote movie with this actor
}

/// Pure, fully-derived view of everything the clue builders need about an actor.
struct ActorFacts {
    let actor: Actor
    let movies: [Movie]                 // sorted by votes desc
    let totalCredits: Int
    let sortedGenres: [GenreCount]      // desc by count
    let topGenreShare: Double
    let breakoutDecade: Int?            // decade of earliest recognizable film
    let careerSpanYears: Int
    let acclaimedFilms: [Movie]         // rating >= acclaimRating, votes desc
    let blockbusterFilms: [Movie]       // votes >= blockbusterVotes
    let signatureFilms: [Movie]         // recognizable (votes >= anchoredFilmMinVotes)
    let directorsByFrequency: [DirectorCredit]   // desc by count, then movie votes
    let coStars: [Actor]                // qualified, from high-vote films, fame order
    let franchises: [Franchise]
    let tuning: ClueTuning

    init(actor: Actor,
         movies rawMovies: [Movie],
         directorsByMovie: [String: [Director]],
         coStarsByMovie: [String: [Actor]],
         qualifiedPool: Set<String>,
         tuning: ClueTuning) {
        self.actor = actor
        self.tuning = tuning

        let sorted = rawMovies.sorted { ($0.votes ?? 0) > ($1.votes ?? 0) }
        self.movies = sorted
        self.totalCredits = sorted.count

        // Genre frequency
        var genreFreq: [String: Int] = [:]
        for movie in sorted {
            guard let genres = movie.genres else { continue }
            for raw in genres.components(separatedBy: ",") {
                let g = raw.trimmingCharacters(in: .whitespaces)
                guard !g.isEmpty else { continue }
                genreFreq[g, default: 0] += 1
            }
        }
        let sortedGenres = genreFreq
            .map { GenreCount(genre: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
        self.sortedGenres = sortedGenres
        self.topGenreShare = sorted.isEmpty ? 0
            : Double(sortedGenres.first?.count ?? 0) / Double(sorted.count)

        // Decades
        let years = sorted.compactMap(\.year)
        self.careerSpanYears = (years.max() ?? 0) - (years.min() ?? 0)

        let earliestRecognizable = sorted
            .filter { ($0.votes ?? 0) >= tuning.anchoredFilmMinVotes }
            .compactMap(\.year)
            .min() ?? years.min()
        self.breakoutDecade = earliestRecognizable.map { ($0 / 10) * 10 }

        // Acclaim / blockbusters / signature
        self.acclaimedFilms = sorted.filter { ($0.rating ?? 0) >= tuning.acclaimRating }
        self.blockbusterFilms = sorted.filter { ($0.votes ?? 0) >= tuning.blockbusterVotes }
        let signature = sorted.filter { ($0.votes ?? 0) >= tuning.anchoredFilmMinVotes }
        self.signatureFilms = signature.isEmpty ? Array(sorted.prefix(3)) : signature

        // Directors by frequency (representative top movie = their highest-vote film)
        var counts: [String: (director: Director, count: Int, top: Movie)] = [:]
        for movie in sorted {
            for director in directorsByMovie[movie.tconst] ?? [] {
                if let existing = counts[director.nconst] {
                    let top = (movie.votes ?? 0) > (existing.top.votes ?? 0) ? movie : existing.top
                    counts[director.nconst] = (director, existing.count + 1, top)
                } else {
                    counts[director.nconst] = (director, 1, movie)
                }
            }
        }
        self.directorsByFrequency = counts.values
            .map { DirectorCredit(director: $0.director, count: $0.count, topMovie: $0.top) }
            .sorted {
                $0.count != $1.count ? $0.count > $1.count
                    : ($0.topMovie.votes ?? 0) > ($1.topMovie.votes ?? 0)
            }

        // Co-stars: from high-vote films only, qualified, fame order, deduped.
        var seen: Set<String> = [actor.nconst]
        var stars: [Actor] = []
        for movie in sorted where (movie.votes ?? 0) >= tuning.coStarMinMovieVotes {
            for coStar in coStarsByMovie[movie.tconst] ?? [] {
                guard !seen.contains(coStar.nconst) else { continue }
                seen.insert(coStar.nconst)
                if qualifiedPool.contains(coStar.nconst) {
                    stars.append(coStar)
                }
            }
        }
        self.coStars = stars

        self.franchises = FranchiseDetector.detect(in: sorted, tuning: tuning)
    }
}
