# Retro Migration Phase 2 — Hub Re-Skin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate `GameHubView` to the Retro Maximalist look — logo lockup, candy shelf cards, and the nine per-game spot illustrations — per `GamesWithFriends/ART_DIRECTION.md` with the Option C artboard as the visual spec.

**Architecture:** Three additions on top of the phase-1 foundations: (1) a per-game candy accent map on `AppTheme.Retro` (GameTheme keeps its old values until phase 3); (2) `RetroSpotIllustrations.swift` — a `RetroSpotKind` enum mapped from game ids plus a `Canvas`-drawn `RetroSpotIllustration` view (six spots ported from the Option C artboard SVGs, three new ones in the same recipe); (3) a rewritten `GameHubView` that composes `MotifGroundView`, a `RetroHubHeader` lockup, and `RetroHubGameCard` rows styled with the phase-1 modifiers.

**Tech Stack:** SwiftUI (iOS 17+), XCTest, legacy `project.pbxproj` (manual 4-place file registration), simulator **iPhone 17** (the AGENTS.md "iPhone 15" is not installed).

**Delegation:** Per the roadmap in `docs/superpowers/plans/2026-08-22-retro-migration-phase-1.md`, phase 2 is Fable-direct work (design-sensitive illustration + layout); no agent offload, all builds in the main session.

**Working directory for all commands:** `GamesWithFriends/` (the subdir containing the `.xcodeproj`). Tests live at `GamesWithFriends/GamesWithFriendsTests/` (nested — see DECISIONS.md gotcha).

