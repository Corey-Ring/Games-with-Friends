import CoreGraphics

/// Deterministic seedable RNG (SplitMix64). Seeded per screen so the motif
/// ground is stable across renders — ART_DIRECTION.md §7 "seeded-random with
/// a fixed seed, never visibly gridded".
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct Motif: Equatable {
    enum Kind: CaseIterable, Equatable {
        case daisy, sparkle, dot, heart, squiggle
    }
    let kind: Kind
    let position: CGPoint
    /// Diameter in points, 4–18 (§7).
    let size: CGFloat
    /// Index into the rendering palette (renderer wraps with %).
    let colorIndex: Int
    let rotationDegrees: Double
}

/// Pure layout generator for the motif ground (§7): one candidate motif per
/// 90×90pt cell, jittered inside its cell, skipping exclusion rects padded by
/// 12pt clearance. Rendering lives in MotifGroundView.
enum MotifFieldLayout {
    static let cellSide: CGFloat = 90
    static let clearance: CGFloat = 12
    static let sizeRange: ClosedRange<CGFloat> = 4...18
    static let paletteSlots = 4
    /// Renderers draw up to this fraction of `size` from the motif center
    /// (sparkle spikes 0.7, squiggle arms 0.8), so centers stay this far
    /// inside the field to keep whole motifs on screen.
    static let maxExtentRatio: CGFloat = 0.8

    static func generate(seed: UInt64,
                         size: CGSize,
                         density: CGFloat = 1.0,
                         avoiding exclusions: [CGRect] = []) -> [Motif] {
        guard size.width > 0, size.height > 0, density > 0 else { return [] }
        var rng = SplitMix64(seed: seed)
        let cols = max(1, Int((size.width / cellSide).rounded(.up)))
        let rows = max(1, Int((size.height / cellSide).rounded(.up)))
        let padded = exclusions.map { $0.insetBy(dx: -clearance, dy: -clearance) }
        var motifs: [Motif] = []

        for row in 0..<rows {
            for col in 0..<cols {
                // Draw every random even for skipped cells so density changes
                // don't reshuffle the surviving motifs' appearance.
                let roll = CGFloat.random(in: 0..<1, using: &rng)
                let rawX = CGFloat(col) * cellSide + CGFloat.random(in: 0...cellSide, using: &rng)
                let rawY = CGFloat(row) * cellSide + CGFloat.random(in: 0...cellSide, using: &rng)
                let kind = Motif.Kind.allCases.randomElement(using: &rng) ?? .dot
                let motifSize = CGFloat.random(in: sizeRange, using: &rng)
                let colorIndex = Int.random(in: 0..<paletteSlots, using: &rng)
                let rotation = Double.random(in: -20...20, using: &rng)

                if roll >= density { continue }
                // Inset by the motif's drawn extent so the whole shape stays
                // on screen — edge sparkles were getting sliced by the bezel.
                let margin = motifSize * maxExtentRatio
                let point = CGPoint(
                    x: min(max(rawX, margin), max(margin, size.width - margin)),
                    y: min(max(rawY, margin), max(margin, size.height - margin))
                )
                if padded.contains(where: { $0.contains(point) }) { continue }
                motifs.append(Motif(kind: kind, position: point, size: motifSize,
                                    colorIndex: colorIndex, rotationDegrees: rotation))
            }
        }
        return motifs
    }
}
