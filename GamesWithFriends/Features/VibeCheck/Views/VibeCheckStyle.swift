import SwiftUI

// Candy remaps for Vibe Check (ART_DIRECTION §3.2 + §8).
//
// Vibe Check ships two flows off one model layer — the classic team mode
// (Features/VibeCheck/Views) and Competition (Features/VibeCheck/Competition).
// Both read this one enum so they cannot drift apart: it is the single source
// for every semantic color the screens used to pull from the retired palette
// (AppTheme.success / .warning / .error / .tealGreen / .medalGold / .medalSilver
// / .medalBronze / .mediumGray, the per-player identity ramp, and the bare
// SwiftUI .purple / .orange / .yellow / .green literals).
//
// `ScoringZone.color` lives in the model layer (VibeCheckModels.swift) and is
// out of scope for a view-layer migration, so the views call
// `VibeCheckStyle.zoneColor(_:)` instead of `zone.color` — same five-stop
// ramp, candy values, no model change.
enum VibeCheckStyle {
    /// ART_DIRECTION §3.2: vibecheck → berry. §8 keeps berry's text ink for
    /// display type; body copy always moves onto a cream panel or lozenge.
    static let accent = AppTheme.Retro.berry

    // MARK: - Scoring ramp (was ScoringZone.color's five stops)

    /// Five-stop good→bad ramp, one candy hue per retired stop:
    /// `AppTheme.success` `34C759` → grass, `AppTheme.tealGreen` `4FBFA5` →
    /// poolBlue, `AppTheme.medalGold` `FFD700` → mustard, `AppTheme.warning`
    /// `FF9500` → tangerine, `AppTheme.error` `FF3B30` → tomato. Every stop
    /// takes ink glyphs (§8), so the ramp can ride chips inside cream cards.
    static func zoneColor(_ zone: ScoringZone) -> Color {
        switch zone {
        case .perfect: return AppTheme.Retro.grass
        case .great: return AppTheme.Retro.poolBlue
        case .good: return AppTheme.Retro.mustard
        case .okay: return AppTheme.Retro.tangerine
        case .miss: return AppTheme.Retro.tomato
        }
    }

    // MARK: - Spectrum markers

    /// The hidden target the Vibe Setter picked (was `AppTheme.success`).
    static let targetMarker = AppTheme.Retro.grass
    /// A guess laid against the target (was `AppTheme.warning`). Deliberately
    /// far from `targetMarker` in hue so the reveal reads at a glance.
    static let guessMarker = AppTheme.Retro.tangerine

    // MARK: - Spectrum poles
    // The two pole labels are semantic (top end vs bottom end of the
    // spectrum), so they carry the only two candy fills on the slider that
    // ink text passes on outright (§8: mustard, bubblegum, poolBlue, cream,
    // tangerine). The label text itself stays ink — never cream — at every
    // size, so the poles read whatever the Dynamic Type setting.

    /// Top pole ("0%" end of `position`).
    static let poleTop = AppTheme.Retro.poolBlue
    /// Bottom pole ("100%" end of `position`).
    static let poleBottom = AppTheme.Retro.tangerine

    // MARK: - Round roles (was the bare `.purple` / `.orange` literals on the
    // pass-device screens, shared by classic TeamRole and Competition
    // PlayerRole)

    /// Vibe Setter / Prompt Setter. `.purple` → plum, the one accent dark
    /// enough for cream body text (§8), which is what the privacy screen's
    /// bold full-bleed panel needs.
    static let setterRole = AppTheme.Retro.plum
    /// Guesser / Guessing Team. `.orange` → tangerine; ink text passes on it,
    /// so the same panel flips its text color via `roleTextColor(on:)`.
    static let guesserRole = AppTheme.Retro.tangerine

    // MARK: - Standings medals (was medalGold / medalSilver / medalBronze /
    // elevatedSurface, matching the Movie Chain treatment so the two games'
    // standings read as one system)

    static let medalFirst = AppTheme.Retro.mustard
    static let medalSecond = AppTheme.Retro.cornflower
    static let medalThird = AppTheme.Retro.cocoa
    /// Everyone below the podium: a plain cream disc, ink numeral.
    static let medalRunnerUp = AppTheme.Retro.panel

    // MARK: - Status colors

    /// Round leader / winner highlight — the game's own accent.
    static let leaderColor = AppTheme.Retro.berry
    /// Closest guess of the round (was `AppTheme.success`).
    static let closestColor = AppTheme.Retro.grass
    /// Worst-guesser tease (was `AppTheme.warning`). A gentle ribbing, not an
    /// error, so it lands on tangerine rather than tomato.
    static let teaseColor = AppTheme.Retro.tangerine
    /// Neutral chatter (hints, "minimum 2 players", shuffle notices). The
    /// retired mediumGray was a neutral, not a warning → cornflower.
    static let infoColor = AppTheme.Retro.cornflower

    // MARK: - Per-player identity ramp (was AppTheme.skyBlue /
    // .electricIndigo / .softMauve / .tealGreen / .coralRed / .forestGreen /
    // .warmGold / .compassRose / .mediumGray on the multi-guess reveal)

