# AGENTS.md — Games With Friends

> **This file is the shared source of truth** for AI coding assistants working in this repo (Claude Code, Cursor, Aider, etc.). `CLAUDE.md` intentionally points at this file so the two cannot drift.
>
> Read this file start-to-finish before writing any code. Then skim the linked docs as needed.

---

## 1. Project at a glance

**What it is:** `GamesWithFriends` — a native iOS app that bundles a growing collection of party / road-trip games behind a single "Game Hub". Built by Corey Ring as a personal product.

**Stack:**
- **Platform:** iOS 17.0+ (Swift 5.9+, Xcode 15+)
- **UI:** SwiftUI exclusively — no UIKit view controllers
- **State:** MVVM with `@Observable` macro (iOS 17 Observation framework) — **not** `ObservableObject`/`@Published` unless you're explicitly maintaining an older view model
- **Persistence:** SwiftData (`@Model`) — **not** Core Data, **not** `UserDefaults` for anything non-trivial
- **Dependencies:** Zero external Swift packages. Everything is built-in (SwiftUI, SwiftData, Foundation, MapKit where relevant). Do not add SPM dependencies without asking first.
- **Bundle ID:** `com.coreyring.GamesWithFriends`
- **Target:** single iOS target `GamesWithFriends`

**Shipped / in-progress games** (all registered in `Features/GameHub/GameRegistry.swift`):
License Plate Game, Conversation Starters, Country Letter Game, Name 5, Border Blitz, Movie Chain, Casting Director, Vibe Check, Border Hop.

---

## 2. Repository layout

```
GamesWithFriends/
├── GamesWithFriendsApp.swift        # @main entry point
├── Core/                            # (reserved for cross-cutting protocols/utilities)
├── Theme/                           # AppTheme, GameTheme, shared modifiers & components
│   ├── AppTheme.swift               # ALL design tokens (colors, spacing, radius, type, animation)
│   ├── GameTheme.swift              # per-game accent color definitions
│   ├── SharedComponents.swift       # PrimaryButton, SecondaryButton, CategoryPill, GameSpinner…
│   ├── ViewModifiers.swift          # .gameCard(), .pressable(), .staggeredAppear(), etc.
│   ├── BackgroundStyles.swift       # WarmLinenBackground, GameBackground
│   ├── HapticManager.swift          # HapticManager.success/error/light/medium/heavy/selection
│   ├── SkeletonLoading.swift        # .skeletonLoading() shimmer modifier
│   ├── AnimatedScoreText.swift
│   └── Color+Hex.swift
├── Features/
│   ├── GameHub/
│   │   ├── GameDefinition.swift     # protocol + AnyGameDefinition wrapper
│   │   ├── GameRegistry.swift       # THE list of all games — register new games here
│   │   └── GameHubView.swift        # home screen
│   └── <GameName>/
│       ├── <GameName>Game.swift     # conforms to GameDefinition
│       ├── Models/
│       ├── ViewModels/
│       ├── Views/
│       ├── Components/              # (optional) game-specific subviews
│       ├── Data/                    # (optional) seed data, geojson, etc.
│       └── Resources/               # (optional) JSON, images
├── Assets.xcassets/
├── Map Images/                      # bundled images used by geography games
├── Country Map Download/             # scratch / source data
└── GamesWithFriends.xcodeproj
```

**Rule of thumb:** anything visual or reusable across games lives in `Theme/`. Anything specific to one game lives under `Features/<GameName>/`. Nothing in `Features/<GameName>/` should import or reach into another game's folder.

---

## 3. Architectural patterns (the ones that matter)

### 3.1 The `GameDefinition` protocol

Every game is a value type (usually `struct`) conforming to `GameDefinition`:

```swift
protocol GameDefinition {
    var id: String { get }
    var name: String { get }
    var description: String { get }
    var iconName: String { get }        // SF Symbol name
    var accentColor: Color { get }      // from GameTheme.*.accentColor
    func makeRootView() -> AnyView
}
```

`AnyGameDefinition` is the type-erased wrapper used in collections (`GameRegistry.allGames()` returns `[AnyGameDefinition]`).

**When you add a new game, you MUST:**
1. Create `Features/<GameName>/<GameName>Game.swift` with a `struct <GameName>Game: GameDefinition`.
2. Add a new accent color assignment in `GameTheme.swift` (pick from the palette in `DESIGN_GUIDE.md` §2.2 or ask).
3. **Register it in `GameRegistry.allGames()`** — this is the single most-forgotten step. If it's not in the registry, it doesn't appear in the hub.
4. Follow the folder convention: `Models/`, `ViewModels/`, `Views/`, plus `Components/`, `Data/`, `Resources/` as needed.

### 3.2 MVVM with `@Observable`

View models use the Observation framework:

```swift
@Observable
final class ExampleViewModel {
    var score: Int = 0
    var isPlaying: Bool = false
    // no @Published, no ObservableObject
}
```

