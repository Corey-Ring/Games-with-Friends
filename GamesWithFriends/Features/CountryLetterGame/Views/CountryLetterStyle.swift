import SwiftUI

// Candy remaps for Country Letter Challenge (ART_DIRECTION §3.2 + §8).
// Single source for the semantic colors the screens used to pull from the
// retired palette (AppTheme.success / .error / .warning / .mediumGray), so
// GamePlayView and ResultsView can't drift apart again.
enum CountryLetterStyle {
    /// ART_DIRECTION §3.2: country-letter-game → grass.
    static let accent = AppTheme.Retro.grass

    // MARK: - Guess feedback (was AppTheme.success / .error / .mediumGray)

    /// Accepted guess. `34C759` → grass.
    static let successColor = AppTheme.Retro.grass
    /// Rejected / duplicate guess. `FF3B30` → tomato.
    static let errorColor = AppTheme.Retro.tomato
    /// Neutral chatter (hints, "ready", give-up notices). The retired
    /// mediumGray was a neutral, not a warning → cornflower.
    static let infoColor = AppTheme.Retro.cornflower

    // MARK: - Results row statuses

    /// Found it. Same success ramp as the in-game feedback badge.
    static let correctColor = AppTheme.Retro.grass
    /// Never named. Neutral, not a failure state (was mediumGray) → cornflower.
    static let missedColor = AppTheme.Retro.cornflower
    /// Revealed via hints. `AppTheme.warning` `FF9500` → tangerine.
    static let giveUpColor = AppTheme.Retro.tangerine

    /// §8: ink passes on every color above; plum is the one accent that needs
    /// cream instead. Kept so chip call sites stay honest if the map grows.
    static func chipTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.plum ? AppTheme.Retro.cream : AppTheme.Retro.ink
    }
}

/// Ink-outlined status disc (§2 rules 1 and 5): the semantic color rides on
/// the badge so the label beside it can stay ink-on-cream body copy. Replaces
/// the tinted `checkmark.circle.fill` / `xmark.circle` / `hand.raised` glyphs.
struct CountryStatusBadge: View {
    let systemImage: String
    let color: Color
    var diameter: CGFloat = 24

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: 2)
            Image(systemName: systemImage)
                .font(.system(size: diameter * 0.45, weight: .black))
                .foregroundColor(CountryLetterStyle.chipTextColor(on: color))
        }
        .frame(width: diameter, height: diameter)
    }
}
