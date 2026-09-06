import SwiftUI

/// Placement math for the off-screen-neighbour pills on the Border Hop map.
///
/// Pulled out of the view so it can be exercised directly: the map is drawn full-bleed,
/// so this arithmetic is the only thing keeping the pills clear of the HUD row and the
/// mini-map, and it is easy to get wrong by a safe-area inset.
enum BorderHopEdgePillLayout {

    /// Nominal pill footprint used for collision math. The real pill is sized by its
    /// content and long names ("Democratic Republic of the Congo") run wider than this,
    /// so stacking is approximate for those; the vertical size is what keeps rows apart.
    static let pillSize = CGSize(width: 110, height: 32)

    private static let horizontalInset: CGFloat = 16
    /// Half the pill width, so a clamped pill never hangs off the side of the view.
    private static let edgeMargin: CGFloat = 55
    private static let verticalMargin: CGFloat = 16
    /// How far a colliding pill drops before trying again.
    private static let stackStep: CGFloat = 36
    /// Breathing room left around excluded chrome so pills don't sit flush against it.
    private static let exclusionPadding: CGFloat = 8
    private static let maxStackAttempts = 8

    struct Candidate {
        let id: String
        /// Where the country actually is, in map coordinates — usually off-screen.
        let realPosition: CGPoint

        init(id: String, realPosition: CGPoint) {
            self.id = id
            self.realPosition = realPosition
        }
    }

    struct Placement {
        let id: String
        let position: CGPoint
        let angle: Angle

        /// The pill's footprint, centred on `position`.
        var rect: CGRect {
            CGRect(
                x: position.x - BorderHopEdgePillLayout.pillSize.width / 2,
                y: position.y - BorderHopEdgePillLayout.pillSize.height / 2,
                width: BorderHopEdgePillLayout.pillSize.width,
                height: BorderHopEdgePillLayout.pillSize.height
            )
        }
    }

    /// Clamps every off-screen candidate to the edge of the usable area, pointing back at
    /// where the country really is, and stacks pills that would collide.
    ///
    /// - Parameters:
    ///   - topClearance: bottom edge of the HUD row, in map coordinates.
    ///   - bottomClearance: height reserved for the destination bar.
    ///   - exclusions: rects already occupied by other chrome (the mini-map).
    static func place(
        candidates: [Candidate],
        viewSize: CGSize,
        topClearance: CGFloat,
        bottomClearance: CGFloat,
        exclusions: [CGRect]
    ) -> [Placement] {
        guard viewSize.width > 0, viewSize.height > 0 else { return [] }

        let bounds = CGRect(origin: .zero, size: viewSize)
        let safeArea = CGRect(
            x: horizontalInset, y: topClearance,
            width: bounds.width - horizontalInset * 2,
            height: max(0, bounds.height - topClearance - bottomClearance)
        )

        var placements: [Placement] = []
        // Chrome the pills must dodge is seeded into the collision list, so the existing
        // stacking nudge pushes pills below the mini-map instead of behind it.
        var placedRects: [CGRect] = exclusions.map { $0.insetBy(dx: -exclusionPadding, dy: -exclusionPadding) }

        for candidate in candidates {
            let real = candidate.realPosition
            guard !bounds.insetBy(dx: horizontalInset, dy: horizontalInset).contains(real) else { continue }

            var clamped = CGPoint(
                x: min(max(real.x, safeArea.minX + edgeMargin), safeArea.maxX - edgeMargin),
                y: min(max(real.y, safeArea.minY + verticalMargin), safeArea.maxY - verticalMargin)
            )
            let angle = Angle(radians: atan2(real.y - clamped.y, real.x - clamped.x))

            var pillRect = CGRect(
                x: clamped.x - pillSize.width / 2,
                y: clamped.y - pillSize.height / 2,
                width: pillSize.width,
                height: pillSize.height
            )
            var attempts = 0
            while placedRects.contains(where: { $0.intersects(pillRect) }), attempts < maxStackAttempts {
                clamped.y += stackStep
                pillRect = pillRect.offsetBy(dx: 0, dy: stackStep)
                attempts += 1
            }
            placedRects.append(pillRect)

            placements.append(Placement(id: candidate.id, position: clamped, angle: angle))
        }

        return placements
    }
}
