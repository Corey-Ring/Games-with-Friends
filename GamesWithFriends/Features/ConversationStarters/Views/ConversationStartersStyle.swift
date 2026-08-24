import SwiftUI

// Candy remaps for Conversation Starters (ART_DIRECTION §3.2 + §8).
// Single source for the vibe/category colors that were previously
// duplicated across HomeView, GameView/CardView and SavedStarterRow.
enum ConversationStartersStyle {
    static let accent = AppTheme.Retro.bubblegum

    /// Vibe ramp: cool → hot. Semantic garnish colors; always rendered on
    /// cream panels, never used as page accents.
    static func vibeColor(_ level: Int) -> Color {
        switch level {
        case 1: return AppTheme.Retro.poolBlue    // Ice
        case 2: return AppTheme.Retro.grass       // Casual
        case 3: return AppTheme.Retro.tangerine   // Fun
        case 4: return AppTheme.Retro.plum        // Deep
        case 5: return AppTheme.Retro.tomato      // Daring
        default: return AppTheme.Retro.poolBlue
        }
    }

    static func categoryColor(_ category: Category) -> Color {
        switch category {
        case .wouldYouRather: return AppTheme.Retro.bubblegum
        case .hotTakes: return AppTheme.Retro.tomato
        case .hypotheticals: return AppTheme.Retro.tangerine
        case .storyTime: return AppTheme.Retro.cornflower
        case .thisOrThat: return AppTheme.Retro.grass
        case .deepDive: return AppTheme.Retro.plum
        }
    }

    /// §8: ink passes on every chip color above except plum, where cream
    /// is the only safe body text.
    static func chipTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.plum ? AppTheme.Retro.cream : AppTheme.Retro.ink
    }
}
