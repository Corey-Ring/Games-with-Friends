import XCTest
@testable import GamesWithFriends

final class ClueBuildersTests: XCTestCase {
    func testNewClueTypesHaveIcons() {
        let newTypes: [ClueType] = [.genreIdentity, .longevity, .blockbuster, .franchise]
        for type in newTypes {
            XCTAssertFalse(type.icon.isEmpty, "\(type) must have an icon")
        }
    }

    private func movie(_ id: String, year: Int? = 2010, genres: String? = "Drama",
                       rating: Double? = 7.0, votes: Int? = 100_000) -> Movie {
        Movie(tconst: id, title: id, year: year, genres: genres, rating: rating, votes: votes)
    }

    private func facts(movies: [Movie],
                       directorsByMovie: [String: [Director]] = [:],
                       coStarsByMovie: [String: [Actor]] = [:],
                       qualifiedPool: Set<String> = []) -> ActorFacts {
        ActorFacts(actor: Actor(nconst: "nm1", name: "Target", knownFor: nil),
                   movies: movies, directorsByMovie: directorsByMovie,
                   coStarsByMovie: coStarsByMovie, qualifiedPool: qualifiedPool, tuning: .default)
    }

    func testGenreIdentityFiresWhenConcentrated() {
        let f = facts(movies: [movie("a", genres: "Drama"), movie("b", genres: "Drama"),
                               movie("c", genres: "Drama"), movie("d", genres: "Comedy")])
        let clue = ClueBuilders.genreIdentity(f)
        XCTAssertNotNil(clue)
        XCTAssertEqual(clue?.type, .genreIdentity)
        XCTAssertTrue(clue?.text.contains("Drama") == true)
    }

    func testGenreIdentitySuppressedWhenSpread() {
        let f = facts(movies: [movie("a", genres: "Drama"), movie("b", genres: "Comedy"),
                               movie("c", genres: "Action"), movie("d", genres: "Horror"),
                               movie("e", genres: "Sci-Fi")])
        XCTAssertNil(ClueBuilders.genreIdentity(f))
    }

    func testLongevityFiresForLongCareerOnly() {
        let long = facts(movies: [movie("a", year: 1980), movie("b", year: 2015)])
        XCTAssertNotNil(ClueBuilders.longevity(long))
        let short = facts(movies: [movie("a", year: 2010), movie("b", year: 2015)])
        XCTAssertNil(ClueBuilders.longevity(short))
    }

    func testProlificAndSelective() {
        let prolific = facts(movies: (0..<60).map { movie("m\($0)") })
        XCTAssertEqual(ClueBuilders.prolificOrSelective(prolific)?.text, "A remarkably prolific actor")

        let selective = facts(movies: [movie("a", rating: 8.5), movie("b", rating: 8.2),
                                       movie("c", rating: 8.1)])
        XCTAssertTrue(ClueBuilders.prolificOrSelective(selective)?.text.contains("selective") == true)

        let neither = facts(movies: [movie("a", rating: 6.0), movie("b", rating: 6.0)])
        XCTAssertNil(ClueBuilders.prolificOrSelective(neither))
    }

    func testBlockbusterFiresWithEnoughBigFilms() {
        let f = facts(movies: [movie("a", votes: 600_000), movie("b", votes: 700_000)])
        XCTAssertNotNil(ClueBuilders.blockbuster(f))
        let small = facts(movies: [movie("a", votes: 600_000), movie("b", votes: 10_000)])
        XCTAssertNil(ClueBuilders.blockbuster(small))
    }

    func testFranchiseUnnamedAndNamed() {
        let movies = [Movie(tconst: "1", title: "Thor", year: 2011, genres: "Action", rating: 7.0, votes: 300_000),
                      Movie(tconst: "2", title: "Thor: Ragnarok", year: 2017, genres: "Action", rating: 7.9, votes: 400_000)]
        let f = facts(movies: movies)
        XCTAssertEqual(ClueBuilders.franchiseUnnamed(f)?.tier, .narrowing)
        XCTAssertEqual(ClueBuilders.franchiseNamed(f)?.text, "Part of the Thor franchise")
    }

    func testAcclaimFiresWithThreeHighRatedFilms() {
        let f = facts(movies: [movie("a", rating: 8.1), movie("b", rating: 8.5), movie("c", rating: 9.0)])
        XCTAssertNotNil(ClueBuilders.acclaim(f))
        let f2 = facts(movies: [movie("a", rating: 8.1), movie("b", rating: 7.0)])
        XCTAssertNil(ClueBuilders.acclaim(f2))
    }

    func testFrequentDirectorAndNamedDirectorsExcludeOverlap() {
        let movies = [movie("a", votes: 600_000), movie("b", votes: 500_000),
                      movie("c", votes: 400_000), movie("d", votes: 100_000)]
        let nolan = Director(nconst: "d1", name: "Nolan")
        let other = Director(nconst: "d2", name: "Other")
        let dirs = ["a": [nolan], "b": [nolan], "c": [nolan], "d": [other]]
        let f = facts(movies: movies, directorsByMovie: dirs)
        XCTAssertEqual(ClueBuilders.frequentDirector(f)?.text, "A regular in Nolan's films")
        let named = ClueBuilders.namedDirectors(f)
        XCTAssertFalse(named.contains { $0.text.contains("Nolan") }, "frequent director must not repeat")
        XCTAssertTrue(named.contains { $0.text.contains("Other") })
    }

    func testNamedCoStars() {
        let movies = [movie("a", votes: 600_000)]
        let costars = ["a": [Actor(nconst: "nm2", name: "Idris Elba", knownFor: nil)]]
        let f = facts(movies: movies, coStarsByMovie: costars, qualifiedPool: ["nm2"])
        XCTAssertEqual(ClueBuilders.namedCoStars(f).first?.text, "Co-starred with Idris Elba")
    }

    func testExactTitlesMostFamousLast() {
        let movies = [movie("Small", votes: 60_000), movie("Mid", votes: 200_000),
                      movie("Huge", votes: 900_000)]
        let titles = ClueBuilders.exactTitles(facts(movies: movies), count: 2)
        XCTAssertEqual(titles.count, 2)
        XCTAssertTrue(titles.last?.text.contains("Huge") == true)
        XCTAssertEqual(titles.last?.tier, .giveaway)
    }
}
