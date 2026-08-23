import SwiftUI

// Candy remaps for Casting Director (ART_DIRECTION §3.2 + §8). Single source
// for the clue-tier ramp and status colors the screens used to pull from the
// retired palette (skyBlue/forestGreen/warmGold/coralRed, success/error/
// warning, medalGold), so ClueChipView and RoundResultsView can't drift.
enum CastingDirectorStyle {
    /// ART_DIRECTION §3.2: casting-director → tangerine.
    static let accent = AppTheme.Retro.tangerine

    /// Clue tiers get warmer as they get more revealing — cool cornflower for
    /// vague hints up to hot tomato for the giveaway.
    static func tierColor(_ tier: ClueTier) -> Color {
        switch tier {
        case .vague: return AppTheme.Retro.cornflower
        case .narrowing: return AppTheme.Retro.grass
        case .strongSignal: return AppTheme.Retro.mustard
        case .giveaway: return AppTheme.Retro.tomato
        }
    }

    // MARK: - Status (was AppTheme.success / .error / .warning / medalGold)

    static let successColor = AppTheme.Retro.grass
    static let errorColor = AppTheme.Retro.tomato
    static let warningColor = AppTheme.Retro.tangerine
    static let medalColor = AppTheme.Retro.mustard

    /// §8: ink passes on every color above; plum would need cream (unused
    /// here, kept so chip call sites stay honest if the map grows).
    static func chipTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.plum ? AppTheme.Retro.cream : AppTheme.Retro.ink
    }
}
