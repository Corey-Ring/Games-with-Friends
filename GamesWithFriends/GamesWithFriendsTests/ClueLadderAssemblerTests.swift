import XCTest
@testable import GamesWithFriends

final class ClueLadderAssemblerTests: XCTestCase {
    private func movie(_ id: String, year: Int = 2010, genres: String = "Drama",
                       rating: Double = 8.5, votes: Int) -> Movie {
        Movie(tconst: id, title: id, year: year, genres: genres, rating: rating, votes: votes)
    }

    /// A rich actor that triggers many gates, used to stress the budget/reservation logic.
    private func richFacts() -> ActorFacts {
        let movies = (0..<12).map { movie("Film\($0)", year: 1985 + $0, votes: 100_000 + $0 * 50_000) }
        let nolan = Director(nconst: "d1", name: "Nolan")
        var dirs: [String: [Director]] = [:]
        for m in movies.prefix(4) { dirs[m.tconst] = [nolan] }
        let costars = ["Film11": [Actor(nconst: "nm2", name: "Idris Elba", knownFor: nil),
                                  Actor(nconst: "nm3", name: "Emma Stone", knownFor: nil)]]
        return ActorFacts(actor: Actor(nconst: "nm1", name: "Target", knownFor: nil),
                          movies: movies, directorsByMovie: dirs, coStarsByMovie: costars,
                          qualifiedPool: ["nm2", "nm3"], tuning: .default)
    }

    func testLadderIsTierOrderedAndRenumbered() {
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .easy, tuning: .default)
        XCTAssertFalse(clues.isEmpty)
        // orderNumber is sequential from 1
        XCTAssertEqual(clues.map(\.orderNumber), Array(1...clues.count))
        // tiers never decrease across the ladder
        let tiers = clues.map { $0.tier.rawValue }
        XCTAssertEqual(tiers, tiers.sorted())
    }

    func testRespectsMaxCluesBudget() {
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .hard, tuning: .default)
        XCTAssertLessThanOrEqual(clues.count, CastingDirectorDifficulty.hard.maxClues)
    }

    func testReservesGiveawayTitleSlotOnHard() {
        // The core bug fix: titles must survive the Hard budget of 8.
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .hard, tuning: .default)
        XCTAssertTrue(clues.contains { $0.type == .movieTitle },
                      "at least one exact-title clue must appear within the Hard budget")
    }

    func testHardModeMovesCoStarsLate() {
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .hard, tuning: .default)
        if let coStar = clues.first(where: { $0.type == .coStar }) {
            XCTAssertEqual(coStar.tier, .giveaway, "Hard mode co-stars belong in the giveaway tier")
        }
    }

    func testTopDirectorNamedAtMostOnce() {
        let clues = ClueLadderAssembler.assemble(facts: richFacts(), difficulty: .easy, tuning: .default)
        let nolanMentions = clues.filter { $0.text.contains("Nolan") }.count
        XCTAssertLessThanOrEqual(nolanMentions, 1, "a director must not be named in more than one clue")
    }

    func testFallbackActorStillGetsTitle() {
        // Actor that triggers no special gates: few films, mixed genres, short career, low ratings.
        let movies = [movie("A", year: 2018, genres: "Drama", rating: 6.0, votes: 60_000),
                      movie("B", year: 2019, genres: "Comedy", rating: 6.2, votes: 80_000),
                      movie("C", year: 2020, genres: "Action", rating: 6.1, votes: 120_000)]
        let facts = ActorFacts(actor: Actor(nconst: "nm9", name: "Plain", knownFor: nil),
                               movies: movies, directorsByMovie: [:], coStarsByMovie: [:],
                               qualifiedPool: [], tuning: .default)
        let clues = ClueLadderAssembler.assemble(facts: facts, difficulty: .medium, tuning: .default)
        XCTAssertTrue(clues.contains { $0.type == .movieTitle })
        XCTAssertFalse(clues.isEmpty)
    }
}
