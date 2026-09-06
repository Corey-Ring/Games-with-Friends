//
//  FinishTheLineStyle.swift
//  GamesWithFriends
//

import SwiftUI

// Candy remaps for Finish the Line (ART_DIRECTION §3.2 + §8). Single source
// for the semantic colors the five screens and four components used to pull
// from the retired palette (AppTheme.success / .warning / .error /
// .brandOrange / .medalGold / .warmGold / .mediumGray), so menu, countdown,
// game, results and the quote card can't drift apart.
enum FinishTheLineStyle {
    /// ART_DIRECTION §3.2: finish-the-line → plum. Plum is the ONE accent dark
    /// enough for cream body text and the one where ink text fails — every
    /// plum fill in this game takes `chipTextColor(on:)`, never bare ink.
    static let accent = AppTheme.Retro.plum

    // MARK: - Card resolution (was AppTheme.success / .warning)

    /// Correct answer — the blank fills green. `34C759` → grass.
    static let correctColor = AppTheme.Retro.grass
    /// The skip "groan reveal". The retired `AppTheme.warning` `FF9500` read as
    /// a near-miss rather than an error → tangerine.
    static let skippedColor = AppTheme.Retro.tangerine
    /// Hard fail / urgent timer / encore alarm. `FF3B30` → tomato.
    static let dangerColor = AppTheme.Retro.tomato
    /// Neutral chatter (heard-transcript captions, quote counts). The retired
    /// mediumGray was a neutral, not a warning → cornflower.
    static let infoColor = AppTheme.Retro.cornflower
    /// Personal best / score-to-beat metal. `AppTheme.medalGold` `FFD700` and
    /// `warmGold` `D4943A` both → mustard, the one warm metal in the candy
    /// palette (§3.1 — mustard is never a *game* accent, but it is fair game
    /// as a badge fill).
    static let bestColor = AppTheme.Retro.mustard

    // MARK: - Streak ramp (was AppTheme.brandOrange / .warning gradients)

    /// Streak of 2+. Mustard reads as "warming up" and takes ink text (§8).
    static let streakColor = AppTheme.Retro.mustard
    /// Streak of 5+ (On Fire). Tangerine is the hotter step of the same family
    /// and still takes ink text, so the badge label never needs a lozenge.
    static let streakOnFireColor = AppTheme.Retro.tangerine

    // MARK: - Spotlight timer ramp
    //
    // The >30s / 11–30s / ≤10s thresholds and the pulse trigger stay in
    // SpotlightTimerView, untouched — these only remap the colors it draws.

    /// >30s: the round accent rides the arc (a graphic, not text).
    static let timerCalmArc = accent
    /// 11–30s (was AppTheme.warning).
    static let timerCautionArc = AppTheme.Retro.tangerine
    /// ≤10s (was AppTheme.error).
    static let timerUrgentArc = AppTheme.Retro.tomato
    /// §3 recipe: the countdown numerals are ink-on-cream until urgency
    /// arrives, at which point they take `timerUrgentArc`.
    static let timerCalmText = AppTheme.Retro.panelText

    // MARK: - Difficulty ramp

    /// Easy → grass, Medium → tangerine, Hard → tomato. Rendered as garnish
    /// inside a cream card, never as a page fill (§8).
    static func difficultyColor(_ difficulty: QuoteDifficulty) -> Color {
        switch difficulty {
        case .easy: return correctColor
        case .medium: return skippedColor
        case .hard: return dangerColor
        }
    }

    // MARK: - Category hues

    /// Distinct candy hue per quote category, used only for the chip on the
    /// live quote card — semantic variety is allowed on chips inside cream
    /// cards (playbook §3), while the setup pills all wear the game accent.
    static func categoryColor(_ category: QuoteCategory) -> Color {
        switch category {
        case .silverScreen: return AppTheme.Retro.cornflower
        case .smallScreen: return AppTheme.Retro.poolBlue
        case .animated: return AppTheme.Retro.bubblegum
        case .songsAndJingles: return AppTheme.Retro.lilac
        case .pitchPerfect: return AppTheme.Retro.tangerine
        case .storytime: return AppTheme.Retro.mustard
        case .playTime: return AppTheme.Retro.grass
        }
    }

    /// §8, the plum rule: ink passes on every accent this game uses *except*
    /// plum, which is the one accent dark enough to need cream instead. Every
    /// plum fill on these screens routes its label through here.
    static func chipTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.plum ? AppTheme.Retro.cream : AppTheme.Retro.ink
    }
}

/// Ink-outlined status disc (§2 rules 1 and 5): the semantic color rides on
/// the badge so the label beside it can stay ink-on-cream body copy. Replaces
/// the tinted `checkmark.circle.fill` / `flame.fill` / `forward.fill` glyphs
/// the old results screen floated on the card surface.
struct FinishTheLineStatusDisc: View {
    let systemImage: String
    let color: Color
    var diameter: CGFloat = 28

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: 2)
            Image(systemName: systemImage)
                .font(.system(size: diameter * 0.45, weight: .black))
                .foregroundColor(FinishTheLineStyle.chipTextColor(on: color))
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Spot plate: cream circle, ink rule, illustration inside (§3 recipe header).
/// Finish the Line's spot is the "I know this…" bubble (§3.2 / RetroSpotKind).
struct FinishTheLineSpotPlate: View {
    var diameter: CGFloat = 84

    var body: some View {
        ZStack {
            Circle().fill(AppTheme.Retro.panel)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
            RetroSpotIllustration(kind: .quoteBubble)
                .frame(width: diameter * 0.76, height: diameter * 0.76)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Framed Lilita title on the plum accent panel with the hard ink offset and
/// the ±1° tilt (§3 recipe, Rule 4). Cream letterforms — the plum rule.
struct FinishTheLineTitlePanel: View {
    let text: String
    var size: CGFloat = 22
    var tilt: Double = -1

    var body: some View {
        Text(text)
            .font(AppTheme.Retro.Typography.heading(size, relativeTo: .title2))
            .foregroundColor(FinishTheLineStyle.chipTextColor(on: FinishTheLineStyle.accent))
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .retroPanel(FinishTheLineStyle.accent)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                    .fill(AppTheme.Retro.ink)
                    .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
            )
            .rotationEffect(.degrees(tilt))
    }
}