Views hold view models with `@State` (owned by the view) or `@Bindable` / passed in from a parent.

### 3.3 SwiftData persistence

Models use `@Model`. The `ModelContainer` is set up in `GamesWithFriendsApp.swift` (or a per-game container where isolation matters). For any new persisted type:
- Prefer adding the schema to the existing container where possible.
- Keep migrations in mind — if you change a `@Model`, document it in `DECISIONS.md` with a one-liner about backward compatibility.

### 3.4 Theme system

**Never hardcode colors, spacing, radii, typography, or shadows in a game view.** Always reach through `AppTheme.*` or `GameTheme.<game>.*`. Full rules live in `DESIGN_GUIDE.md`; the short version is in §5 below.

---

## 4. Required reading (linked docs)

These files already exist and are considered authoritative for their domain. Do not duplicate their content here — read them directly when the topic comes up.

| Doc | When to read |
|---|---|
| `DESIGN_GUIDE.md` | **Before any UI work.** Colors, typography, spacing, components, animation, dark mode, accessibility, keyboard behavior, SwiftUI pitfalls. This is the UI bible. |
| `README.md` | Quick project overview for humans. |
| `LICENSE_PLATE_GAME_README.md` | Deep dive on the first shipped game's data model + features. Useful as a reference implementation when building new games. |
| `IMPLEMENTATION_SUMMARY.md` | Historical implementation notes for License Plate Game. |
| `QUICK_START.md` | How to get the project building locally. |
| `BUILD_CHECKLIST.md` | License-Plate-specific QA checklist. Template to copy when shipping a new game. |
| `BorderHop_PRD.docx` / `BorderHop_DesignHandoff.docx` / `BorderHop_ImplementationPlan.docx` | Active spec for the Border Hop game. Read before touching `Features/BorderHop/`. |
| `AUDIT_SUMMARY.txt` | Rolling audit notes. Check before a release. |
| `DECISIONS.md` | Running log of architectural decisions and gotchas. **Append here** when you make a non-obvious choice so the next session inherits the context. |

---

## 5. Coding conventions — the non-negotiable rules

Most of these are enforced (or at least strongly implied) by `DESIGN_GUIDE.md`. Listed here so the agent sees them before diving in.

### 5.1 UI / Theme

1. **Never** use raw `Color.blue` / `.red` / `.green` / etc. Use `AppTheme.*` (semantic: success, error, warning, medalGold…) or `GameTheme.<game>.accentColor`.
2. **Never** hardcode spacing numbers in game views. Use `AppTheme.Spacing.xs/sm/md/lg/xl/xxl`. Intermediate values are allowed only inside shared components in `Theme/`.
3. **Never** hardcode `cornerRadius(12)` etc. Use `AppTheme.Radius.small/medium/card/large`.
4. **Never** use raw `.font(.title)` / `.font(.headline)`. Use `AppTheme.Typography.*`. The only exception is `.font(.system(size:))` for decorative display elements ≥ 36pt (hero icons, big score numbers).
5. **Never** use `ProgressView()` for loading. Use `.skeletonLoading()` for content-shaped placeholders, or `GameSpinner(color: <accent>)` when there's no content shape.
6. **Always** use shared components: `PrimaryButton`, `SecondaryButton`, `CategoryPill`, `HubGameCard`, `GameSpinner`. Don't reimplement buttons or pills locally.
7. **Always** use `.gameCard()` for card containers and `.pressable()` for tappable elements (includes haptic).
8. **Always** support dark mode via `@Environment(\.colorScheme)` — use `GameTheme.<game>.darkAccent` on dark backgrounds.
9. **Always** respect `@Environment(\.accessibilityReduceMotion)` — skip scale/slide/bounce when enabled.
10. **Always** add a `HapticManager` call at the key moments (correct/wrong/milestone). Button taps via `.pressable()` already include a light haptic.

### 5.2 SwiftUI pitfalls (learned the hard way)

- `Text("\(someInt)")` applies locale formatting — `2019` renders as `"2,019"`. For years / raw integer displays use `Text(verbatim: "\(n)")` or `Text(String(n))`.
- Avoid `UIScreen.main.bounds` for layout. Use `GeometryReader` or SwiftUI's native layout (Spacer pairs, `maxWidth: .infinity`).
- In horizontal pairs of cards (e.g., compact steppers), use `.frame(maxWidth: .infinity, maxHeight: .infinity)` for equal heights — don't set fixed heights. Labels need `.lineLimit(1)` + `.minimumScaleFactor(0.75)` to prevent wrapping.
- Keyboard-aware search screens (Movie Chain, Casting Director): search results must **overlay** content, not push it. Keep at least 2–3 result rows visible with the keyboard up.
- Don't duplicate prompt text between the content area and the search field when space is tight.

### 5.3 Swift / code quality

