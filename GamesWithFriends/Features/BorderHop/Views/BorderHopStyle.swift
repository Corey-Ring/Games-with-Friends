//
//  BorderHopStyle.swift
//  GamesWithFriends
//

import SwiftUI

// Candy remaps for Border Hop (ART_DIRECTION §3.2 + §8). Single source for the
// semantic colors the five screens, the stopwatch and the map canvas used to
// pull from the retired palette (AppTheme.success / .warning / .error /
// .medalGold / .mediumGray / .compassRose / .deepCharcoal and the raw
// `Color(hex:)` map greys), so the setup, briefing, live map, quiz sheet and
// results screens can't drift apart.
enum BorderHopStyle {
    /// ART_DIRECTION §3.2: border-hop → cornflower. §8 keeps its text ink —
    /// cream body copy passes only on plum.
    static let accent = AppTheme.Retro.cornflower

    // MARK: - Round outcome (was AppTheme.success / .warning / .error)

    /// Correct answer, "closer to the goal", optimal route. `34C759` → grass.
    static let correctColor = AppTheme.Retro.grass
    /// Wrong answer, eliminated choice, "further from the goal". `FF3B30` →
    /// tomato. Also the urgent stopwatch color if a caller ever needs one.
    static let wrongColor = AppTheme.Retro.tomato
    /// Second-look states: the answer revealed after three strikes, a fact the
    /// player missed, the streak flame. The retired `AppTheme.warning`
    /// `FF9500` read as heat/near-miss, not an error → tangerine.
    static let reviewColor = AppTheme.Retro.tangerine
    /// The goal metal — destination country, checkered flag, "Perfect!" chip.
    /// `AppTheme.medalGold` `FFD700` → mustard, the one warm metal in the
    /// candy palette (§3.1 — mustard is never a *game* accent, but it is fair
    /// game as a badge/goal fill).
    static let goalColor = AppTheme.Retro.mustard
    /// Neutral chatter (hop counts, "it doesn't score" captions). The retired
    /// mediumGray was a neutral, not a warning → ink-on-cream at reduced
    /// weight, never grey (§4 gotcha 6).
    static let mutedText = AppTheme.Retro.panelText.opacity(0.7)

    /// Full-bleed scrim behind the quiz sheet, the coach card and the victory
    /// stamp. Ink rather than raw black — the overlays sit on candy, not on
    /// system chrome.
    static let scrim = AppTheme.Retro.ink.opacity(0.5)

    // MARK: - Medals (results screen; the mustard/cornflower/cocoa pattern
    // shared with Movie Chain and Vibe Check)

    static let medalFirst = AppTheme.Retro.mustard
    static let medalSecond = AppTheme.Retro.cornflower
    static let medalThird = AppTheme.Retro.cocoa

    // MARK: - Difficulty ramp
    //
    // `BorderHopDifficulty.badgeColor` lives in Models/ and is untouched; this
    // is the view-layer remap the migrated screens read instead.
    // Easy → grass, Medium → tangerine, Hard → tomato, Expert → lilac
    // (`AppTheme.electricIndigo` `7B6CF6` → lilac). Rendered as a chip inside a
    // cream card, never as a page fill (§8).
    static func difficultyColor(_ difficulty: BorderHopDifficulty) -> Color {
        switch difficulty {
        case .easy: return correctColor
        case .medium: return reviewColor
        case .hard: return wrongColor
        case .expert: return AppTheme.Retro.lilac
        }
    }

    /// §8: ink passes on every candy fill this game uses; plum and cocoa are
    /// the two dark enough to need cream instead. Kept as the single honest
    /// call site so chips can't drift.
    static func chipTextColor(on color: Color) -> Color {
        (color == AppTheme.Retro.plum || color == AppTheme.Retro.cocoa)
            ? AppTheme.Retro.cream
            : AppTheme.Retro.ink
    }

    /// `chipTextColor(on:)` for call sites whose fill may be the adaptive cream
    /// panel — that one follows the color scheme instead of taking a fixed ink.
    static func panelAwareTextColor(on color: Color) -> Color {
        color == AppTheme.Retro.panel ? AppTheme.Retro.panelText : chipTextColor(on: color)
    }

    // MARK: - Map palette
    //
    // Named values for every color BorderHopMapView's Canvas draws. The map
    // branches on `colorScheme` in several places and that branching structure
    // is preserved verbatim — only the values changed — so the two variants
    // stay paired here rather than behind an adaptive token. (Adaptive
    // `UIColor` providers are deliberately avoided *inside* Canvas: the
    // GraphicsContext resolves colors once, so an explicit `isDark` pair is
    // the reliable form. SwiftUI chrome around the canvas — mini-map plate,
    // recenter button, edge pills — uses the adaptive Retro tokens.)
    //
    // The world reads as a printed map: cream sea, cocoa-tinted land, the
    // player's country flat cornflower, the goal flat mustard, ink linework
    // throughout (cream linework at night, where ink would vanish on the dark
    // ground — §3.3's "add a cream rule if separation suffers").
    enum Map {
        // Ocean / page ground for the map. Cream by day so the candy country
        // fills read as ink-outlined blocks on paper.
        static let oceanLight = AppTheme.Retro.cream
        static let oceanDark = AppTheme.Retro.darkGround

        // Non-game land masses — scenery. Flat cocoa tint on cream, flat cream
        // tint on the night ground.
        static let decorativeFillLight = AppTheme.Retro.cocoa.opacity(0.18)
        static let decorativeFillDark = AppTheme.Retro.cream.opacity(0.10)
        static let decorativeStrokeLight = AppTheme.Retro.ink.opacity(0.35)
        static let decorativeStrokeDark = AppTheme.Retro.cream.opacity(0.22)

