import XCTest
import SwiftUI
@testable import GamesWithFriends

/// Border Hop draws its map full-bleed (`.ignoresSafeArea()`), so the map's coordinate
/// space starts at the physical top of the device while the HUD row sits below the status
/// bar / Dynamic Island. These tests pin the placement math that keeps the off-screen
/// neighbour pills clear of the HUD row and the mini-map — the bug was pills stacking
/// underneath the close button and behind the mini-map.
final class BorderHopEdgePillLayoutTests: XCTestCase {

    private let viewSize = CGSize(width: 402, height: 874)
    /// Dynamic Island inset + HUD top padding + 44pt close plate + its raised shadow.
    private let topClearance: CGFloat = 120
    private let bottomClearance: CGFloat = 104

    private func place(
        _ candidates: [BorderHopEdgePillLayout.Candidate],
        exclusions: [CGRect] = []
    ) -> [BorderHopEdgePillLayout.Placement] {
        BorderHopEdgePillLayout.place(
            candidates: candidates,
            viewSize: viewSize,
            topClearance: topClearance,
            bottomClearance: bottomClearance,
            exclusions: exclusions
        )
    }

    /// A neighbour off the left edge and high up must not land under the HUD row.
    func testPillForNeighbourOffScreenTopLeftClearsTheHUDRow() throws {
        let placements = place([.init(id: "SAU", realPosition: CGPoint(x: -100, y: 50))])

        let pill = try XCTUnwrap(placements.first)
        XCTAssertEqual(pill.id, "SAU")
        XCTAssertGreaterThanOrEqual(
            pill.rect.minY, topClearance,
            "Pill overlaps the HUD row (close button); rect was \(pill.rect)"
        )
    }

    /// A second off-screen neighbour stacks below the first instead of covering it.
    func testStackedPillsDoNotOverlapEachOther() throws {
        let placements = place([
            .init(id: "SAU", realPosition: CGPoint(x: -100, y: 50)),
            .init(id: "YEM", realPosition: CGPoint(x: -120, y: 60))
        ])

        XCTAssertEqual(placements.count, 2)
        let first = try XCTUnwrap(placements.first)
        let second = try XCTUnwrap(placements.last)
        XCTAssertFalse(
            first.rect.intersects(second.rect),
            "Stacked pills overlap: \(first.rect) vs \(second.rect)"
        )
        XCTAssertGreaterThanOrEqual(second.rect.minY, topClearance)
    }

    /// The mini-map sits at the top trailing corner; a pill clamped to the right edge
    /// must be pushed clear of it rather than hidden behind it.
    func testPillOffScreenRightIsPushedClearOfTheMiniMap() throws {
        let miniMap = CGRect(x: viewSize.width - 16 - 112, y: 128, width: 112, height: 56)

        let placements = place(
            [.init(id: "PRK", realPosition: CGPoint(x: 600, y: 140))],
            exclusions: [miniMap]
        )

        let pill = try XCTUnwrap(placements.first)
        XCTAssertFalse(
            pill.rect.intersects(miniMap),
            "Pill is hidden behind the mini-map; pill \(pill.rect) vs mini-map \(miniMap)"
        )
    }

    /// Countries already comfortably on screen get no pill at all.
    func testOnScreenCountryProducesNoPill() {
        let placements = place([.init(id: "EGY", realPosition: CGPoint(x: 200, y: 400))])
        XCTAssertTrue(placements.isEmpty)
    }

    /// Pills stay inside the horizontal bounds of the view at both edges.
    func testPillsStayWithinHorizontalBounds() throws {
        let placements = place([
            .init(id: "SAU", realPosition: CGPoint(x: -400, y: 400)),
            .init(id: "PRK", realPosition: CGPoint(x: 900, y: 500))
        ])

        XCTAssertEqual(placements.count, 2)
        for pill in placements {
            XCTAssertGreaterThanOrEqual(pill.rect.minX, 0, "Pill runs off the left edge: \(pill.rect)")
            XCTAssertLessThanOrEqual(pill.rect.maxX, viewSize.width, "Pill runs off the right edge: \(pill.rect)")
        }
    }
}