**Deliberate deviations from the Option C artboard** (spec-driven; record in DECISIONS.md in Task 5):
1. The "PARTY GAMES FOR YOUR TABLE" tagline pill is omitted — ART_DIRECTION §11 marks that copy as placeholder, not adopted.
2. Card descriptions sit in a cream mini-panel (ink text), not naked on the accent. §8 requires body copy on tomato/grass/lilac/cornflower/berry to move into a cream device; a uniform treatment across all nine cards keeps the shelf consistent and makes contrast failures structurally impossible.
3. Logo stays at the phase-1 `Typography.logo` size (40 pt vs the artboard's 44 px) — Dynamic Type scaling needs the headroom on a 390 pt screen.

---

### Task 1: Per-game candy accent map

**Files:**
- Modify: `GamesWithFriends/Theme/RetroTheme.swift` (append at end of file)
- Test: `GamesWithFriends/GamesWithFriendsTests/RetroThemeTests.swift` (append inside the class)

- [ ] **Step 1: Write the failing tests**

Append inside `final class RetroThemeTests` (the `assertSameColor(_:hex:)` helper already exists at the top of the class):

```swift
    // MARK: - Phase 2: hub accent map (ART_DIRECTION §3.2)

    func testHubAccentMapMatchesArtDirection() {
        let expected: [String: String] = [
            "conversation-starters": "F387B8",
            "country-letter-game": "57A34F",
            "name-5-game": "A08BE0",
            "border-blitz": "5BC0DF",
            "movie-chain": "E8442E",
            "casting-director": "F07C24",
            "vibecheck": "C64B7E",
            "border-hop": "6C9BD2",
            "finish-the-line": "8E4585"
        ]
        for (id, hex) in expected {
            guard let accent = AppTheme.Retro.accent(forGameID: id) else {
                XCTFail("No candy accent for \(id)")
                continue
            }
            assertSameColor(accent, hex: hex)
        }
        XCTAssertNil(AppTheme.Retro.accent(forGameID: "unknown-game"))
    }

    func testEveryRegisteredGameHasACandyAccent() {
        for game in GameRegistry.allGames() {
            XCTAssertNotNil(AppTheme.Retro.accent(forGameID: game.id),
                            "\(game.id) has no candy accent — mustard is the ground, never a fallback")
        }
    }
```

- [ ] **Step 2: Run the tests to verify they fail**

```bash
cd GamesWithFriends && xcodebuild -project GamesWithFriends.xcodeproj -scheme GamesWithFriends -destination 'platform=iOS Simulator,name=iPhone 17' test 2>&1 | grep -E "error:|Test Suite|Test Case .*(passed|failed)|\*\* TEST"
```

Expected: compile error — `type 'AppTheme.Retro' has no member 'accent'`.

- [ ] **Step 3: Implement the accent map**

Append at the end of `GamesWithFriends/Theme/RetroTheme.swift`:

```swift
// MARK: - Per-game candy accents (§3.2). GameTheme still carries the old
// muted values until phase 3; migrated screens read accents from here.
extension AppTheme.Retro {
    /// Candy accent for a game id per ART_DIRECTION §3.2. Returns nil for
    /// unknown ids so callers pick their own fallback. Mustard is never a
    /// game accent — it is the ground.
    static func accent(forGameID id: String) -> Color? {
        switch id {
        case "conversation-starters": return bubblegum
        case "country-letter-game": return grass
        case "name-5-game": return lilac
        case "border-blitz": return poolBlue
        case "movie-chain": return tomato
        case "casting-director": return tangerine
        case "vibecheck": return berry
        case "border-hop": return cornflower
        case "finish-the-line": return plum
        default: return nil
        }
    }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Same command as Step 2. Expected: all `RetroThemeTests` pass (10 existing + 2 new).

- [ ] **Step 5: Commit**

```bash
git add GamesWithFriends/Theme/RetroTheme.swift GamesWithFriends/GamesWithFriendsTests/RetroThemeTests.swift
git commit -m "feat: per-game candy accent map for retro hub (ART_DIRECTION §3.2)"
```

---

### Task 2: Spot illustrations — `RetroSpotKind` + nine Canvas drawings

**Files:**
- Create: `GamesWithFriends/Theme/RetroSpotIllustrations.swift`
- Modify: `GamesWithFriends/GamesWithFriends.xcodeproj/project.pbxproj` (4 places)
- Test: `GamesWithFriends/GamesWithFriendsTests/RetroThemeTests.swift` (append inside the class)

- [ ] **Step 1: Write the failing test**

Append inside `RetroThemeTests`:

```swift
    // MARK: - Phase 2: spot illustrations (ART_DIRECTION §6)

    func testEveryRegisteredGameHasADistinctSpotIllustration() {
        let games = GameRegistry.allGames()
        var kinds = Set<RetroSpotKind>()
        for game in games {
            guard let kind = RetroSpotKind(gameID: game.id) else {
                XCTFail("No spot illustration for \(game.id)")
                continue
            }
            kinds.insert(kind)
        }
        XCTAssertEqual(kinds.count, games.count, "each game owns its own spot illustration")
        XCTAssertNil(RetroSpotKind(gameID: "unknown-game"))
        XCTAssertEqual(RetroSpotKind.allCases.count, games.count,
                       "no orphaned illustration kinds")
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Same test command as Task 1 Step 2. Expected: compile error — `cannot find 'RetroSpotKind' in scope`.

- [ ] **Step 3: Create `RetroSpotIllustrations.swift`**

Create `GamesWithFriends/Theme/RetroSpotIllustrations.swift` with exactly:

```swift
import SwiftUI

// ART_DIRECTION §6: spot illustrations replace decorative SF Symbols. Flat
// candy fills, 3 pt ink outlines in a 64 pt art box, rounded joins, faces per
// Rule 6, at most one sparkle garnish per spot. The first six are ported from
// the adopted Option C artboard SVGs; the three below-the-fold games follow
// the same recipe.
enum RetroSpotKind: CaseIterable, Hashable {
    case speechBubbles   // Conversation Starters
    case globe           // Country Letter Challenge
    case burstFive       // Name 5
    case borderMap       // Border Blitz
    case filmFrame       // Movie Chain
    case starFace        // Casting Director
    case heart           // Vibe Check
    case suitcase        // Border Hop
    case clapperboard    // Finish the Line

    init?(gameID: String) {
        switch gameID {
        case "conversation-starters": self = .speechBubbles
        case "country-letter-game": self = .globe
        case "name-5-game": self = .burstFive
        case "border-blitz": self = .borderMap
        case "movie-chain": self = .filmFrame
        case "casting-director": self = .starFace
        case "vibecheck": self = .heart
        case "border-hop": self = .suitcase
        case "finish-the-line": self = .clapperboard
        default: return nil
        }
    }
}

/// One spot illustration, scaled to fit its container. Decorative — hidden
/// from accessibility (hub cards carry the game name as their label).
struct RetroSpotIllustration: View {
    let kind: RetroSpotKind

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 64
            context.scaleBy(x: scale, y: scale)
            RetroSpotPainter.draw(kind, in: &context)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Painter

enum RetroSpotPainter {
    private static let ink = AppTheme.Retro.ink

    static func draw(_ kind: RetroSpotKind, in context: inout GraphicsContext) {
        switch kind {
        case .speechBubbles: speechBubbles(&context)
        case .globe: globe(&context)
        case .burstFive: burstFive(&context)
        case .borderMap: borderMap(&context)
        case .filmFrame: filmFrame(&context)
        case .starFace: starFace(&context)
        case .heart: heart(&context)
        case .suitcase: suitcase(&context)
        case .clapperboard: clapperboard(&context)
        }
    }

    // MARK: Shared vocabulary

    /// Flat fill + uniform ink outline (Rules 1 and 2).
    private static func paint(_ c: inout GraphicsContext, _ path: Path,
                              fill: Color, lineWidth: CGFloat = 3) {
        c.fill(path, with: .color(fill))
        c.stroke(path, with: .color(ink),
                 style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
    }

    /// Dot eyes + smile (Rule 6). Cream on dark fills, ink on light fills.
    private static func face(_ c: inout GraphicsContext,
                             leftEye: CGPoint, rightEye: CGPoint,
                             color: Color = AppTheme.Retro.ink) {
        for eye in [leftEye, rightEye] {
            let dot = Path(ellipseIn: CGRect(x: eye.x - 1.8, y: eye.y - 1.8,
                                             width: 3.6, height: 3.6))
            c.fill(dot, with: .color(color))
        }
        var smile = Path()
        smile.move(to: CGPoint(x: leftEye.x, y: leftEye.y + 5))
        smile.addQuadCurve(to: CGPoint(x: rightEye.x, y: rightEye.y + 5),
                           control: CGPoint(x: (leftEye.x + rightEye.x) / 2,
                                            y: leftEye.y + 9))
        c.stroke(smile, with: .color(color),
                 style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    }

    private static func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat) -> Path {
        var p = Path()
        for i in 0..<10 {
            let r = i.isMultiple(of: 2) ? outer : inner
            let angle = Angle(degrees: Double(i) * 36 - 90).radians
            let pt = CGPoint(x: center.x + r * CGFloat(cos(angle)),
                             y: center.y + r * CGFloat(sin(angle)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    private static func sparklePath(center: CGPoint, r: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: center.x, y: center.y - r))
        p.addLine(to: CGPoint(x: center.x + r * 0.25, y: center.y - r * 0.25))
        p.addLine(to: CGPoint(x: center.x + r, y: center.y))
        p.addLine(to: CGPoint(x: center.x + r * 0.25, y: center.y + r * 0.25))
        p.addLine(to: CGPoint(x: center.x, y: center.y + r))
        p.addLine(to: CGPoint(x: center.x - r * 0.25, y: center.y + r * 0.25))
        p.addLine(to: CGPoint(x: center.x - r, y: center.y))
        p.addLine(to: CGPoint(x: center.x - r * 0.25, y: center.y - r * 0.25))
        p.closeSubpath()
        return p
    }

    // MARK: Conversation Starters — two chatting bubbles

    private static func speechBubbles(_ c: inout GraphicsContext) {
        var big = Path()
        big.move(to: CGPoint(x: 8, y: 14))
        big.addLine(to: CGPoint(x: 38, y: 14))
        big.addQuadCurve(to: CGPoint(x: 43, y: 19), control: CGPoint(x: 43, y: 14))
        big.addLine(to: CGPoint(x: 43, y: 33))
        big.addQuadCurve(to: CGPoint(x: 38, y: 38), control: CGPoint(x: 43, y: 38))
        big.addLine(to: CGPoint(x: 22, y: 38))
        big.addLine(to: CGPoint(x: 13, y: 46))
        big.addLine(to: CGPoint(x: 13, y: 38))
        big.addLine(to: CGPoint(x: 8, y: 38))
        big.addQuadCurve(to: CGPoint(x: 3, y: 33), control: CGPoint(x: 3, y: 38))
        big.addLine(to: CGPoint(x: 3, y: 19))
        big.addQuadCurve(to: CGPoint(x: 8, y: 14), control: CGPoint(x: 3, y: 14))
        big.closeSubpath()
        paint(&c, big, fill: AppTheme.Retro.bubblegum)
        face(&c, leftEye: CGPoint(x: 18, y: 24), rightEye: CGPoint(x: 28, y: 24))

        var small = Path()
        small.move(to: CGPoint(x: 44, y: 30))
        small.addLine(to: CGPoint(x: 54, y: 30))
        small.addQuadCurve(to: CGPoint(x: 58, y: 34), control: CGPoint(x: 58, y: 30))
        small.addLine(to: CGPoint(x: 58, y: 42))
        small.addQuadCurve(to: CGPoint(x: 54, y: 46), control: CGPoint(x: 58, y: 46))
        small.addLine(to: CGPoint(x: 54, y: 52))
        small.addLine(to: CGPoint(x: 47, y: 46))
        small.addLine(to: CGPoint(x: 44, y: 46))
        small.addQuadCurve(to: CGPoint(x: 40, y: 42), control: CGPoint(x: 40, y: 46))
        small.addLine(to: CGPoint(x: 40, y: 34))
        small.addQuadCurve(to: CGPoint(x: 44, y: 30), control: CGPoint(x: 40, y: 30))
        small.closeSubpath()
        paint(&c, small, fill: AppTheme.Retro.poolBlue)
    }

    // MARK: Country Letter Challenge — smiling globe

    private static func globe(_ c: inout GraphicsContext) {
        let sphere = Path(ellipseIn: CGRect(x: 10, y: 10, width: 44, height: 44))
        paint(&c, sphere, fill: AppTheme.Retro.grass)

        var lat1 = Path()
        lat1.move(to: CGPoint(x: 12, y: 26))
        lat1.addQuadCurve(to: CGPoint(x: 32, y: 26), control: CGPoint(x: 22, y: 32))
        lat1.addQuadCurve(to: CGPoint(x: 50, y: 28), control: CGPoint(x: 42, y: 20))
        var lat2 = Path()
        lat2.move(to: CGPoint(x: 14, y: 42))
        lat2.addQuadCurve(to: CGPoint(x: 32, y: 42), control: CGPoint(x: 23, y: 37))
        lat2.addQuadCurve(to: CGPoint(x: 48, y: 40), control: CGPoint(x: 41, y: 47))
        for lat in [lat1, lat2] {
            c.stroke(lat, with: .color(AppTheme.Retro.cream),
                     style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        face(&c, leftEye: CGPoint(x: 26, y: 30), rightEye: CGPoint(x: 38, y: 30))
    }

    // MARK: Name 5 — sixteen-point burst with a big 5

    private static func burstFive(_ c: inout GraphicsContext) {
        let pts: [CGPoint] = [
            CGPoint(x: 32, y: 4), CGPoint(x: 37, y: 18), CGPoint(x: 51, y: 12),
            CGPoint(x: 45, y: 25), CGPoint(x: 60, y: 28), CGPoint(x: 46, y: 34),
            CGPoint(x: 54, y: 46), CGPoint(x: 40, y: 42), CGPoint(x: 38, y: 58),
            CGPoint(x: 30, y: 45), CGPoint(x: 20, y: 54), CGPoint(x: 23, y: 39),
            CGPoint(x: 8, y: 38), CGPoint(x: 21, y: 30), CGPoint(x: 12, y: 16),
            CGPoint(x: 27, y: 21)
        ]
        var burst = Path()
        burst.move(to: pts[0])
        for p in pts.dropFirst() { burst.addLine(to: p) }
        burst.closeSubpath()
        paint(&c, burst, fill: AppTheme.Retro.tomato)

        let five = Text("5").font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
        c.draw(five.foregroundStyle(ink), at: CGPoint(x: 33.2, y: 33.2))
        c.draw(five.foregroundStyle(Color.white), at: CGPoint(x: 32, y: 32))
    }

    // MARK: Border Blitz — country blob with dashed borders and a flag

    private static func borderMap(_ c: inout GraphicsContext) {
        var blob = Path()
        blob.move(to: CGPoint(x: 10, y: 20))
        blob.addQuadCurve(to: CGPoint(x: 26, y: 10), control: CGPoint(x: 14, y: 8))
        blob.addQuadCurve(to: CGPoint(x: 40, y: 8), control: CGPoint(x: 34, y: 12))
        blob.addQuadCurve(to: CGPoint(x: 56, y: 16), control: CGPoint(x: 52, y: 4))
        blob.addQuadCurve(to: CGPoint(x: 52, y: 32), control: CGPoint(x: 59, y: 26))
        blob.addQuadCurve(to: CGPoint(x: 48, y: 44), control: CGPoint(x: 46, y: 37))
        blob.addQuadCurve(to: CGPoint(x: 40, y: 53), control: CGPoint(x: 49, y: 52))
        blob.addQuadCurve(to: CGPoint(x: 28, y: 47), control: CGPoint(x: 31, y: 54))
        blob.addQuadCurve(to: CGPoint(x: 19, y: 41), control: CGPoint(x: 26, y: 41))
        blob.addQuadCurve(to: CGPoint(x: 8, y: 31), control: CGPoint(x: 9, y: 40))
        blob.addQuadCurve(to: CGPoint(x: 10, y: 20), control: CGPoint(x: 7, y: 24))
        blob.closeSubpath()
        paint(&c, blob, fill: AppTheme.Retro.poolBlue)

        var b1 = Path()
        b1.move(to: CGPoint(x: 20, y: 26))
        b1.addQuadCurve(to: CGPoint(x: 44, y: 30), control: CGPoint(x: 28, y: 34))
        var b2 = Path()
        b2.move(to: CGPoint(x: 24, y: 42))
        b2.addQuadCurve(to: CGPoint(x: 38, y: 44), control: CGPoint(x: 32, y: 40))
        for border in [b1, b2] {
            c.stroke(border, with: .color(.white),
                     style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [4, 4]))
        }

        var flag = Path()
        flag.move(to: CGPoint(x: 40, y: 14))
        flag.addLine(to: CGPoint(x: 40, y: 6))
        flag.addLine(to: CGPoint(x: 50, y: 9))
        flag.addLine(to: CGPoint(x: 40, y: 12))
        flag.closeSubpath()
        paint(&c, flag, fill: AppTheme.Retro.tomato, lineWidth: 2)
    }

    // MARK: Movie Chain — film frame with a star

    private static func filmFrame(_ c: inout GraphicsContext) {
        let frame = Path(roundedRect: CGRect(x: 6, y: 16, width: 52, height: 34),
                         cornerRadius: 5)
        paint(&c, frame, fill: AppTheme.Retro.mustard)
        var rails = Path()
        rails.move(to: CGPoint(x: 16, y: 16))
        rails.addLine(to: CGPoint(x: 16, y: 50))
        rails.move(to: CGPoint(x: 48, y: 16))
        rails.addLine(to: CGPoint(x: 48, y: 50))
        c.stroke(rails, with: .color(ink), style: StrokeStyle(lineWidth: 2.4))
        let star = starPath(center: CGPoint(x: 32, y: 33), outer: 9, inner: 3.6)
        paint(&c, star, fill: AppTheme.Retro.tomato, lineWidth: 2)
    }

    // MARK: Casting Director — smiling star

    private static func starFace(_ c: inout GraphicsContext) {
        let star = starPath(center: CGPoint(x: 32, y: 29), outer: 24, inner: 9.5)
        paint(&c, star, fill: AppTheme.Retro.tangerine)
        face(&c, leftEye: CGPoint(x: 27, y: 26), rightEye: CGPoint(x: 37, y: 26))
    }

    // MARK: Vibe Check — smiling heart (new, berry)

    private static func heart(_ c: inout GraphicsContext) {
        var h = Path()
        h.move(to: CGPoint(x: 32, y: 54))
        h.addCurve(to: CGPoint(x: 11, y: 18),
                   control1: CGPoint(x: 12, y: 40), control2: CGPoint(x: 6, y: 27))
        h.addCurve(to: CGPoint(x: 32, y: 16),
                   control1: CGPoint(x: 16, y: 8), control2: CGPoint(x: 28, y: 8))
        h.addCurve(to: CGPoint(x: 53, y: 18),
                   control1: CGPoint(x: 36, y: 8), control2: CGPoint(x: 48, y: 8))
        h.addCurve(to: CGPoint(x: 32, y: 54),
                   control1: CGPoint(x: 58, y: 27), control2: CGPoint(x: 52, y: 40))
        h.closeSubpath()
        paint(&c, h, fill: AppTheme.Retro.berry)
        face(&c, leftEye: CGPoint(x: 26, y: 27), rightEye: CGPoint(x: 38, y: 27),
             color: AppTheme.Retro.cream)
        let sparkle = sparklePath(center: CGPoint(x: 56, y: 9), r: 6)
        paint(&c, sparkle, fill: AppTheme.Retro.cream, lineWidth: 2)
    }

    // MARK: Border Hop — hopping suitcase (new, cornflower)

    private static func suitcase(_ c: inout GraphicsContext) {
        let handle = Path(roundedRect: CGRect(x: 24, y: 14, width: 16, height: 10),
                          cornerRadius: 4)
        paint(&c, handle, fill: AppTheme.Retro.cornflower, lineWidth: 2.4)
        let body = Path(roundedRect: CGRect(x: 10, y: 22, width: 44, height: 30),
                        cornerRadius: 6)
        paint(&c, body, fill: AppTheme.Retro.cornflower)
        let sticker = Path(ellipseIn: CGRect(x: 42, y: 27, width: 9, height: 9))
        paint(&c, sticker, fill: AppTheme.Retro.cream, lineWidth: 2)
        face(&c, leftEye: CGPoint(x: 23, y: 36), rightEye: CGPoint(x: 33, y: 36))
        var hop = Path()
        hop.move(to: CGPoint(x: 6, y: 14))
        hop.addQuadCurve(to: CGPoint(x: 20, y: 8), control: CGPoint(x: 10, y: 4))
        c.stroke(hop, with: .color(ink),
                 style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [3, 4]))
    }

    // MARK: Finish the Line — smiling clapperboard (new, plum)

    private static func clapperboard(_ c: inout GraphicsContext) {
        let bar = Path(roundedRect: CGRect(x: 8, y: 16, width: 48, height: 11),
                       cornerRadius: 3)
        c.fill(bar, with: .color(AppTheme.Retro.plum))
        var striped = c
        striped.clip(to: bar)
        for i in 0..<4 {
            let x0 = CGFloat(10 + i * 12)
            var s = Path()
            s.move(to: CGPoint(x: x0, y: 27))
            s.addLine(to: CGPoint(x: x0 + 5, y: 16))
            s.addLine(to: CGPoint(x: x0 + 10, y: 16))
            s.addLine(to: CGPoint(x: x0 + 5, y: 27))
            s.closeSubpath()
            striped.fill(s, with: .color(AppTheme.Retro.cream))
        }
        c.stroke(bar, with: .color(ink),
                 style: StrokeStyle(lineWidth: 3, lineJoin: .round))
        let board = Path(roundedRect: CGRect(x: 8, y: 29, width: 48, height: 24),
                         cornerRadius: 4)
        paint(&c, board, fill: AppTheme.Retro.plum)
        face(&c, leftEye: CGPoint(x: 26, y: 38), rightEye: CGPoint(x: 38, y: 38),
             color: AppTheme.Retro.cream)
        let sparkle = sparklePath(center: CGPoint(x: 58, y: 8), r: 5)
        paint(&c, sparkle, fill: AppTheme.Retro.cream, lineWidth: 2)
    }
}

// MARK: - Preview

#Preview("Retro Spots") {
    ZStack {
        AppTheme.Retro.ground.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
            ForEach(RetroSpotKind.allCases, id: \.self) { kind in
                ZStack {
                    Circle().fill(AppTheme.Retro.panel)
                    Circle().stroke(AppTheme.Retro.ink,
                                    lineWidth: AppTheme.Retro.strokeWidth)
                    RetroSpotIllustration(kind: kind)
                        .padding(8)
                }
                .frame(width: 80, height: 80)
            }
        }
        .padding()
    }
}
```

- [ ] **Step 4: Register the file in project.pbxproj (4 places)**

Edit `GamesWithFriends/GamesWithFriends.xcodeproj/project.pbxproj`, following the phase-1 `TH…` pattern (suffix `F`):

1. **PBXBuildFile** — after the line containing `TH000001000000000000000E /* MotifGroundView.swift in Sources */`, add:
```
		TH000001000000000000000F /* RetroSpotIllustrations.swift in Sources */ = {isa = PBXBuildFile; fileRef = TH000002000000000000000F /* RetroSpotIllustrations.swift */; };
```
2. **PBXFileReference** — after the line containing `TH000002000000000000000E /* MotifGroundView.swift */`, add:
```
		TH000002000000000000000F /* RetroSpotIllustrations.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RetroSpotIllustrations.swift; sourceTree = "<group>"; };
```
3. **Theme group children** — find the group children list entry `TH000002000000000000000C /* RetroComponents.swift */,` and add after it:
```
				TH000002000000000000000F /* RetroSpotIllustrations.swift */,
```
4. **Sources build phase** — find `TH000001000000000000000E /* MotifGroundView.swift in Sources */,` and add after it:
```
				TH000001000000000000000F /* RetroSpotIllustrations.swift in Sources */,
```

- [ ] **Step 5: Run the tests to verify they pass**

Same test command as Task 1 Step 2. Expected: all tests pass, including `testEveryRegisteredGameHasADistinctSpotIllustration`.

- [ ] **Step 6: Commit**

```bash
git add GamesWithFriends/Theme/RetroSpotIllustrations.swift GamesWithFriends/GamesWithFriendsTests/RetroThemeTests.swift GamesWithFriends/GamesWithFriends.xcodeproj/project.pbxproj
git commit -m "feat: nine retro spot illustrations (six ported from Option C, three new)"
```

---

### Task 3: Hub re-skin — lockup header + candy shelf cards

**Files:**
- Modify: `GamesWithFriends/Features/GameHub/GameHubView.swift` (full rewrite)

- [ ] **Step 1: Rewrite `GameHubView.swift`**

Replace the entire file content with:

```swift
import SwiftUI

// Phase-2 migrated screen (ART_DIRECTION §10.2): motif ground, Shrikhand
// lockup, candy shelf cards. The Option C artboard is the spec; deviations
// are logged in DECISIONS.md (tagline omitted, descriptions panelled).
struct GameHubView: View {
    let games = GameRegistry.allGames()

    var body: some View {
        NavigationStack {
            ZStack {
                GeometryReader { geo in
                    // Motifs live in the gutters and top strip; the exclusion
                    // keeps them ≥12pt clear of the interactive card column (§7).
                    MotifGroundView(exclusions: [CGRect(x: 36, y: 110,
                                                        width: geo.size.width - 72,
                                                        height: geo.size.height - 110)])
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        RetroHubHeader()
                            .padding(.top, AppTheme.Spacing.lg)
                            .padding(.bottom, AppTheme.Spacing.lg)

                        // 20pt gap and gutters from the artboard; the extra
                        // room also clears the 5pt hard shadows.
                        VStack(spacing: 20) {
                            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                                NavigationLink(destination: game.makeRootView()) {
                                    RetroHubGameCard(game: game)
                                }
                                .buttonStyle(RetroRaisedButtonStyle())
                                .rotationEffect(.degrees(index.isMultiple(of: 2) ? -0.6 : 0.6))
                                .accessibilityLabel("\(game.name). \(game.description)")
                                .accessibilityHint("Double tap to play")
                                .staggeredAppear(index: index)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, AppTheme.Spacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Header lockup (Rule 4: chunky framed lettering)

private struct RetroHubHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Text("GAMES")
                .font(AppTheme.Retro.Typography.logo)
                .foregroundColor(.white)
                .shadow(color: AppTheme.Retro.tomato, radius: 0, x: 3, y: 3)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.xs)
                .retroPanel(AppTheme.Retro.bubblegum)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset,
                                y: AppTheme.Retro.shadowOffset)
                )
                .rotationEffect(.degrees(-1.5))

            // Tomato on cream ≈ 3.2:1 — passes as large text (20px heavy face).
            Text("with friends")
                .font(AppTheme.Retro.Typography.heading(15, relativeTo: .subheadline))
                .foregroundColor(AppTheme.Retro.tomato)
                .retroLozenge()
                .rotationEffect(.degrees(1))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Games with Friends")
    }
}

// MARK: - Candy shelf card (§5 card anatomy)

struct RetroHubGameCard: View {
    let game: AnyGameDefinition

    private var accent: Color {
        AppTheme.Retro.accent(forGameID: game.id) ?? AppTheme.Retro.tangerine
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                // Title lozenge — ink-on-cream, always safe (§8).
                Text(game.name)
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(AppTheme.Retro.panel))
                    .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))

                // Description mini-panel — §8: body copy never sits naked on
                // a saturated accent.
                Text(game.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                            .fill(AppTheme.Retro.panel)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                            .stroke(AppTheme.Retro.ink, lineWidth: 2)
                    )
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 66pt cream circle plate with the game's spot illustration.
            ZStack {
                Circle().fill(AppTheme.Retro.panel)
                Circle().stroke(AppTheme.Retro.ink,
                                lineWidth: AppTheme.Retro.strokeWidth)
                if let kind = RetroSpotKind(gameID: game.id) {
                    RetroSpotIllustration(kind: kind)
                        .frame(width: 52, height: 52)
                } else {
                    Image(systemName: game.iconName)
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundColor(accent)
                }
            }
            .frame(width: 66, height: 66)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .retroPanel(accent)
    }
}

#Preview {
    GameHubView()
        .modelContainer(for: FinishTheLineRoundResult.self, inMemory: true)
}
```

- [ ] **Step 2: Build**

```bash
cd GamesWithFriends && xcodebuild -project GamesWithFriends.xcodeproj -scheme GamesWithFriends -destination 'platform=iOS Simulator,name=iPhone 17' build 2>&1 | grep -E "error:|warning:|\*\* BUILD" | head -20
```

Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 3: Run the full test suite**

```bash
cd GamesWithFriends && xcodebuild -project GamesWithFriends.xcodeproj -scheme GamesWithFriends -destination 'platform=iOS Simulator,name=iPhone 17' test 2>&1 | grep -E "error:|Test Suite|Test Case .*(passed|failed)|\*\* TEST"
```

Expected: all tests pass (24 total: 21 from phase 1 + 3 new).

- [ ] **Step 4: Commit**

```bash
git add GamesWithFriends/Features/GameHub/GameHubView.swift
git commit -m "feat: migrate GameHubView to retro maximalist (phase 2)"
```

---

### Task 4: Visual verification on simulator (light + dark)

The hub is the app's root view, so no env-var harness is needed — build, install, launch, screenshot.

- [ ] **Step 1: Install and launch on iPhone 17**

```bash
cd GamesWithFriends && xcodebuild -project GamesWithFriends.xcodeproj -scheme GamesWithFriends -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build 2>&1 | tail -2
APP=$(find GamesWithFriends/build/Build/Products -name "*.app" | head -1)
xcrun simctl install booted "$APP"
BUNDLE_ID=$(defaults read "$(pwd)/$APP/Info" CFBundleIdentifier)
xcrun simctl launch booted "$BUNDLE_ID"
sleep 3
xcrun simctl io booted screenshot <scratchpad>/hub-light.png
```

(Adjust paths if run from repo root; boot the simulator first with `xcrun simctl boot "iPhone 17"` if not booted.)

- [ ] **Step 2: Inspect `hub-light.png` against the Option C artboard**

Check: mustard motif ground with motifs only in gutters/top strip; pink GAMES lockup with tomato offset + hard shadow, tilted; "with friends" lozenge; nine cards in artboard accent order (bubblegum, grass, lilac, poolBlue, tomato, tangerine, berry, cornflower, plum); each card = title lozenge + description panel + illustration plate; alternating tilt; ink outlines everywhere; no soft shadows. Fix and re-run if anything is off.

- [ ] **Step 3: Dark mode check**

```bash
xcrun simctl ui booted appearance dark
xcrun simctl launch booted "$BUNDLE_ID"
sleep 3
xcrun simctl io booted screenshot <scratchpad>/hub-dark.png
xcrun simctl ui booted appearance light
```

**Note:** `GamesWithFriendsApp.swift` currently forces `.preferredColorScheme(.light)`. If dark verification is blocked by that, leave the app-level setting alone (AGENTS.md §8 protected file — do not change without approval) and instead verify dark tokens via the "Retro Showcase" preview reasoning: `ground`/`panel`/`panelText` adaptivity was already validated in phase 1. Record whichever path was taken.

- [ ] **Step 4: Commit any visual fixes**

```bash
git add -A
git commit -m "fix: hub visual polish after simulator verification"
```

(Skip if no fixes were needed.)

---

### Task 5: Documentation + wrap-up

**Files:**
- Modify: `GamesWithFriends/DECISIONS.md` (append entry)
- Modify: `docs/superpowers/plans/2026-08-22-retro-migration-phase-2.md` (check off boxes)

- [ ] **Step 1: Append a DECISIONS.md entry**

Append (matching the existing entry format in the file):

```markdown
## 2026-08-22: Retro migration phase 2 — hub re-skin landed

**Decision:** `GameHubView` migrated to Retro Maximalist. New: `AppTheme.Retro.accent(forGameID:)` (candy accents; `GameTheme` unchanged until phase 3), `RetroSpotIllustrations.swift` (nine Canvas-drawn spots, `RetroSpotKind` mapped from game ids), rewritten hub with `MotifGroundView` + lockup header + shelf cards.

**Deliberate deviations from the Option C artboard:** (1) "Party games for your table" tagline omitted — ART_DIRECTION §11 calls it placeholder copy. (2) Card descriptions sit in cream mini-panels rather than naked on accents — §8 requires it on 6 of 9 accents; uniform treatment keeps the shelf consistent and makes contrast failures structurally impossible. (3) Logo stays 40pt (artboard 44px) for Dynamic Type headroom.

**Gotcha:** hub cards read accents from `AppTheme.Retro.accent(forGameID:)`, NOT `game.accentColor` — do not "simplify" back to GameTheme until phase 3 remaps it.
```

- [ ] **Step 2: Check off all plan checkboxes, run the full suite one final time**

Same test command as Task 3 Step 3. Expected: all pass.

- [ ] **Step 3: Commit**

```bash
git add GamesWithFriends/DECISIONS.md docs/superpowers/plans/2026-08-22-retro-migration-phase-2.md
git commit -m "docs: record phase-2 decisions and completed plan"
```

---

## Self-Review Notes

- **Spec coverage:** §2 rules 1–6 all embodied (outlines, hard shadows, motif ground, framed lettering, lozenges/panels, faces on 7 of 9 spots — burst and film frame carry a star instead, matching the artboard). §3.2 accent map ✓ (hub-local until phase 3). §5 card anatomy ✓. §6 spot illustrations ✓. §7 exclusion zone ✓. §8 body-text-on-panel ✓.
- **Type consistency:** `RetroSpotKind(gameID:)`, `RetroSpotIllustration(kind:)`, `AppTheme.Retro.accent(forGameID:)` used identically across tasks. Game ids verified against source: `conversation-starters`, `country-letter-game`, `name-5-game`, `border-blitz`, `movie-chain`, `casting-director`, `vibecheck`, `border-hop`, `finish-the-line`.
- **Placeholder scan:** clean; every code step carries complete code.