        // In-play but not yet relevant countries — a step darker than the
        // scenery, the same relationship the retired greys had.
        static let foggedFillLight = AppTheme.Retro.cocoa.opacity(0.32)
        static let foggedFillDark = AppTheme.Retro.cream.opacity(0.18)
        static let foggedStrokeLight = AppTheme.Retro.ink.opacity(0.5)
        static let foggedStrokeDark = AppTheme.Retro.cream.opacity(0.32)

        // Tappable neighbors. The retired accent glow is gone (§9) — a solid
        // ink outline plus a pale cornflower wash carries the affordance.
        static let frontierFillLight = accent.opacity(0.30)
        static let frontierFillDark = accent.opacity(0.38)
        static let frontierStrokeLight = AppTheme.Retro.ink
        static let frontierStrokeDark = AppTheme.Retro.cream

        // Where the player has been — cornflower-tinted, dashed outline.
        static let visitedFillLight = accent.opacity(0.18)
        static let visitedFillDark = accent.opacity(0.24)
        static let visitedStrokeLight = AppTheme.Retro.ink.opacity(0.55)
        static let visitedStrokeDark = AppTheme.Retro.cream.opacity(0.5)

        /// "You are here" — flat game accent in both schemes (§3.3: accents
        /// stay at full saturation at night).
        static let currentFill = accent
        /// White marker outlines are retired; ink passes on cornflower (§8).
        static let currentStroke = AppTheme.Retro.ink

        /// The goal. `AppTheme.medalGold` → mustard, filled flat now that the
        /// gold glow is gone.
        static let destination = goalColor
        static let destinationStroke = AppTheme.Retro.ink
        /// Checkered-flag glyph, drawn over the flat mustard destination.
        static let destinationGlyph = AppTheme.Retro.ink

        /// Dashed route line. Flat accent (§2 rule 2) instead of the old 55%
        /// alpha wash.
        static let trail = accent

        // Country labels. Ink on the cream sea by day, cream at night.
        static let labelPrimaryLight = AppTheme.Retro.ink
        static let labelPrimaryDark = AppTheme.Retro.cream
        static let labelDestinationLight = AppTheme.Retro.cocoa
        static let labelDestinationDark = AppTheme.Retro.mustard
        static let labelSecondaryLight = AppTheme.Retro.cocoa.opacity(0.75)
        static let labelSecondaryDark = AppTheme.Retro.cream.opacity(0.65)
        /// Solid halo behind map labels (the only legibility device left after
        /// the soft shadows went — see DECISIONS 2026-08-23).
        static let labelHaloLight = AppTheme.Retro.cream
        static let labelHaloDark = AppTheme.Retro.ink

        // Player marker: ink ring, cream plate, cornflower pip — the hub's
        // spot-plate anatomy at 14pt.
        static let markerRing = AppTheme.Retro.ink
        static let markerPlate = AppTheme.Retro.cream
        static let markerPip = accent

        // Mini-map.
        static let miniLandLight = AppTheme.Retro.cocoa.opacity(0.30)
        static let miniLandDark = AppTheme.Retro.cream.opacity(0.30)
        static let miniViewport = accent
        static let miniDestination = goalColor
        static let miniPlayerRing = AppTheme.Retro.ink
        static let miniPlayerPip = accent
    }
}

// MARK: - Shared header furniture (§3 recipe)

/// Suitcase spot illustration on an ink-outlined cream plate. Replaces the
/// naked SF heroes the screens used to open with (§9).
struct BorderHopSpotPlate: View {
    var diameter: CGFloat = 96

    var body: some View {
        ZStack {
            Circle().fill(AppTheme.Retro.panel)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
            RetroSpotIllustration(kind: .hopMap)
                .frame(width: diameter * 0.72, height: diameter * 0.72)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// Framed Lilita title on the cornflower panel with the hard ink offset and the
/// ±1° tilt (§3 recipe, Rule 4). "Border Hop" is past the ~8-char Shrikhand cap
/// (§4), so the game name stays Lilita.
struct BorderHopTitlePanel: View {
    let text: String
    var size: CGFloat = 22
    var tilt: Double = -1

    var body: some View {
        Text(text)
            .font(AppTheme.Retro.Typography.heading(size, relativeTo: .title2))
            .foregroundColor(BorderHopStyle.chipTextColor(on: BorderHopStyle.accent))
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .retroPanel(BorderHopStyle.accent)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                    .fill(AppTheme.Retro.ink)
                    .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
            )
            .rotationEffect(.degrees(tilt))
    }
}

/// Functional SF glyph on an ink-outlined plate (§6). Used for the map's
/// step/way-marker icons where a full spot illustration would be too loud.
struct BorderHopGlyphPlate: View {
    let systemImage: String
    var fill: Color = AppTheme.Retro.panel
    var diameter: CGFloat = 44
    var glyphSize: CGFloat = 20

    /// The cream plate follows the scheme (`panelText`); candy plates take the
    /// §8 chip rule.
    private var glyphColor: Color {
        BorderHopStyle.panelAwareTextColor(on: fill)
    }

    var body: some View {
        ZStack {
            Circle().fill(fill)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
            Image(systemName: systemImage)
                .font(.system(size: glyphSize, weight: .bold))
                .foregroundColor(glyphColor)
        }
        .frame(width: diameter, height: diameter)
    }
}
