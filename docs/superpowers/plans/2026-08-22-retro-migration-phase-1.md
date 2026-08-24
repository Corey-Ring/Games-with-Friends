# Retro Maximalist Migration — Phase 1 (Foundations) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the retro design-system foundation — `AppTheme.Retro` tokens, bundled display fonts, the retro card/panel/lozenge modifiers, the raised-button press style, retro button/pill components, and the seeded motif ground — per `GamesWithFriends/ART_DIRECTION.md`, without changing any shipped screen.

**Architecture:** All new code lives in `GamesWithFriends/Theme/` beside the existing theme files, namespaced under `AppTheme.Retro` / `Retro*` so nothing collides with the current system. Fonts are bundled as resources and registered at runtime with CTFontManager (the project uses `GENERATE_INFOPLIST_FILE`, so runtime registration avoids Info.plist plumbing). The motif field is split into a pure, seeded layout generator (unit-testable) and a `Canvas` view that draws it. Nothing in this phase is referenced by shipped screens except the one-line font registration in the app initializer; a `#Preview` showcase is the visual verification surface.

**Tech Stack:** SwiftUI (iOS 17+), XCTest, legacy `project.pbxproj` (manual file registration required — this project does NOT use filesystem-synchronized groups), Shrikhand + Lilita One (Google Fonts, SIL OFL).

