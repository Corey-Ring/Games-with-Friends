import XCTest
@testable import GamesWithFriends

final class ActorFactsTests: XCTestCase {
    private func movie(_ id: String, year: Int?, genres: String?, rating: Double?, votes: Int?) -> Movie {
        Movie(tconst: id, title: id, year: year, genres: genres, rating: rating, votes: votes)
    }

    private func makeFacts(movies: [Movie],
                           directorsByMovie: [String: [Director]] = [:],
                           coStarsByMovie: [String: [Actor]] = [:],
                           qualifiedPool: Set<String> = []) -> ActorFacts {
        ActorFacts(actor: Actor(nconst: "nm1", name: "Target", knownFor: nil),
                   movies: movies,
                   directorsByMovie: directorsByMovie,
                   coStarsByMovie: coStarsByMovie,
                   qualifiedPool: qualifiedPool,
                   tuning: .default)
    }

    func testComputesCreditsGenreAndSpan() {
        let movies = [
            movie("a", year: 2000, genres: "Drama,Crime", rating: 8.5, votes: 600_000),
            movie("b", year: 2010, genres: "Drama", rating: 7.0, votes: 100_000),
            movie("c", year: 2018, genres: "Comedy", rating: 6.0, votes: 30_000)
        ]
        let facts = makeFacts(movies: movies)
        XCTAssertEqual(facts.totalCredits, 3)
        XCTAssertEqual(facts.sortedGenres.first?.genre, "Drama")
        XCTAssertEqual(facts.careerSpanYears, 18)
    }

    func testIdentifiesAcclaimAndBlockbusters() {
        let movies = [
            movie("a", year: 2000, genres: "Drama", rating: 8.5, votes: 600_000),
            movie("b", year: 2005, genres: "Drama", rating: 8.1, votes: 700_000),
            movie("c", year: 2010, genres: "Drama", rating: 9.0, votes: 40_000)
        ]
        let facts = makeFacts(movies: movies)
        XCTAssertEqual(facts.acclaimedFilms.count, 3)
        XCTAssertEqual(facts.blockbusterFilms.count, 2)
    }

    func testGathersQualifiedCoStarsFromHighVoteFilmsOnly() {
        let movies = [
            movie("a", year: 2000, genres: "Drama", rating: 8.0, votes: 600_000),
            movie("b", year: 2005, genres: "Drama", rating: 7.0, votes: 5_000)
        ]
        let coStars = [
            "a": [Actor(nconst: "nm2", name: "Famous", knownFor: nil),
                  Actor(nconst: "nm3", name: "Unknown", knownFor: nil)],
            "b": [Actor(nconst: "nm4", name: "LowVoteFilmCoStar", knownFor: nil)]
        ]
        let facts = makeFacts(movies: movies, coStarsByMovie: coStars, qualifiedPool: ["nm2"])
        // Only nm2 is qualified, and only film "a" clears coStarMinMovieVotes.
        XCTAssertEqual(facts.coStars.map(\.nconst), ["nm2"])
    }

    func testRanksDirectorsByCollaborationCount() {
        let movies = [
            movie("a", year: 2000, genres: "Drama", rating: 8.0, votes: 600_000),
            movie("b", year: 2005, genres: "Drama", rating: 8.0, votes: 500_000),
            movie("c", year: 2010, genres: "Drama", rating: 8.0, votes: 100_000)
        ]
        let nolan = Director(nconst: "d1", name: "Nolan")
        let other = Director(nconst: "d2", name: "Other")
        let dirs = ["a": [nolan], "b": [nolan], "c": [other]]
        let facts = makeFacts(movies: movies, directorsByMovie: dirs)
        XCTAssertEqual(facts.directorsByFrequency.first?.director.name, "Nolan")
        XCTAssertEqual(facts.directorsByFrequency.first?.count, 2)
    }
}
