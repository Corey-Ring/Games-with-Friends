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
}