**Spec:** `GamesWithFriends/ART_DIRECTION.md` (§3 palette, §4 type, §5 shape, §7 motifs, §8 accessibility, §10 phase 1 scope). Visual reference: Option C artboard on the [Retro Aesthetic Explorer canvas](https://claude.ai/code/artifact/3971b3d8-bb93-4d2e-8d79-bbba81408593).

---

## Roadmap & Delegation Split (all phases)

Established working split for this project: **Fable (main session)** takes design-sensitive and subtle work directly; **Opus subagents** run mechanical, module-grouped sweeps; **agents never run builds** — every build/test/screenshot happens in the main session.

| Phase | Scope | Who | Why |
|---|---|---|---|
| **1. Foundations** (this plan) | `AppTheme.Retro` tokens, fonts, retro modifiers/components, motif ground | **Fable, inline** | Small surface, high leverage, every later phase inherits its judgment calls (press physics, contrast defaults, pbxproj wiring) |
| **2. Hub re-skin** | GameHubView → Option C artboard: logo lockup, candy cards, motif ground, 9 spot illustrations (SwiftUI `Path`/`Canvas`) | **Fable** | Illustration and lockup quality is the make-or-break of the whole direction; not delegable mechanical work |
| **3. Accent remap** | `GameTheme` old→new values (§3.2) in one commit, then a repo-wide sweep for hardcoded old-accent hexes/usages | **Fable** does the 9-line remap; **Opus agents** sweep per feature module for stragglers; Fable builds + reviews | The remap is trivial; the sweep is exactly the module-grouped mechanical work agents are good at |
| **4. Per-game migration** (9 games: setup → in-game → results) | Apply retro components per screen | **Fable** migrates Conversation Starters first and writes `RETRO_MIGRATION_PLAYBOOK.md` from it; **Opus agents** then migrate one game module each, following the playbook; **Fable** personally handles Movie Chain + Casting Director (keyboard-overlay/search screens — the subtle layout work) and reviews every agent diff | First-game-then-playbook keeps agent output convergent; the two search-driven games have the known-hard keyboard layouts |
| **5. Dark mode + accessibility audit** (runs per phase, not at the end) | Contrast checks (§8), Reduce Motion, Dynamic Type with custom fonts, dark-ground variants | **Opus agents** produce module-grouped audit findings (grep/token/contrast passes); **Fable** fixes subtle findings and verifies on-simulator (headless screenshot harness from the 2026-08-04 review), agents fix mechanical ones | Same split as the launch-readiness pass that worked before |

Phase gates: each phase ends with a build + test run and a simulator screenshot review in the main session before the next phase starts.

---

## File Structure (Phase 1)

| File | Responsibility |
|---|---|
| Create `GamesWithFriends/Theme/RetroTheme.swift` | `AppTheme.Retro` namespace: candy palette, adaptive ground/panel colors, shape tokens; `RetroFonts` registrar; `AppTheme.Retro.Typography` |
| Create `GamesWithFriends/Theme/RetroModifiers.swift` | `.retroPanel`, `.retroCard`, `.retroLozenge`, `RetroRaisedButtonStyle` |
| Create `GamesWithFriends/Theme/RetroComponents.swift` | `RetroPrimaryButton`, `RetroCategoryPill`, showcase `#Preview` |
| Create `GamesWithFriends/Theme/MotifField.swift` | `SplitMix64`, `Motif`, `MotifFieldLayout` — pure seeded layout, no SwiftUI import |
| Create `GamesWithFriends/Theme/MotifGroundView.swift` | `Canvas` renderer for the motif field over the retro ground |
| Create `GamesWithFriends/Theme/Fonts/Shrikhand-Regular.ttf`, `LilitaOne-Regular.ttf`, `Shrikhand-OFL.txt`, `LilitaOne-OFL.txt` | Bundled display fonts + licenses |
| Modify `GamesWithFriends/GamesWithFriendsApp.swift` | Add `init()` calling `RetroFonts.registerAll()` — **AGENTS.md §8 flags this file; user approved via this plan** |
| Modify `GamesWithFriends/GamesWithFriends.xcodeproj/project.pbxproj` | Register the 5 Swift files + 2 fonts + 1 test file |
| Create `GamesWithFriendsTests/RetroThemeTests.swift` | Token values, font registration, motif determinism/bounds/exclusions |
| Modify `GamesWithFriends/DECISIONS.md` | Phase 1 entry |

**Working directory for all commands:** `GamesWithFriends/` (the folder containing `GamesWithFriends.xcodeproj`).

**Build command** (AGENTS.md §6.2):
```bash
xcodebuild -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'generic/platform=iOS Simulator' build
```
**Test command** (if `iPhone 15` isn't installed, pick any iOS 17+ device from `xcrun simctl list devices available`):
```bash
xcodebuild -project GamesWithFriends.xcodeproj -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

---

### Task 1: Scaffold files and register them in the Xcode project

The project is a legacy pbxproj — new files must be added by hand in four places (PBXBuildFile, PBXFileReference, a group's `children`, and a target build phase). Do all registration once, up front, with stub files, so later tasks only edit Swift.

**Files:**
- Create: the 5 Swift files + test file as stubs (below)
- Modify: `GamesWithFriends.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create stub Swift files**

Each of `Theme/RetroTheme.swift`, `Theme/RetroModifiers.swift`, `Theme/RetroComponents.swift`, `Theme/MotifGroundView.swift` gets exactly:

```swift
import SwiftUI
```

`Theme/MotifField.swift` gets exactly:

```swift
import CoreGraphics
```

`../GamesWithFriendsTests/RetroThemeTests.swift` (sibling of `SmokeTests.swift`) gets:

```swift
import XCTest
@testable import GamesWithFriends

final class RetroThemeTests: XCTestCase {}
```

Also create the fonts directory: `mkdir -p Theme/Fonts`

- [ ] **Step 2: Verify the new pbxproj IDs are unused**

```bash
grep -c "TH000001000000000000000A\|TF0000010000000000000001\|TT0000010000000000000001" GamesWithFriends.xcodeproj/project.pbxproj
```
Expected: `0`. If nonzero, bump the trailing hex digits until unused and use those consistently below.

- [ ] **Step 3: Add PBXBuildFile entries**

Find the line `TH0000010000000000000002 /* AppTheme.swift in Sources */ = {` (~line 151) and add directly below it:

```
		TH000001000000000000000A /* RetroTheme.swift in Sources */ = {isa = PBXBuildFile; fileRef = TH000002000000000000000A /* RetroTheme.swift */; };
		TH000001000000000000000B /* RetroModifiers.swift in Sources */ = {isa = PBXBuildFile; fileRef = TH000002000000000000000B /* RetroModifiers.swift */; };
		TH000001000000000000000C /* RetroComponents.swift in Sources */ = {isa = PBXBuildFile; fileRef = TH000002000000000000000C /* RetroComponents.swift */; };
		TH000001000000000000000D /* MotifField.swift in Sources */ = {isa = PBXBuildFile; fileRef = TH000002000000000000000D /* MotifField.swift */; };
		TH000001000000000000000E /* MotifGroundView.swift in Sources */ = {isa = PBXBuildFile; fileRef = TH000002000000000000000E /* MotifGroundView.swift */; };
		TF0000010000000000000001 /* Shrikhand-Regular.ttf in Resources */ = {isa = PBXBuildFile; fileRef = TF0000020000000000000001 /* Shrikhand-Regular.ttf */; };
		TF0000010000000000000002 /* LilitaOne-Regular.ttf in Resources */ = {isa = PBXBuildFile; fileRef = TF0000020000000000000002 /* LilitaOne-Regular.ttf */; };
		TT0000010000000000000001 /* RetroThemeTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = TT0000020000000000000001 /* RetroThemeTests.swift */; };
```

- [ ] **Step 4: Add PBXFileReference entries**

Find `TH0000020000000000000002 /* AppTheme.swift */ = {` (~line 328) and add directly below it:

```
		TH000002000000000000000A /* RetroTheme.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RetroTheme.swift; sourceTree = "<group>"; };
		TH000002000000000000000B /* RetroModifiers.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RetroModifiers.swift; sourceTree = "<group>"; };
		TH000002000000000000000C /* RetroComponents.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = RetroComponents.swift; sourceTree = "<group>"; };
		TH000002000000000000000D /* MotifField.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MotifField.swift; sourceTree = "<group>"; };
		TH000002000000000000000E /* MotifGroundView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MotifGroundView.swift; sourceTree = "<group>"; };
		TF0000020000000000000001 /* Shrikhand-Regular.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; path = "Shrikhand-Regular.ttf"; sourceTree = "<group>"; };
		TF0000020000000000000002 /* LilitaOne-Regular.ttf */ = {isa = PBXFileReference; lastKnownFileType = file; path = "LilitaOne-Regular.ttf"; sourceTree = "<group>"; };
		TT0000020000000000000001 /* RetroThemeTests.swift */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; name = RetroThemeTests.swift; path = ../../GamesWithFriendsTests/RetroThemeTests.swift; sourceTree = "<group>"; };
```

(The test-file `name`/`path` shape copies the existing `SmokeTests.swift` reference exactly.)

- [ ] **Step 5: Add the Fonts group and extend the Theme group**

Find `TH0000030000000000000001 /* Theme */ = {` (~line 1017). Inside its `children = (...)` list, add after the `ViewModifiers.swift` line:

```
				TH000002000000000000000A /* RetroTheme.swift */,
				TH000002000000000000000B /* RetroModifiers.swift */,
				TH000002000000000000000C /* RetroComponents.swift */,
				TH000002000000000000000D /* MotifField.swift */,
				TH000002000000000000000E /* MotifGroundView.swift */,
				TF0000030000000000000001 /* Fonts */,
```

Then, immediately after that whole Theme group block's closing `};`, add a new group:

```
		TF0000030000000000000001 /* Fonts */ = {
			isa = PBXGroup;
			children = (
				TF0000020000000000000001 /* Shrikhand-Regular.ttf */,
				TF0000020000000000000002 /* LilitaOne-Regular.ttf */,
			);
			path = Fonts;
			sourceTree = "<group>";
		};
```

Finally, find the group whose `children` list contains `0CC84603689E26C6A2B560E2 /* SmokeTests.swift */,` and add below that line:

```
				TT0000020000000000000001 /* RetroThemeTests.swift */,
```

- [ ] **Step 6: Add build-phase entries**

App **Sources** phase — find `TH0000010000000000000002 /* AppTheme.swift in Sources */,` (~line 1323) and add below it:

```
				TH000001000000000000000A /* RetroTheme.swift in Sources */,
				TH000001000000000000000B /* RetroModifiers.swift in Sources */,
				TH000001000000000000000C /* RetroComponents.swift in Sources */,
				TH000001000000000000000D /* MotifField.swift in Sources */,
				TH000001000000000000000E /* MotifGroundView.swift in Sources */,
```

App **Resources** phase — find `F10000010000000000000080 /* Assets.xcassets in Resources */,` (~line 1182) and add below it:

```
				TF0000010000000000000001 /* Shrikhand-Regular.ttf in Resources */,
				TF0000010000000000000002 /* LilitaOne-Regular.ttf in Resources */,
```

Test target **Sources** phase — find `C50C046FE5CA1CE43FE9F2CD /* SmokeTests.swift in Sources */,` (~line 1195) and add below it:

```
				TT0000010000000000000001 /* RetroThemeTests.swift in Sources */,
```

- [ ] **Step 7: Build to prove the project file still parses**

Run the build command. Expected: `BUILD SUCCEEDED`. (Fonts aren't on disk yet — file references without files only fail Resources *copying* at the point the file is missing; if the build fails with "Build input file cannot be found" for the .ttf files, create empty placeholders `touch Theme/Fonts/Shrikhand-Regular.ttf Theme/Fonts/LilitaOne-Regular.ttf` and rebuild; Task 3 replaces them.)

- [ ] **Step 8: Commit**

```bash
git add -A && git commit -m "feat(retro): scaffold phase-1 theme files and register in project"
```

---

### Task 2: Retro color and shape tokens (TDD)

**Files:**
- Modify: `Theme/RetroTheme.swift`
- Test: `../GamesWithFriendsTests/RetroThemeTests.swift`

- [ ] **Step 1: Write the failing tests**

Replace the body of `RetroThemeTests` with:

```swift
final class RetroThemeTests: XCTestCase {

    private func assertSameColor(_ color: Color, hex: String,
                                 file: StaticString = #filePath, line: UInt = #line) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var er: CGFloat = 0, eg: CGFloat = 0, eb: CGFloat = 0, ea: CGFloat = 0
        XCTAssertTrue(UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a), file: file, line: line)
        XCTAssertTrue(UIColor(Color(hex: hex)).getRed(&er, green: &eg, blue: &eb, alpha: &ea), file: file, line: line)
        XCTAssertEqual(r, er, accuracy: 0.005, "red of \(hex)", file: file, line: line)
        XCTAssertEqual(g, eg, accuracy: 0.005, "green of \(hex)", file: file, line: line)
        XCTAssertEqual(b, eb, accuracy: 0.005, "blue of \(hex)", file: file, line: line)
    }

    func testCandyPaletteMatchesArtDirection() {
        assertSameColor(AppTheme.Retro.mustard, hex: "F2B417")
        assertSameColor(AppTheme.Retro.cream, hex: "FBF2E0")
        assertSameColor(AppTheme.Retro.ink, hex: "1B1B1B")
        assertSameColor(AppTheme.Retro.cocoa, hex: "55351D")
        assertSameColor(AppTheme.Retro.bubblegum, hex: "F387B8")
        assertSameColor(AppTheme.Retro.tomato, hex: "E8442E")
        assertSameColor(AppTheme.Retro.tangerine, hex: "F07C24")
        assertSameColor(AppTheme.Retro.cornflower, hex: "6C9BD2")
        assertSameColor(AppTheme.Retro.poolBlue, hex: "5BC0DF")
        assertSameColor(AppTheme.Retro.grass, hex: "57A34F")
        assertSameColor(AppTheme.Retro.lilac, hex: "A08BE0")
        assertSameColor(AppTheme.Retro.berry, hex: "C64B7E")
        assertSameColor(AppTheme.Retro.plum, hex: "8E4585")
    }

    func testShapeTokens() {
        XCTAssertEqual(AppTheme.Retro.strokeWidth, 2.5)
        XCTAssertEqual(AppTheme.Retro.strokeHeavy, 3)
        XCTAssertEqual(AppTheme.Retro.Radius.card, 18)
        XCTAssertEqual(AppTheme.Retro.shadowOffset, 5)
        XCTAssertEqual(AppTheme.Retro.shadowPressedOffset, 2)
        XCTAssertEqual(AppTheme.Retro.pressTravel, 3)
    }
}
```

Add `import SwiftUI` under the existing imports of the test file.

- [ ] **Step 2: Run tests to verify they fail**

Run the test command. Expected: FAIL — `type 'AppTheme' has no member 'Retro'` (compile error counts as the failing state).

- [ ] **Step 3: Implement the tokens**

Replace `Theme/RetroTheme.swift` with:

```swift
import SwiftUI
import UIKit

// ART_DIRECTION.md §3 (color), §5 (shape). Phase-1 foundation; no shipped
// screen references these until its migration phase lands.
extension AppTheme {
    enum Retro {
        // MARK: - Candy palette (§3.1)
        static let mustard = Color(hex: "F2B417")
        static let cream = Color(hex: "FBF2E0")
        static let ink = Color(hex: "1B1B1B")
        static let cocoa = Color(hex: "55351D")
        static let bubblegum = Color(hex: "F387B8")
        static let tomato = Color(hex: "E8442E")
        static let tangerine = Color(hex: "F07C24")
        static let cornflower = Color(hex: "6C9BD2")
        static let poolBlue = Color(hex: "5BC0DF")
        static let grass = Color(hex: "57A34F")
        static let lilac = Color(hex: "A08BE0")
        static let berry = Color(hex: "C64B7E")
        static let plum = Color(hex: "8E4585")

        // MARK: - Dark mode "shop at night" (§3.3)
        static let darkGround = Color(hex: "2A1A10")
        static let darkPanel = Color(hex: "3A2A1C")

        // MARK: - Adaptive surfaces (same dynamic-provider pattern as AppTheme.cardSurface)
        /// Page ground: mustard by day, deep cocoa at night.
        static let ground = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(darkGround) : UIColor(mustard)
        })
        /// Panel/lozenge fill: cream by day, dark cocoa panel at night.
        static let panel = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(darkPanel) : UIColor(cream)
        })
        /// Text on `panel`: ink by day, cream at night.
        static let panelText = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(cream) : UIColor(ink)
        })

        // MARK: - Shape language (§5)
        static let strokeWidth: CGFloat = 2.5
        static let strokeHeavy: CGFloat = 3
        struct Radius {
            static let card: CGFloat = 18
            static let inner: CGFloat = 12
        }
        static let shadowOffset: CGFloat = 5
        static let shadowPressedOffset: CGFloat = 2
        static let pressTravel: CGFloat = 3
        /// Max rotation jitter for cards/lockups, in degrees (§5).
        static let maxCardTilt: Double = 1.5
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run the test command. Expected: `testCandyPaletteMatchesArtDirection` and `testShapeTokens` PASS.

- [ ] **Step 5: Commit**

```bash
git add Theme/RetroTheme.swift ../GamesWithFriendsTests/RetroThemeTests.swift
git commit -m "feat(retro): AppTheme.Retro color and shape tokens"
```

---

### Task 3: Bundle and register the display fonts

> ⚠️ **Requires a file download** (needs user approval at execution time if not pre-approved): two .ttf files + two OFL.txt license files from the official `google/fonts` GitHub repository, ~80–400 KB each, SIL Open Font License.

**Files:**
- Create: `Theme/Fonts/Shrikhand-Regular.ttf`, `Theme/Fonts/LilitaOne-Regular.ttf`, `Theme/Fonts/Shrikhand-OFL.txt`, `Theme/Fonts/LilitaOne-OFL.txt`
- Modify: `Theme/RetroTheme.swift`, `GamesWithFriendsApp.swift`
- Test: `../GamesWithFriendsTests/RetroThemeTests.swift`

- [ ] **Step 1: Write the failing test**

Add to `RetroThemeTests`:

```swift
    func testDisplayFontsRegister() {
        RetroFonts.registerAll()
        XCTAssertNotNil(UIFont(name: "Shrikhand-Regular", size: 20),
                        "Shrikhand not registered — check bundle resource + PostScript name")
        XCTAssertNotNil(UIFont(name: "LilitaOne", size: 20),
                        "Lilita One not registered — check bundle resource + PostScript name")
    }
```

- [ ] **Step 2: Run tests to verify it fails**

Run the test command. Expected: FAIL — `cannot find 'RetroFonts' in scope`.

- [ ] **Step 3: Download the fonts (with licenses)**

```bash
curl -fL -o Theme/Fonts/Shrikhand-Regular.ttf "https://github.com/google/fonts/raw/main/ofl/shrikhand/Shrikhand-Regular.ttf"
curl -fL -o Theme/Fonts/LilitaOne-Regular.ttf "https://github.com/google/fonts/raw/main/ofl/lilitaone/LilitaOne-Regular.ttf"
curl -fL -o Theme/Fonts/Shrikhand-OFL.txt "https://github.com/google/fonts/raw/main/ofl/shrikhand/OFL.txt"
curl -fL -o Theme/Fonts/LilitaOne-OFL.txt "https://github.com/google/fonts/raw/main/ofl/lilitaone/OFL.txt"
```

Verify both .ttf files are real fonts (not error pages): `file Theme/Fonts/*.ttf` → both report `TrueType Font data`.

- [ ] **Step 4: Add the registrar and typography API**

Add `import CoreText` under the existing imports at the top of `Theme/RetroTheme.swift`, then append to the file:

```swift
// MARK: - Font registration (runtime; project uses GENERATE_INFOPLIST_FILE,
// so CTFontManager registration replaces UIAppFonts plumbing)
enum RetroFonts {
    private final class BundleToken {}
    private static var registered = false

    /// Idempotent. Call once from the app initializer (and from tests).
    static func registerAll() {
        guard !registered else { return }
        registered = true
        for resource in ["Shrikhand-Regular", "LilitaOne-Regular"] {
            guard let url = Bundle(for: BundleToken.self).url(forResource: resource, withExtension: "ttf") else {
                assertionFailure("Missing bundled font \(resource).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

// MARK: - Retro typography (§4). Display faces scale with Dynamic Type
// via relativeTo; SF Pro (AppTheme.Typography) remains the body face.
extension AppTheme.Retro {
    struct Typography {
        /// Shrikhand — logo lockups ONLY (§4), never body or labels.
        static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .largeTitle) -> Font {
            .custom("Shrikhand-Regular", size: size, relativeTo: style)
        }
        /// Lilita One — headings, card titles, buttons, pills.
        static func heading(_ size: CGFloat, relativeTo style: Font.TextStyle = .headline) -> Font {
            .custom("LilitaOne", size: size, relativeTo: style)
        }

        static let logo = display(40)
        static let screenTitle = heading(28, relativeTo: .title)
        static let cardTitle = heading(17, relativeTo: .headline)
        static let pillLabel = heading(14, relativeTo: .subheadline)
    }
}
```

- [ ] **Step 5: Register at app launch**

In `GamesWithFriendsApp.swift`, add an initializer to the `GamesWithFriendsApp` struct, directly above `var body: some Scene {`:

```swift
    init() {
        RetroFonts.registerAll()
    }
```

(This is the only app-level-config touch in this plan; AGENTS.md §8 requires it be called out — it was approved with this plan.)

- [ ] **Step 6: Run tests to verify they pass**

Run the test command. Expected: `testDisplayFontsRegister` PASS. If a font name assertion fails, print the truth and fix the string: add `print(UIFont.familyNames.filter { $0.contains("Shrik") || $0.contains("Lilita") })` temporarily in the test, use the reported PostScript name in both `Typography` and the test, then remove the print.

- [ ] **Step 7: Commit**

```bash
git add Theme/Fonts Theme/RetroTheme.swift GamesWithFriendsApp.swift ../GamesWithFriendsTests/RetroThemeTests.swift
git commit -m "feat(retro): bundle Shrikhand + Lilita One with runtime registration and retro typography"
```

---

### Task 4: Motif field layout engine (TDD)

Pure, seeded, no SwiftUI — this is the testable half of the motif ground (§7: ~1 motif per 90×90 pt cell, sizes 4–18, exclusion zones with 12 pt clearance).

**Files:**
- Modify: `Theme/MotifField.swift`
- Test: `../GamesWithFriendsTests/RetroThemeTests.swift`

- [ ] **Step 1: Write the failing tests**

Add to `RetroThemeTests`:

```swift
    func testMotifFieldIsDeterministicPerSeed() {
        let size = CGSize(width: 390, height: 844)
        let a = MotifFieldLayout.generate(seed: 42, size: size)
        let b = MotifFieldLayout.generate(seed: 42, size: size)
        let c = MotifFieldLayout.generate(seed: 43, size: size)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertFalse(a.isEmpty)
    }

    func testMotifFieldStaysInBoundsAndInSpec() {
        let size = CGSize(width: 390, height: 844)
        let motifs = MotifFieldLayout.generate(seed: 7, size: size)
        for m in motifs {
            XCTAssertTrue(m.position.x >= 0 && m.position.x <= size.width)
            XCTAssertTrue(m.position.y >= 0 && m.position.y <= size.height)
            XCTAssertTrue((4...18).contains(m.size), "motif sizes are 4–18pt per §7")
        }
        // ~1 per 90×90 cell: 5 cols × 10 rows = 50 cells at density 1
        XCTAssertEqual(motifs.count, 50)
    }

    func testMotifFieldRespectsExclusionsWithClearance() {
        let size = CGSize(width: 390, height: 844)
        let exclusion = CGRect(x: 50, y: 100, width: 290, height: 200)
        let motifs = MotifFieldLayout.generate(seed: 7, size: size, avoiding: [exclusion])
        let padded = exclusion.insetBy(dx: -12, dy: -12)
        XCTAssertFalse(motifs.isEmpty)
        for m in motifs {
            XCTAssertFalse(padded.contains(m.position),
                           "motif at \(m.position) is inside an exclusion zone (+12pt clearance)")
        }
    }

    func testMotifFieldDensityScalesCount() {
        let size = CGSize(width: 390, height: 844)
        let full = MotifFieldLayout.generate(seed: 7, size: size, density: 1.0)
        let sparse = MotifFieldLayout.generate(seed: 7, size: size, density: 0.6)
        XCTAssertLessThan(sparse.count, full.count)
        XCTAssertGreaterThan(sparse.count, 0)
    }
```

- [ ] **Step 2: Run tests to verify they fail**

Run the test command. Expected: FAIL — `cannot find 'MotifFieldLayout' in scope`.

- [ ] **Step 3: Implement the layout engine**

Replace `Theme/MotifField.swift` with:

```swift
import CoreGraphics

/// Deterministic seedable RNG (SplitMix64). Seeded per screen so the motif
/// ground is stable across renders — ART_DIRECTION.md §7 "seeded-random with
/// a fixed seed, never visibly gridded".
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

struct Motif: Equatable {
    enum Kind: CaseIterable, Equatable {
        case daisy, sparkle, dot, heart, squiggle
    }
    let kind: Kind
    let position: CGPoint
    /// Diameter in points, 4–18 (§7).
    let size: CGFloat
    /// Index into the rendering palette (renderer wraps with %).
    let colorIndex: Int
    let rotationDegrees: Double
}

/// Pure layout generator for the motif ground (§7): one candidate motif per
/// 90×90pt cell, jittered inside its cell, skipping exclusion rects padded by
/// 12pt clearance. Rendering lives in MotifGroundView.
enum MotifFieldLayout {
    static let cellSide: CGFloat = 90
    static let clearance: CGFloat = 12
    static let sizeRange: ClosedRange<CGFloat> = 4...18
    static let paletteSlots = 4

    static func generate(seed: UInt64,
                         size: CGSize,
                         density: CGFloat = 1.0,
                         avoiding exclusions: [CGRect] = []) -> [Motif] {
        guard size.width > 0, size.height > 0, density > 0 else { return [] }
        var rng = SplitMix64(seed: seed)
        let cols = max(1, Int((size.width / cellSide).rounded(.up)))
        let rows = max(1, Int((size.height / cellSide).rounded(.up)))
        let padded = exclusions.map { $0.insetBy(dx: -clearance, dy: -clearance) }
        var motifs: [Motif] = []

        for row in 0..<rows {
            for col in 0..<cols {
                // Draw every random even for skipped cells so density changes
                // don't reshuffle the surviving motifs' appearance.
                let roll = CGFloat.random(in: 0..<1, using: &rng)
                let x = min(size.width, CGFloat(col) * cellSide + CGFloat.random(in: 0...cellSide, using: &rng))
                let y = min(size.height, CGFloat(row) * cellSide + CGFloat.random(in: 0...cellSide, using: &rng))
                let kind = Motif.Kind.allCases.randomElement(using: &rng) ?? .dot
                let motifSize = CGFloat.random(in: sizeRange, using: &rng)
                let colorIndex = Int.random(in: 0..<paletteSlots, using: &rng)
                let rotation = Double.random(in: -20...20, using: &rng)

                if roll >= density { continue }
                let point = CGPoint(x: x, y: y)
                if padded.contains(where: { $0.contains(point) }) { continue }
                motifs.append(Motif(kind: kind, position: point, size: motifSize,
                                    colorIndex: colorIndex, rotationDegrees: rotation))
            }
        }
        return motifs
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run the test command. Expected: all four motif tests PASS. Note `testMotifFieldStaysInBoundsAndInSpec` asserts exactly 50 for a 390×844 field — if it reports a different count, the ceil math changed; fix the code, not the test, unless the count is provably right (5×10 cells, density 1, no exclusions).

- [ ] **Step 5: Commit**

```bash
git add Theme/MotifField.swift ../GamesWithFriendsTests/RetroThemeTests.swift
git commit -m "feat(retro): seeded motif field layout engine"
```

---

### Task 5: Motif ground view

Rendering half — a `Canvas` that draws the five motif kinds over the adaptive ground. Decorative: hidden from accessibility, not hit-testable, static (no animation in phase 1; the optional twinkle from §7 is deferred — YAGNI).

**Files:**
- Modify: `Theme/MotifGroundView.swift`

- [ ] **Step 1: Implement the view**

Replace `Theme/MotifGroundView.swift` with:

```swift
import SwiftUI

/// Populated retro page ground (ART_DIRECTION.md §3.1, §7).
/// Decorative only: accessibility-hidden, never hit-testable, static.
/// Pass `exclusions` (in this view's coordinate space) for regions that must
/// stay motif-free (§7: none within 12pt of interactive areas — the layout
/// engine adds the clearance).
struct MotifGroundView: View {
    var seed: UInt64 = 0xCAFE_D00D
    var density: CGFloat = 1.0
    var exclusions: [CGRect] = []
    var palette: [Color] = [
        AppTheme.Retro.cream,
        AppTheme.Retro.bubblegum,
        AppTheme.Retro.tomato,
        AppTheme.Retro.grass,
    ]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Retro.ground.ignoresSafeArea()
            Canvas { context, size in
                // §3.3: dark mode drops density and uses accents only (no cream).
                let dark = colorScheme == .dark
                let effectiveDensity = dark ? density * 0.6 : density
                let colors = dark ? Array(palette.dropFirst()) : palette
                guard !colors.isEmpty else { return }
                let motifs = MotifFieldLayout.generate(seed: seed, size: size,
                                                       density: effectiveDensity,
                                                       avoiding: exclusions)
                for motif in motifs {
                    draw(motif, in: context, colors: colors)
                }
            }
            .ignoresSafeArea()
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func draw(_ motif: Motif, in context: GraphicsContext, colors: [Color]) {
        var ctx = context
        ctx.translateBy(x: motif.position.x, y: motif.position.y)
        ctx.rotate(by: .degrees(motif.rotationDegrees))
        let s = motif.size
        let color = colors[motif.colorIndex % colors.count]
        let ink = AppTheme.Retro.ink
        let line = max(1.2, s * 0.12)

        switch motif.kind {
        case .dot:
            let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
            ctx.fill(Path(ellipseIn: rect), with: .color(color))
            ctx.stroke(Path(ellipseIn: rect), with: .color(ink), lineWidth: line)

        case .daisy:
            // Six petal ellipses around an ink-outlined center.
            let petal = CGRect(x: -s * 0.16, y: -s * 0.62, width: s * 0.32, height: s * 0.5)
            for i in 0..<6 {
                var petalCtx = ctx
                petalCtx.rotate(by: .degrees(Double(i) * 60))
                petalCtx.fill(Path(ellipseIn: petal), with: .color(color))
                petalCtx.stroke(Path(ellipseIn: petal), with: .color(ink), lineWidth: line)
            }
            let center = CGRect(x: -s * 0.18, y: -s * 0.18, width: s * 0.36, height: s * 0.36)
            ctx.fill(Path(ellipseIn: center), with: .color(AppTheme.Retro.mustard))
            ctx.stroke(Path(ellipseIn: center), with: .color(ink), lineWidth: line)

        case .sparkle:
            // 4-point star: long vertical/horizontal spikes with pinched waist.
            var path = Path()
            let long = s * 0.7, waist = s * 0.16
            path.move(to: CGPoint(x: 0, y: -long))
            path.addLine(to: CGPoint(x: waist, y: -waist))
            path.addLine(to: CGPoint(x: long, y: 0))
            path.addLine(to: CGPoint(x: waist, y: waist))
            path.addLine(to: CGPoint(x: 0, y: long))
            path.addLine(to: CGPoint(x: -waist, y: waist))
            path.addLine(to: CGPoint(x: -long, y: 0))
            path.addLine(to: CGPoint(x: -waist, y: -waist))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
            ctx.stroke(path, with: .color(ink), lineWidth: line)

        case .heart:
            var path = Path()
            let w = s, h = s
            path.move(to: CGPoint(x: 0, y: h * 0.45))
            path.addCurve(to: CGPoint(x: -w * 0.5, y: -h * 0.2),
                          control1: CGPoint(x: -w * 0.55, y: h * 0.15),
                          control2: CGPoint(x: -w * 0.55, y: -h * 0.25))
            path.addArc(center: CGPoint(x: -w * 0.25, y: -h * 0.2), radius: w * 0.25,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addArc(center: CGPoint(x: w * 0.25, y: -h * 0.2), radius: w * 0.25,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addCurve(to: CGPoint(x: 0, y: h * 0.45),
                          control1: CGPoint(x: w * 0.55, y: -h * 0.25),
                          control2: CGPoint(x: w * 0.55, y: h * 0.15))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
            ctx.stroke(path, with: .color(ink), lineWidth: line)

        case .squiggle:
            var path = Path()
            path.move(to: CGPoint(x: -s * 0.8, y: 0))
            path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -s * 0.4, y: -s * 0.6))
            path.addQuadCurve(to: CGPoint(x: s * 0.8, y: 0), control: CGPoint(x: s * 0.4, y: s * 0.6))
            ctx.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: max(2, s * 0.18), lineCap: .round))
        }
    }
}

#Preview("Motif ground") {
    MotifGroundView(exclusions: [CGRect(x: 20, y: 300, width: 350, height: 200)])
}
```

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add Theme/MotifGroundView.swift
git commit -m "feat(retro): motif ground canvas view"
```

---

### Task 6: Retro panel/card/lozenge modifiers and the raised press style

**Files:**
- Modify: `Theme/RetroModifiers.swift`

- [ ] **Step 1: Implement the modifiers**

Replace `Theme/RetroModifiers.swift` with:

```swift
import SwiftUI

// ART_DIRECTION.md §5: ink outlines on everything, flat fills, hard offset
// shadows; press = shadow collapses while the element travels toward it.

// MARK: - Retro Panel (fill + ink outline, no shadow)
struct RetroPanelModifier: ViewModifier {
    var fill: Color
    var cornerRadius: CGFloat = AppTheme.Retro.Radius.card

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
            )
    }
}

// MARK: - Retro Card (padded panel + static hard shadow) — non-interactive
// surfaces. Interactive elements use RetroRaisedButtonStyle instead so the
// shadow can collapse on press.
struct RetroCardModifier: ViewModifier {
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .retroPanel(fill)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                    .fill(AppTheme.Retro.ink)
                    .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
            )
    }
}

// MARK: - Retro Lozenge (capsule pill; §2 rule 5 — text lives in devices)
struct RetroLozengeModifier: ViewModifier {
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
    }
}

// MARK: - Raised press style: hard shadow at 5,5 collapses to 2,2 while the
// element travels +3,+3 — pressing a physical button. Reduce Motion: no
// travel/shadow animation; haptic still fires (it isn't visual motion).
struct RetroRaisedButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = AppTheme.Retro.Radius.card
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !reduceMotion
        let shadow = pressed ? AppTheme.Retro.shadowPressedOffset : AppTheme.Retro.shadowOffset
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Retro.ink)
                    .offset(x: shadow, y: shadow)
            )
            .offset(x: pressed ? AppTheme.Retro.pressTravel : 0,
                    y: pressed ? AppTheme.Retro.pressTravel : 0)
            .animation(reduceMotion ? nil : AppTheme.Animation.cardTap, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

extension View {
    func retroPanel(_ fill: Color = AppTheme.Retro.panel,
                    cornerRadius: CGFloat = AppTheme.Retro.Radius.card) -> some View {
        modifier(RetroPanelModifier(fill: fill, cornerRadius: cornerRadius))
    }

    func retroCard(_ fill: Color = AppTheme.Retro.panel) -> some View {
        modifier(RetroCardModifier(fill: fill))
    }

    func retroLozenge(_ fill: Color = AppTheme.Retro.panel) -> some View {
        modifier(RetroLozengeModifier(fill: fill))
    }
}
```

Add `import UIKit` under `import SwiftUI` (for `UIImpactFeedbackGenerator`, mirroring `ViewModifiers.swift`, which gets it transitively — be explicit here).

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add Theme/RetroModifiers.swift
git commit -m "feat(retro): panel/card/lozenge modifiers and raised press style"
```

---

### Task 7: Retro components + showcase preview

**Files:**
- Modify: `Theme/RetroComponents.swift`

- [ ] **Step 1: Implement the components**

Replace `Theme/RetroComponents.swift` with:

```swift
import SwiftUI

// MARK: - Retro Primary Button (ART_DIRECTION §5; contrast rules §8)
/// Accent-filled CTA with ink text. §8: ink passes on mustard, bubblegum,
/// poolBlue, cream, tangerine. On plum pass `textColor: AppTheme.Retro.cream`
/// (the one accent dark enough for cream body text); on tomato/grass/lilac/
/// cornflower/berry keep ink text — cream is display-only there.
struct RetroPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var accent: Color = AppTheme.Retro.tangerine
    var textColor: Color = AppTheme.Retro.ink
    let action: () -> Void
    @ScaledMetric(relativeTo: .headline) private var buttonHeight: CGFloat = 52

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(AppTheme.Retro.Typography.heading(17))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: buttonHeight)
            .retroPanel(accent)
        }
        .buttonStyle(RetroRaisedButtonStyle())
    }
}

// MARK: - Retro Category Pill (replaces CategoryPill on migrated screens)
struct RetroCategoryPill: View {
    let title: String
    var icon: String? = nil
    let color: Color
    let isSelected: Bool
    /// §8: default ink works on light accents; pass cream for plum selection.
    var selectedTextColor: Color = AppTheme.Retro.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
            }
            .font(AppTheme.Retro.Typography.pillLabel)
            .foregroundColor(isSelected ? selectedTextColor : AppTheme.Retro.panelText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Capsule().fill(isSelected ? color : AppTheme.Retro.panel))
            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
    }
}

// MARK: - Showcase (visual verification surface for phase 1; not shipped in
// any navigation — reachable only via Xcode Previews)
#Preview("Retro Showcase") {
    ZStack {
        MotifGroundView(exclusions: [CGRect(x: 16, y: 80, width: 358, height: 620)])
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text("GAMES")
                    .font(AppTheme.Retro.Typography.logo)
                    .foregroundColor(.white)
                    .shadow(color: AppTheme.Retro.tomato, radius: 0, x: 3, y: 3)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .retroPanel(AppTheme.Retro.bubblegum)
                    .rotationEffect(.degrees(-1.5))

                Text("with friends")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.tomato)
                    .retroLozenge()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Card title")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)
                    Text("Body copy stays SF Pro on a cream panel — ink on cream is always safe (§8).")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Retro.panelText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .retroCard()

                RetroPrimaryButton(title: "Start Game", icon: "play.fill") {}

                HStack(spacing: AppTheme.Spacing.sm) {
                    RetroCategoryPill(title: "All", color: AppTheme.Retro.grass, isSelected: true) {}
                    RetroCategoryPill(title: "Party", color: AppTheme.Retro.grass, isSelected: false) {}
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }
}
```

- [ ] **Step 2: Build**

Run the build command. Expected: `BUILD SUCCEEDED`.

- [ ] **Step 3: Commit**

```bash
git add Theme/RetroComponents.swift
git commit -m "feat(retro): RetroPrimaryButton, RetroCategoryPill, showcase preview"
```

---

### Task 8: Full verification + decision log

**Files:**
- Modify: `GamesWithFriends/DECISIONS.md`

- [ ] **Step 1: Run the whole test suite**

Run the test command. Expected: all tests PASS, including every pre-existing test (nothing in this phase touches shipped screens, so any old-test regression means a mistake — investigate before proceeding).

- [ ] **Step 2: Visual smoke check (main session only)**

Open the `Retro Showcase` preview in Xcode, or build to a simulator and screenshot. Check against the Option C artboard: ink outlines everywhere, hard un-blurred shadows, Shrikhand renders (not a serif fallback — a serif "GAMES" means font registration failed), press physics on the button, motifs absent inside the exclusion rect.

- [ ] **Step 3: Add the DECISIONS.md entry**

Add above the previous newest entry:

```markdown
## 2026-XX-XX — Retro phase 1: foundations landed [migration]

**What:** `AppTheme.Retro` tokens, bundled Shrikhand/Lilita One (runtime CTFontManager registration — project uses GENERATE_INFOPLIST_FILE, so no UIAppFonts plist), `.retroPanel/.retroCard/.retroLozenge`, `RetroRaisedButtonStyle` (shadow collapse + travel press physics), `MotifFieldLayout` (pure, seeded, tested) + `MotifGroundView`. No shipped screen changed; visual surface is the "Retro Showcase" preview.

**Why:** ART_DIRECTION.md §10 phase 1. Runtime font registration chosen over Info.plist keys for determinism with the generated plist.

**Impact:** Phase 2 (hub) builds only on these primitives — do not hand-roll outlines/shadows in views. `RetroFonts.registerAll()` is called from the app init and is idempotent; tests call it directly. Motif grounds take `exclusions` rects for interactive areas.
```

(Fill in the real date at execution time.)

- [ ] **Step 4: Commit**

```bash
git add DECISIONS.md
git commit -m "docs: record retro phase-1 foundations decision"
```

---

## Verification Summary

- Unit: token values (§3.1), shape tokens (§5), font registration (§4), motif determinism/bounds/size-range/exclusion-clearance/density (§7)
- Build: after every task
- Visual: `Retro Showcase` preview vs the Option C artboard (main session, never delegated)
- Regression: full pre-existing suite in Task 8
