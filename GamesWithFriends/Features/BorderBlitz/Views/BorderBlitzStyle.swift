import SwiftUI

// Candy remaps for Border Blitz (ART_DIRECTION §3.2 + §8). Single source for
// the semantic colors the screens used to pull from the retired palette
// (AppTheme.success / .warning / .error, and the mediumGray / deepCharcoal
// tile chrome), so the menu, play, round-complete and game-over states can't
// drift apart.
enum BorderBlitzStyle {
    /// ART_DIRECTION §3.2: border-blitz → poolBlue. §8 keeps its text ink —
    /// cream body copy passes only on plum.
    static let accent = AppTheme.Retro.poolBlue

    // MARK: - Round outcome (was AppTheme.success / .warning / .error)

    /// Correct guess. `34C759` → grass.
    static let successColor = AppTheme.Retro.grass
    /// Streak heat and the "PERFECT!" call-out. The retired
    /// `AppTheme.warning` `FF9500` read as celebratory heat, not an error
    /// → tangerine.
    static let warningColor = AppTheme.Retro.tangerine
    /// Missed round, denied microphone, urgent timer. `FF3B30` → tomato.
    static let dangerColor = AppTheme.Retro.tomato
    /// Neutral chatter (nothing at stake). The retired mediumGray was a
    /// neutral, not a warning → cornflower.
    static let infoColor = AppTheme.Retro.cornflower

    // MARK: - Timer ramp (the >20s / >10s / ≤10s triggers stay in the view)

    /// > 20s (was AppTheme.success). Ink, not grass: grass text on cream is
    /// ~2.7:1 — the calm state reads as plain chrome and color arrives with
    /// urgency (same treatment as Movie Chain and Conversation Starters).
    static let timerCalm = AppTheme.Retro.panelText
    /// 11–20s (was AppTheme.warning).
    static let timerWarning = AppTheme.Retro.tangerine
    /// ≤ 10s (was AppTheme.error).
    static let timerUrgent = AppTheme.Retro.tomato

    // MARK: - Country silhouette (was accent at 0.85 / 0.6 alpha)

    /// Flat candy fill for the landmass (§2 rule 2 — no alpha washes). The
    /// shape's path data, scaling and clustering math are untouched.
    static let mapFill = AppTheme.Retro.poolBlue
    /// Uniform ink coastline (§2 rule 1).
    static let mapOutline = AppTheme.Retro.ink

    // MARK: - Letter tiles

    /// Revealed letter tile rides the game accent; ink letterform on top (§8).
    static let tileRevealedFill = AppTheme.Retro.poolBlue
    /// Unrevealed tile is a plain cream plate — the ink rule does the work.
    static let tileHiddenFill = AppTheme.Retro.panel
    /// Placeholder underscore: low-alpha ink, never gray (§4 gotcha 6).
    static let tilePlaceholder = AppTheme.Retro.panelText.opacity(0.45)

    /// §8: ink passes on every color above; plum is the one accent that needs
    /// cream instead. Kept so chip call sites stay honest if the map grows.
    static func chipTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.plum ? AppTheme.Retro.cream : AppTheme.Retro.ink
    }
}