    /// Nine distinct candy hues, one per seat, deliberately excluding grass —
    /// grass is the target marker on the same slider and must not be mistaken
    /// for somebody's guess.
    static let playerColors: [Color] = [
        AppTheme.Retro.cornflower,
        AppTheme.Retro.plum,
        AppTheme.Retro.bubblegum,
        AppTheme.Retro.poolBlue,
        AppTheme.Retro.tomato,
        AppTheme.Retro.tangerine,
        AppTheme.Retro.lilac,
        AppTheme.Retro.mustard,
        AppTheme.Retro.cocoa,
    ]

    static func playerColor(at index: Int) -> Color {
        playerColors[index % playerColors.count]
    }

    /// Confetti mix for the two game-over screens (was `.purple` / `.blue` /
    /// `.yellow` / `.green` / `.orange` / `.pink`).
    static let confettiColors: [Color] = [
        AppTheme.Retro.berry,
        AppTheme.Retro.mustard,
        AppTheme.Retro.grass,
        AppTheme.Retro.poolBlue,
        AppTheme.Retro.tangerine,
        AppTheme.Retro.bubblegum,
    ]

    // MARK: - Contrast helpers (§8)

    /// Ink passes on every candy fill above except plum and cocoa, which are
    /// dark enough to need cream instead.
    static func chipTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.plum || color == AppTheme.Retro.cocoa
            ? AppTheme.Retro.cream : AppTheme.Retro.ink
    }

    /// Same rule, spelled for the pass-device role panels so the two role
    /// fills (plum / tangerine) can share one layout.
    static func roleTextColor(on color: Color) -> Color {
        chipTextColor(on: color)
    }
}

// MARK: - Shared chrome

/// Screen header (§3 recipe): spot plate + game/screen title in Lilita One on
/// a hard-shadowed berry panel with a ±1° tilt, plus an optional tagline in a
/// cream lozenge. Shared by both modes so the two flows keep one masthead.
struct VibeCheckHeader: View {
    let title: String
    var subtitle: String? = nil
    var accent: Color = VibeCheckStyle.accent
    var plateDiameter: CGFloat = 84
    var titleSize: CGFloat = 22

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                RetroSpotIllustration(kind: .heart)
                    .frame(width: plateDiameter * 0.76, height: plateDiameter * 0.76)
            }
            .frame(width: plateDiameter, height: plateDiameter)

            Text(title)
                .font(AppTheme.Retro.Typography.heading(titleSize, relativeTo: .title2))
                .foregroundColor(VibeCheckStyle.chipTextColor(on: accent))
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(accent)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset,
                                y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1))

            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.secondary)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
                    .retroLozenge()
                    .rotationEffect(.degrees(0.8))
            }
        }
    }
}

/// Ink-outlined status disc (§2 rules 1 and 5): the semantic color rides on
/// the badge so the label beside it can stay ink-on-cream body copy. Replaces
/// the tinted `checkmark.circle.fill` / `lightbulb.fill` glyphs the old
/// screens floated on the card surface.
struct VibeCheckStatusBadge: View {
    let systemImage: String
    let color: Color
    var diameter: CGFloat = 24

    var body: some View {
        ZStack {
            Circle().fill(color)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: 2)
            Image(systemName: systemImage)
                .font(.system(size: diameter * 0.45, weight: .black))
                .foregroundColor(VibeCheckStyle.chipTextColor(on: color))
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Standings medal disc — candy metals with ink outlines (§2 rule 1). Shared
/// by the classic and Competition scoreboards and both game-over screens.
struct VibeCheckRankBadge: View {
    let rank: Int
    var diameter: CGFloat = 32

    var body: some View {
        ZStack {
            Circle().fill(fill)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)

            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.system(size: diameter * 0.4, weight: .bold))
                    .foregroundColor(glyph)
            } else {
                Text("\(rank)")
                    .font(AppTheme.Retro.Typography.heading(diameter * 0.44,
                                                            relativeTo: .subheadline))
                    .foregroundColor(glyph)
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private var fill: Color {
        switch rank {
        case 1: return VibeCheckStyle.medalFirst
        case 2: return VibeCheckStyle.medalSecond
        case 3: return VibeCheckStyle.medalThird
        default: return VibeCheckStyle.medalRunnerUp
        }
    }

    private var glyph: Color {
        switch rank {
        case 1, 2: return AppTheme.Retro.ink
        case 3: return AppTheme.Retro.cream
        default: return AppTheme.Retro.panelText
        }
    }
}

/// Points chip: the scoring-zone color fills an ink-outlined capsule and the
/// numeral rides on it in Lilita (§8 — never body copy on a saturated fill).
struct VibeCheckPointsChip: View {
    let zone: ScoringZone
    let points: Int

    var body: some View {
        let fill = VibeCheckStyle.zoneColor(zone)
        return Text("+\(points)")
            .font(AppTheme.Retro.Typography.heading(17))
            .foregroundColor(VibeCheckStyle.chipTextColor(on: fill))
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 2)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
    }
}

/// Score progress meter (§4 gotcha 6): unfilled track is `ink.opacity(0.15)`
/// behind a 1pt ink rule, filled portion is a flat candy block.
struct VibeCheckProgressBar: View {
    let progress: Double
    var fill: Color = VibeCheckStyle.accent
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.Retro.ink.opacity(0.15))
                    .frame(height: height)

                Capsule()
                    .fill(fill)
                    .frame(width: max(0, geometry.size.width * progress), height: height)

                Capsule()
                    .stroke(AppTheme.Retro.ink, lineWidth: 1.5)
                    .frame(height: height)
            }
            .frame(height: height)
        }
        .frame(height: height)
    }
}
