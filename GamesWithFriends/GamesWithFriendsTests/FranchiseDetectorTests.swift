import XCTest
@testable import GamesWithFriends

final class FranchiseDetectorTests: XCTestCase {
    private func movie(_ title: String, votes: Int) -> Movie {
        Movie(tconst: title, title: title, year: 2010, genres: "Action", rating: 7.0, votes: votes)
    }

    func testDetectsSequelStemAcrossNumberedTitles() {
        let movies = [movie("Iron Man", votes: 300_000),
                      movie("Iron Man 2", votes: 250_000),
                      movie("Iron Man 3", votes: 200_000)]
        let franchises = FranchiseDetector.detect(in: movies, tuning: .default)
        XCTAssertEqual(franchises.count, 1)
        XCTAssertEqual(franchises.first?.films.count, 3)
        XCTAssertEqual(franchises.first?.displayName, "Iron Man")
    }

    func testDetectsSubtitleStem() {
        let movies = [movie("Avengers: Infinity War", votes: 400_000),
                      movie("Avengers: Endgame", votes: 500_000)]
        let franchises = FranchiseDetector.detect(in: movies, tuning: .default)
        XCTAssertEqual(franchises.first?.displayName, "Avengers")
    }

    func testDoesNotFalseMatchSimilarFirstWord() {
        let movies = [movie("Love Actually", votes: 200_000),
                      movie("Love & Other Drugs", votes: 150_000)]
        let franchises = FranchiseDetector.detect(in: movies, tuning: .default)
        XCTAssertTrue(franchises.isEmpty)
    }

    func testRequiresRecognizableCombinedVotes() {
        let movies = [movie("Obscure Saga", votes: 5_000),
                      movie("Obscure Saga 2", votes: 4_000)]
        let franchises = FranchiseDetector.detect(in: movies, tuning: .default)
        XCTAssertTrue(franchises.isEmpty)
    }
}