- No force-unwraps (`!`) except where genuinely safe (static resources you control).
- Default to `private` / `fileprivate` for anything not explicitly shared.
- Prefer value types (`struct`) for models and view models where reasonable. `@Observable` classes are fine for view models.
- Don't import UIKit unless there's no SwiftUI alternative (e.g., haptic generators are inside `HapticManager` already).
- Don't add third-party SPM dependencies without asking.
- Match the existing file header style where present (many files have the `// Created by Claude Code` comment — keep or omit consistently, don't mix).

---

## 6. How to build, run, and verify

### 6.1 Open in Xcode (the normal path)

```
open GamesWithFriends.xcodeproj
```

Then `⌘B` to build, `⌘R` to run in the simulator. Select any iOS 17+ simulator.

### 6.2 Build from the command line

```bash
# Clean build for the default simulator destination
xcodebuild \
  -project GamesWithFriends.xcodeproj \
  -scheme GamesWithFriends \
  -destination 'generic/platform=iOS Simulator' \
  clean build

# Run unit tests (once a test target exists)
xcodebuild \
  -project GamesWithFriends.xcodeproj \
  -scheme GamesWithFriends \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

> **Note:** As of this writing there is no shared `GamesWithFriendsTests` target. Don't fabricate one silently — if tests are needed, propose it first and add it explicitly.

### 6.3 Manual verification expectations

After any non-trivial change the agent is expected to at least:
1. Build succeeds with no new warnings.
2. The affected game's Xcode Preview still compiles (previews are how this project catches regressions early).
3. If a UI change: eyeball it in light **and** dark mode previews.
4. If a data-model change: add a one-liner to `DECISIONS.md` about migration impact.
5. For shipping-grade work, copy the relevant sections of `BUILD_CHECKLIST.md` into a per-game checklist and walk through it.

---

## 7. Workflows the agent should know

### 7.1 "Add a new game"

1. Confirm the game name, one-line description, SF Symbol icon name, and accent color category with the user (see `DESIGN_GUIDE.md` §2.2 for allowed palette).
2. Scaffold `Features/<GameName>/` with `Models/`, `ViewModels/`, `Views/`, and `<GameName>Game.swift`.
3. Add the accent color mapping in `GameTheme.swift`.
4. Implement `struct <GameName>Game: GameDefinition` with the required properties and `makeRootView()`.
5. **Register** it in `Features/GameHub/GameRegistry.swift`'s `allGames()` array.
6. Build a minimal `<GameName>View` that at least uses `WarmLinenBackground()` and a title — confirms wiring before implementing gameplay.
7. Build in Xcode, verify it appears in the hub, then iterate on gameplay.

### 7.2 "Modify an existing game"

1. Read that game's folder top-to-bottom first — don't assume structure from another game.
2. Check if there's a `*_PRD.docx` / `*_DesignHandoff.docx` pair for it (currently only BorderHop has these). If yes, read the spec before editing.
3. Make the change. Keep files small and focused.
4. Verify `GameRegistry.allGames()` wasn't broken.

### 7.3 "Fix a UI bug"

1. Reproduce it mentally from `DESIGN_GUIDE.md` first — is the bug a violation of the design system, or a genuine SwiftUI layout issue?
2. If it's a token violation (raw color, hardcoded padding, `ProgressView`, etc.), fix it by using the correct token — don't just patch the symptom.
3. Test in both color schemes.

### 7.4 "Write documentation"

- Docs meant for humans (or Claude as a reader) go in the repo root as `.md`.
- Long-form specs / PRDs can live as `.docx` alongside (there's precedent — BorderHop has three).
- **Always** update `DECISIONS.md` when the doc represents an architectural shift.

---

## 8. What to ask the user before doing

The agent should stop and ask — not guess — when any of the following apply:

- Adding an external dependency (SPM package or otherwise).
- Introducing a new architectural pattern (Combine, Redux-like, Core Data, etc.).
- Changing the `GameDefinition` protocol or `GameRegistry` shape.
- Breaking a SwiftData `@Model` schema in a way that loses user data.
- Renaming a shipped game (user-visible strings).
- Picking an accent color that isn't in the `DESIGN_GUIDE.md` palette.
- Anything that touches `GamesWithFriendsApp.swift` app-level configuration.

---

## 9. Out of scope (don't do this)

- Don't convert SwiftUI views to UIKit "for flexibility".
- Don't port to macOS / iPadOS optimizations without being asked.
- Don't add analytics, crash reporting, or network calls — this is an offline-first app.
- Don't add login / auth.
- Don't generate marketing copy or App Store listing content unless asked.

---

## 10. Pointers

- `CLAUDE.md` → points at this file.
- `DECISIONS.md` → running log of choices and gotchas. Read when debugging; append when deciding.
- `DESIGN_GUIDE.md` → UI bible.
- `.claude/settings.local.json` → Claude Code local permissions; don't check secrets in here.
