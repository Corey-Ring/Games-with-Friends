import SwiftUI

// Candy remaps for Name 5 (ART_DIRECTION §3.2 + §8).
// Single source for the semantic colors the four screens used to pull from
// the retired palette (AppTheme.success / .warning / .error / .medalGold /
// .mediumGray and the bare SwiftUI .green/.orange/.red literals), so the
// setup, play, results and game-over screens can't drift apart.
enum Name5Style {
    /// ART_DIRECTION §3.2: name-5-game → lilac. Screen-identity accent
    /// everywhere; §8 keeps its text ink, never cream body copy.
    static let accent = AppTheme.Retro.lilac

    // MARK: - Round outcome (was AppTheme.success / .warning / .error)

    /// Named all five. `34C759` → grass.
    static let successColor = AppTheme.Retro.grass
    /// Ran out of time. The retired `AppTheme.warning` `FF9500` read as a
    /// near-miss rather than an error → tangerine.
    static let missColor = AppTheme.Retro.tangerine
    /// Hard fail / give up / urgent timer. `FF3B30` → tomato.
    static let dangerColor = AppTheme.Retro.tomato
    /// Neutral chatter (turn order, unplaced players). The retired
    /// mediumGray was a neutral, not a warning → cornflower.
    static let infoColor = AppTheme.Retro.cornflower
    /// Round winner. `AppTheme.medalGold` `FFD700` → mustard, the one warm
    /// metal in the candy palette (§3.1 — mustard is never a *game* accent,
    /// but it is fair game as a badge fill inside a cream card).
    static let winnerColor = AppTheme.Retro.mustard

    // MARK: - Difficulty ramp (was .green / .orange / .red literals)

    /// Easy → grass, Medium → tangerine, Hard → tomato. Always rendered as a
    /// garnish inside a cream lozenge, never as a page fill (§8).
    static func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty {
        case .easy: return AppTheme.Retro.grass
        case .medium: return AppTheme.Retro.tangerine
        case .hard: return AppTheme.Retro.tomato
        }
    }

    static func difficultyStars(_ difficulty: Difficulty) -> Int {
        switch difficulty {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    // MARK: - Timer ramp

    /// Candy equivalent of `Name5ViewModel.timerColor`'s three-stop ramp.
    /// The *trigger* stays in the view model, untouched — this only remaps
    /// the color it hands the view.
    static func timerRingColor(_ legacy: Color) -> Color {
        if legacy == AppTheme.error { return dangerColor }
        if legacy == AppTheme.warning { return missColor }
        return successColor
    }

    /// §3 recipe: countdown numerals are ink-on-cream and turn tomato in the
    /// urgent state. Same trigger as `timerRingColor`, no new condition.
    static func timerTextColor(_ legacy: Color) -> Color {
        legacy == AppTheme.error ? dangerColor : AppTheme.Retro.panelText
    }

    /// §8: ink passes on every color above; plum is the one accent that needs
    /// cream instead. Kept so chip call sites stay honest if the map grows.
    static func chipTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.plum ? AppTheme.Retro.cream : AppTheme.Retro.ink
    }
}

/// Ink-outlined status disc (§2 rules 1 and 5): the semantic color rides on
/// the badge so the label beside it can stay ink-on-cream body copy. Replaces
/// the tinted `checkmark.circle.fill` / `xmark.circle.fill` / `crown.fill`
/// glyphs the old screens floated on the card surface.
struct Name5StatusBadge: View {
    let systemImage: String
    let color: Color
    var diameter: CGFloat = 24

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: 2)
            Image(systemName: systemImage)
                .font(.system(size: diameter * 0.45, weight: .black))
                .foregroundColor(Name5Style.chipTextColor(on: color))
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Difficulty garnish: the ramp color rides on ink-outlined stars inside a
/// cream lozenge, so the label stays ink-on-cream whatever the fill behind it
/// (§8 — body copy never sits on a saturated accent).
struct Name5DifficultyChip: View {
    let difficulty: Difficulty

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<Name5Style.difficultyStars(difficulty), id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(AppTheme.Typography.tabLabel)
                    .foregroundColor(Name5Style.difficultyColor(difficulty))
            }
            Text(difficulty.rawValue)
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(AppTheme.Retro.panelText)
        }
        .padding(.vertical, 2)
        .retroLozenge()
    }
}
