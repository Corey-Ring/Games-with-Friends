import SwiftUI

// Candy remaps for Movie Chain (ART_DIRECTION §3.2 + §8). Single source for
// the semantic colors these screens used to pull from the retired palette
// (AppTheme.success/.warning/.error, medal metals, actorNodeSurface), so the
// four screens can't drift apart.
enum MovieChainStyle {
    /// ART_DIRECTION §3.2: movie-chain → tomato.
    static let accent = AppTheme.Retro.tomato

    // MARK: - Chain node identities
    // The chain alternates movie/actor; the two node colors carry that rhythm.

    /// Movie nodes ride the game accent.
    static let movieNode = AppTheme.Retro.tomato
    /// Actor nodes (was actorNodeSurface / deepCharcoal) → cornflower, so the
    /// alternation stays legible on cream in both color schemes.
    static let actorNode = AppTheme.Retro.cornflower

    // MARK: - Timer ramp (trigger thresholds live in the view, unchanged)

    /// > 10s (was AppTheme.success). Ink, not grass: grass text on cream is
    /// ~2.7:1 — the calm state reads as plain chrome, color arrives with
    /// urgency (same treatment as the Conversation Starters timer).
    static let timerCalm = AppTheme.Retro.panelText
    /// 6–10s (was AppTheme.warning).
    static let timerWarning = AppTheme.Retro.tangerine
    /// ≤ 5s (was AppTheme.error).
    static let timerUrgent = AppTheme.Retro.tomato

    /// Lives hearts (was AppTheme.error).
    static let lives = AppTheme.Retro.tomato

    // MARK: - Standings medals (was medalGold/Silver/Bronze/mediumGray)

    static let medalFirst = AppTheme.Retro.mustard
    static let medalSecond = AppTheme.Retro.cornflower
    static let medalThird = AppTheme.Retro.cocoa
    static let medalRunnerUp = AppTheme.Retro.cocoa.opacity(0.6)

    /// §8: ink passes on every accent except plum (and on cocoa nothing light
    /// enough matters here — cocoa medals take cream glyphs like plum).
    static func chipTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.plum || color == AppTheme.Retro.cocoa
            ? AppTheme.Retro.cream : AppTheme.Retro.ink
    }
}

/// Round chain-node disc (§2 rules 1 and 5): flat candy fill, ink outline,
/// ink glyph. Replaces the old borderless accent/charcoal circles.
struct ChainNodeDisc: View {
    let systemImage: String
    let color: Color
    var diameter: CGFloat = 44
    var dashed: Bool = false

    var body: some View {
        ZStack {
            if dashed {
                Circle().fill(AppTheme.Retro.panel)
                Circle().strokeBorder(
                    AppTheme.Retro.ink,
                    style: StrokeStyle(lineWidth: AppTheme.Retro.strokeWidth, dash: [5]))
            } else {
                Circle().fill(color)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
            }
            Image(systemName: systemImage)
                .font(.system(size: diameter * 0.38, weight: .bold))
                .foregroundColor(dashed ? AppTheme.Retro.panelText
                                        : MovieChainStyle.chipTextColor(on: color))
        }
        .frame(width: diameter, height: diameter)
    }
}
