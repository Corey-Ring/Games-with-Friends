import XCTest
@testable import GamesWithFriends

/// Border Hop's "Start Game" silently no-ops if route generation returns nil.
/// This exercises every difficulty (Expert's 12-hop minimum is the tightest
/// constraint) enough times that a real reliability problem would surface.
final class BorderHopRouteGenerationTests: XCTestCase {

    func testEveryDifficultyGeneratesRoutesReliably() {
        let graph = CountryGraph(countries: BorderHopCountryData.loadCountries())

        for difficulty in BorderHopDifficulty.allCases {
            for attempt in 0..<50 {
                guard let route = graph.generateRoute(difficulty: difficulty) else {
                    XCTFail("generateRoute returned nil for \(difficulty.rawValue) on attempt \(attempt)")
                    return
                }
                XCTAssertGreaterThanOrEqual(
                    route.optimalPath.count - 1,
                    difficulty.minHops,
                    "\(difficulty.rawValue) route shorter than its minimum hop count"
                )
                XCTAssertEqual(route.optimalPath.first, route.startId)
                XCTAssertEqual(route.optimalPath.last, route.destinationId)
            }
        }
    }
}
