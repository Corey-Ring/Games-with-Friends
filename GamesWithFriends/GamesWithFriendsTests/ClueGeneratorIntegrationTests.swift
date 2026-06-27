import XCTest
@testable import GamesWithFriends

/// End-to-end verification of Casting Director clue generation against the REAL
/// bundled movie database. This proves the redesigned clue ladders are
/// distinctive (no generic count/rating clues) and that the Hard-difficulty
/// giveaway title-slot reservation bug fix holds against real data.
final class ClueGeneratorIntegrationTests: XCTestCase {

    /// Poll the shared database until it reports loaded, up to `timeout` seconds.
    /// Returns true if loaded, false if it timed out.
    private func waitForDatabase(timeout: TimeInterval = 30) -> Bool {
        let database = MovieChainDatabase.shared
        let deadline = Date().addingTimeInterval(timeout)
        while !database.isLoaded && Date() < deadline {
            // Spin the run loop so the async main-thread isLoaded flip can land.
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.25))
        }
        return database.isLoaded
    }

    func testRealClueLaddersAreDistinctiveAndReserveTitleSlot() throws {
        guard waitForDatabase() else {
            throw XCTSkip("database unavailable in test environment")
        }

        let generator = ClueGenerator()
        let qualified = generator.getQualifiedActors()
        guard !qualified.isEmpty else {
            throw XCTSkip("no qualified actors available in test environment")
        }

        let database = MovieChainDatabase.shared

        // Resolve a deterministic sample of ~8 distinct real qualified actors.
        // Sort for stability, then take the first 8 that resolve to a real Actor.
        let sampleIds = Array(qualified.sorted().prefix(40))
        var sampleActors: [Actor] = []
        for id in sampleIds {
            if let actor = database.getActor(byId: id) {
                sampleActors.append(actor)
            }
            if sampleActors.count >= 8 { break }
        }
        XCTAssertFalse(sampleActors.isEmpty, "Could not resolve any sample actors")

        // Regex for the removed generic "Appeared in N movies" count clue.
        let bareCountRegex = try NSRegularExpression(pattern: "^Appeared in \\d+ movies$")

        var printedHardLadders = 0

        for actor in sampleActors {
            for difficulty in [CastingDirectorDifficulty.hard, .medium] {
                let clues = generator.generateClues(for: actor, difficulty: difficulty)

                // Skip actors that yield no clues (no movies in DB); not a failure.
                guard !clues.isEmpty else { continue }

                let context = "\(actor.name) [\(difficulty.rawValue)]"

                // --- Acceptance criteria ---

                // 1. At least one movieTitle clue (giveaway-slot reservation bug fix).
                XCTAssertTrue(
                    clues.contains { $0.type == .movieTitle },
                    "\(context): ladder must contain at least one .movieTitle clue"
                )

                // 2. No removed generic patterns.
                for clue in clues {
                    let text = clue.text
                    let range = NSRange(text.startIndex..., in: text)
                    XCTAssertNil(
                        bareCountRegex.firstMatch(in: text, range: range),
                        "\(context): found removed bare count clue: \"\(text)\""
                    )
                    XCTAssertFalse(
                        text.contains("film rated") && text.contains("/10"),
                        "\(context): found removed bare rating clue: \"\(text)\""
                    )
                }

                // 3. orderNumber is sequential 1...n.
                XCTAssertEqual(
                    clues.map(\.orderNumber),
                    Array(1...clues.count),
                    "\(context): orderNumber must be sequential 1...n"
                )

                // 4. Tiers are non-decreasing across the ladder.
                let tiers = clues.map { $0.tier.rawValue }
                XCTAssertEqual(
                    tiers, tiers.sorted(),
                    "\(context): tiers must be non-decreasing"
                )

                // --- Print Hard ladders for human eyeballing ---
                if difficulty == .hard && printedHardLadders < 8 {
                    printedHardLadders += 1
                    print("==== CLUE LADDER [Hard] — \(actor.name) ====")
                    for clue in clues {
                        print(String(
                            format: "  %2d. (tier %d, %@) %@",
                            clue.orderNumber,
                            clue.tier.rawValue,
                            String(describing: clue.type),
                            clue.text
                        ))
                    }
                    print("")
                }
            }
        }

        XCTAssertGreaterThanOrEqual(
            printedHardLadders, 5,
            "Expected to print at least 5 Hard ladders for review"
        )
    }
}
