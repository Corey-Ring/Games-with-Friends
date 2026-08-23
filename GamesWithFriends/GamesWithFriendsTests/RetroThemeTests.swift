import XCTest
import SwiftUI
@testable import GamesWithFriends

final class RetroThemeTests: XCTestCase {

    private func assertSameColor(_ color: Color, hex: String,
                                 file: StaticString = #filePath, line: UInt = #line) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var er: CGFloat = 0, eg: CGFloat = 0, eb: CGFloat = 0, ea: CGFloat = 0
        XCTAssertTrue(UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a), file: file, line: line)
        XCTAssertTrue(UIColor(Color(hex: hex)).getRed(&er, green: &eg, blue: &eb, alpha: &ea), file: file, line: line)
        XCTAssertEqual(r, er, accuracy: 0.005, "red of \(hex)", file: file, line: line)
        XCTAssertEqual(g, eg, accuracy: 0.005, "green of \(hex)", file: file, line: line)
        XCTAssertEqual(b, eb, accuracy: 0.005, "blue of \(hex)", file: file, line: line)
    }

    func testCandyPaletteMatchesArtDirection() {
        assertSameColor(AppTheme.Retro.mustard, hex: "F2B417")
        assertSameColor(AppTheme.Retro.cream, hex: "FBF2E0")
        assertSameColor(AppTheme.Retro.ink, hex: "1B1B1B")
        assertSameColor(AppTheme.Retro.cocoa, hex: "55351D")
        assertSameColor(AppTheme.Retro.bubblegum, hex: "F387B8")
        assertSameColor(AppTheme.Retro.tomato, hex: "E8442E")
        assertSameColor(AppTheme.Retro.tangerine, hex: "F07C24")
        assertSameColor(AppTheme.Retro.cornflower, hex: "6C9BD2")
        assertSameColor(AppTheme.Retro.poolBlue, hex: "5BC0DF")
        assertSameColor(AppTheme.Retro.grass, hex: "57A34F")
        assertSameColor(AppTheme.Retro.lilac, hex: "A08BE0")
        assertSameColor(AppTheme.Retro.berry, hex: "C64B7E")
        assertSameColor(AppTheme.Retro.plum, hex: "8E4585")
    }

    func testDisplayFontsRegister() {
        RetroFonts.registerAll()
        XCTAssertNotNil(UIFont(name: "Shrikhand-Regular", size: 20),
                        "Shrikhand not registered — check bundle resource + PostScript name")
        XCTAssertNotNil(UIFont(name: "LilitaOne", size: 20),
                        "Lilita One not registered — check bundle resource + PostScript name")
    }

    func testShapeTokens() {
        XCTAssertEqual(AppTheme.Retro.strokeWidth, 2.5)
        XCTAssertEqual(AppTheme.Retro.strokeHeavy, 3)
        XCTAssertEqual(AppTheme.Retro.Radius.card, 18)
        XCTAssertEqual(AppTheme.Retro.shadowOffset, 5)
        XCTAssertEqual(AppTheme.Retro.shadowPressedOffset, 2)
        XCTAssertEqual(AppTheme.Retro.pressTravel, 3)
    }

    func testMotifFieldIsDeterministicPerSeed() {
        let size = CGSize(width: 390, height: 844)
        let a = MotifFieldLayout.generate(seed: 42, size: size)
        let b = MotifFieldLayout.generate(seed: 42, size: size)
        let c = MotifFieldLayout.generate(seed: 43, size: size)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertFalse(a.isEmpty)
    }

    func testMotifFieldStaysInBoundsAndInSpec() {
        let size = CGSize(width: 390, height: 844)
        let motifs = MotifFieldLayout.generate(seed: 7, size: size)
        for m in motifs {
            XCTAssertTrue(m.position.x >= 0 && m.position.x <= size.width)
            XCTAssertTrue(m.position.y >= 0 && m.position.y <= size.height)
            XCTAssertTrue((4...18).contains(m.size), "motif sizes are 4–18pt per §7")
        }
        // ~1 per 90×90 cell: 5 cols × 10 rows = 50 cells at density 1
        XCTAssertEqual(motifs.count, 50)
    }

    func testMotifFieldRespectsExclusionsWithClearance() {
        let size = CGSize(width: 390, height: 844)
        let exclusion = CGRect(x: 50, y: 100, width: 290, height: 200)
        let motifs = MotifFieldLayout.generate(seed: 7, size: size, avoiding: [exclusion])
        let padded = exclusion.insetBy(dx: -12, dy: -12)
        XCTAssertFalse(motifs.isEmpty)
        for m in motifs {
            XCTAssertFalse(padded.contains(m.position),
                           "motif at \(m.position) is inside an exclusion zone (+12pt clearance)")
        }
    }

    func testMotifFieldDensityScalesCount() {
        let size = CGSize(width: 390, height: 844)
        let full = MotifFieldLayout.generate(seed: 7, size: size, density: 1.0)
        let sparse = MotifFieldLayout.generate(seed: 7, size: size, density: 0.6)
        XCTAssertLessThan(sparse.count, full.count)
        XCTAssertGreaterThan(sparse.count, 0)
    }

    // MARK: - Phase 2: hub accent map (ART_DIRECTION §3.2)

    func testHubAccentMapMatchesArtDirection() {
        let expected: [String: String] = [
            "conversation-starters": "F387B8",
            "country-letter-game": "57A34F",
            "name-5-game": "A08BE0",
            "border-blitz": "5BC0DF",
            "movie-chain": "E8442E",
            "casting-director": "F07C24",
            "vibecheck": "C64B7E",
            "border-hop": "6C9BD2",
            "finish-the-line": "8E4585"
        ]
        for (id, hex) in expected {
            guard let accent = AppTheme.Retro.accent(forGameID: id) else {
                XCTFail("No candy accent for \(id)")
                continue
            }
            assertSameColor(accent, hex: hex)
        }
        XCTAssertNil(AppTheme.Retro.accent(forGameID: "unknown-game"))
    }

    func testEveryRegisteredGameHasACandyAccent() {
        for game in GameRegistry.allGames() {
            XCTAssertNotNil(AppTheme.Retro.accent(forGameID: game.id),
                            "\(game.id) has no candy accent — mustard is the ground, never a fallback")
        }
    }
}
