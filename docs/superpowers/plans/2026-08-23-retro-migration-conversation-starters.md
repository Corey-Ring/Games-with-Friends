# Retro Migration — Conversation Starters (Phase 4 Pilot) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate all four Conversation Starters screens (setup, in-game, settings, saved) to the Retro Maximalist look per `GamesWithFriends/ART_DIRECTION.md`, without touching any gameplay logic, and produce `RETRO_MIGRATION_PLAYBOOK.md` so the remaining games can follow the same recipe.

**Architecture:** Views-only migration. A new `ConversationStartersStyle.swift` centralizes the candy remaps for vibe levels and categories (currently duplicated across three view files). The four view files re-skin using the phase-1/2 primitives (`MotifGroundView`, `.retroCard/.retroPanel/.retroLozenge`, `RetroPrimaryButton`, `RetroCategoryPill`, `RetroRaisedButtonStyle`, `RetroSpotIllustration(.speechBubbles)`). `GameTheme.conversationStarters` gets its §3.2 accent remap (Soft Mauve → Bubblegum) pulled forward from phase 3 — safe because after this migration nothing outside this game reads it (the hub uses `AppTheme.Retro.accent(forGameID:)`).

**Tech Stack:** SwiftUI (iOS 17+), legacy pbxproj (4-place registration for the one new file), simulator iPhone 17 / iPhone 17 Pro (install BOTH by UDID).

**Working directory:** `GamesWithFriends/`.

## Gameplay invariants (the "don't mess up gameplay" contract)

Files that must NOT change: `ViewModels/GameViewModel.swift`, `Models/*`, `Data/*`, `Utilities/*`, `ConversationStartersGame.swift`. Verify with `git diff --stat` before the final commit.

Behavior that must survive re-skin, verified on-simulator in Task 6:
1. Player count stepper: min 2 enforced, minus disabled at 2.
2. Vibe slider: 5 stops, updates description text.
3. Category/theme pills toggle selection; Start uses the filters (`updateFilteredStarters()` before presenting).
4. Card drag: >100pt right → previous (only if `hasPrevious`), >100pt left → next; card springs back; Reduce Motion path intact (`withNavAnimation`).
5. Prev button disabled state on first card; next past last card → All Done; Reset Deck restores.
6. Star toggle persists to Saved list; share sheet opens from Saved.
7. Timer: enabled toggle starts/pauses, presets + custom set duration, <10s turns red-equivalent (tomato), scene-phase backgrounding pauses (HomeView `.onChange(of: scenePhase)` kept).
8. All `accessibilityLabel`s kept or improved; empty deck shows empty state, not a running timer (GameView `.onAppear` guard kept).

## Candy remaps (single source: `ConversationStartersStyle.swift`)

Vibe (1–5, was accent/success/gold/warning/error): 1 Ice → `poolBlue`, 2 Casual → `grass`, 3 Fun → `tangerine`, 4 Deep → `plum`, 5 Daring → `tomato`.
Category (was accent/error/warning/accent/success/accent — with duplicates): wouldYouRather → `bubblegum`, hotTakes → `tomato`, hypotheticals → `tangerine`, storyTime → `cornflower`, thisOrThat → `grass`, deepDive → `plum`.
Chip text: `plum` → cream, all others → ink (§8: ink passes ≥4.5:1 on every non-plum chip color; cream body is only safe on plum).
Game accent everywhere else: `AppTheme.Retro.bubblegum` (§3.2; one game accent per screen — category/vibe colors are semantic garnish on cream, not competing accents).

---

### Task 1: Style file + GameTheme accent remap

**Files:**
- Create: `Features/ConversationStarters/Views/ConversationStartersStyle.swift`
- Modify: `Theme/GameTheme.swift:14` (accent only)
- Modify: `GamesWithFriends.xcodeproj/project.pbxproj` (4 places, IDs suffix `10` after phase-2's `0F`)

- [x] **Step 1: Create the style file**

```swift
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
```

- [x] **Step 2: Remap the GameTheme accent**

In `Theme/GameTheme.swift` line 14, change only the accent:

```swift
    static let conversationStarters = GameTheme(accentColor: AppTheme.Retro.bubblegum, name: "Conversation Starters", iconName: "bubble.left.and.bubble.right.fill")
```

- [x] **Step 3: Register the new file in pbxproj** — same 4 places as phase 2, new IDs `TH0000010000000000000010` / `TH0000020000000000000010`, but in the **ConversationStarters Views group** (find the group children containing `SavedStartersView.swift` and add after it; PBXBuildFile/PBXFileReference sections next to the phase-2 `0F` entries; Sources phase after the `0F` line).

- [x] **Step 4: Build** (standard build command). Expected: `** BUILD SUCCEEDED **`.

- [x] **Step 5: Commit** — `feat(cs): candy style maps + GameTheme accent remap (phase-3 pull-forward)`.

---

### Task 2: HomeView (setup screen)

**Files:** Modify `Features/ConversationStarters/Views/HomeView.swift` (visual layer only — keep `FlowLayout`, all bindings, `scenePhase` pause, sheet wiring, vibe name/description functions).

Changes (complete replacements for the visual layer):

- **Background:** replace the `LinearGradient` with `GeometryReader { geo in MotifGroundView(exclusions: [CGRect(x: 8, y: 60, width: geo.size.width - 16, height: geo.size.height - 60)]) }.ignoresSafeArea()` — content column is wide here, so motifs keep to a top strip and thin edges.
- **Header:** spot plate + framed title (Rule 4 — Lilita One, not Shrikhand: game names exceed the ~8-char Shrikhand cap):

```swift
VStack(spacing: AppTheme.Spacing.sm) {
    ZStack {
        Circle().fill(AppTheme.Retro.panel)
        Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
        RetroSpotIllustration(kind: .speechBubbles)
            .frame(width: 64, height: 64)
    }
    .frame(width: 84, height: 84)

    Text("Conversation Starters")
        .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
        .foregroundColor(AppTheme.Retro.ink)
        .multilineTextAlignment(.center)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .retroPanel(ConversationStartersStyle.accent)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
        .rotationEffect(.degrees(-1))

    Text("Break the ice and spark great conversations")
        .font(AppTheme.Typography.secondary)
        .foregroundColor(AppTheme.Retro.panelText)
        .multilineTextAlignment(.center)
        .retroLozenge()
        .rotationEffect(.degrees(0.8))
}
.padding(.top, AppTheme.Spacing.lg)
```

- **Setting cards:** each of the four sections (Players / Vibe / Categories / Themes) drops `.background(AppTheme.cardSurface) .clipShape(...) .shadow(radius: 5)` for `.retroCard()`. Section `Label`s become `.font(AppTheme.Retro.Typography.cardTitle).foregroundColor(AppTheme.Retro.panelText)`.
- **Stepper buttons:** ink glyphs in outlined accent circles (44pt targets), disabled at min:

```swift
Button(action: { if viewModel.settings.playerCount > 2 { viewModel.settings.playerCount -= 1 } }) {
    Image(systemName: "minus")
        .font(AppTheme.Typography.cardTitle.weight(.black))
        .foregroundColor(AppTheme.Retro.ink)
        .frame(width: 44, height: 44)
        .background(Circle().fill(ConversationStartersStyle.accent))
        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
}
.disabled(viewModel.settings.playerCount <= 2)
.opacity(viewModel.settings.playerCount <= 2 ? 0.35 : 1)
```
(plus button identical with `"plus"`, no upper-bound disable — matches current behavior). Count keeps `screenTitle` font, `panelText` color.
- **Vibe slider:** keep `Slider` mechanics; `.tint(ConversationStartersStyle.vibeColor(viewModel.settings.vibeLevel))`; labels/description → `panelText`/`cocoa` on the cream card; delete the local `vibeColor(for:)` (use the style enum).
- **Pills:** swap `CategoryPill` → `RetroCategoryPill(title:icon:color: ConversationStartersStyle.accent, isSelected:action:)` in both Categories and Themes sections (same toggle closures).
- **Start button:** `RetroPrimaryButton(title: "Start Game", icon: "play.fill", accent: ConversationStartersStyle.accent) { viewModel.updateFilteredStarters(); showingGame = true }`.
- **Toolbar:** keep both buttons and labels; star icon `.foregroundColor(AppTheme.Retro.mustard)`, gear `.foregroundColor(AppTheme.Retro.ink)`.

- [x] **Step 1: Apply the changes above** · **Step 2: Build** · **Step 3: Screenshot on simulator, compare against §5/§8** · **Step 4: Commit** `feat(cs): retro setup screen`.

---

### Task 3: GameView + CardView (in-game)

**Files:** Modify `Features/ConversationStarters/Views/GameView.swift`. Keep: `withNavAnimation`, drag gesture (thresholds, `hasPrevious` guard), toolbar actions, reset alert, `.onAppear` timer guard, all accessibility labels.

- **Background:** replace `backgroundGradient` + `vibeColor` computed vars with `MotifGroundView(seed: 0xC0FFEE, exclusions: [CGRect(x: 24, y: 100, width: geo.size.width - 48, height: geo.size.height - 180)])` in a `GeometryReader` (card + controls column excluded; the vibe-tinted gradient is retired — vibe color still reads from the card's dot meter, and gradients are banned in §2 rule 2).
- **Progress + timer row:** progress text becomes an ink-on-cream lozenge; timer becomes a lozenge whose text/icon turn `AppTheme.Retro.tomato` under 10s (semantics preserved):

```swift
Text("\(viewModel.currentIndex + 1) of \(viewModel.filteredStarters.count)")
    .font(AppTheme.Retro.Typography.pillLabel)
    .foregroundColor(AppTheme.Retro.panelText)
    .retroLozenge()
```

```swift
private var timerView: some View {
    HStack(spacing: 5) {
        Image(systemName: viewModel.isTimerRunning ? "timer" : "pause.circle")
        Text(timeString(from: viewModel.timeRemaining))
            .font(AppTheme.Retro.Typography.pillLabel)
            .monospacedDigit()
    }
    .foregroundColor(viewModel.timeRemaining < 10 ? AppTheme.Retro.tomato : AppTheme.Retro.panelText)
    .retroLozenge()
    .accessibilityElement(children: .combine)
    .accessibilityLabel(viewModel.isTimerRunning ? "\(Int(viewModel.timeRemaining)) seconds remaining" : "Timer paused")
}
```

- **CardView:** cream retro panel with hard shadow (drag rotation preserved by the caller):
  - container: `.retroPanel(AppTheme.Retro.panel)` + ink hard-shadow background rect (as in phase-2 cards), replacing `.background(cardSurface).clipShape(...).shadow(radius: 10)`.
  - category chip: capsule filled `ConversationStartersStyle.categoryColor(starter.category)`, text/icon `chipTextColor(on:)`, ink stroke 2.
  - star button: `isStarred ? AppTheme.Retro.mustard : AppTheme.Retro.ink.opacity(0.35)`.
  - question text: `panelText`.
  - vibe dots: filled `ConversationStartersStyle.vibeColor(starter.vibeLevel)`, empty `AppTheme.Retro.ink.opacity(0.15)`, each with `.overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1))` (Rule 1).
  - theme chips: capsule fill `AppTheme.Retro.bubblegum`, ink text, ink stroke 1.5.
  - delete CardView's local `categoryColor`/`vibeColor` (use the style enum).
- **Nav buttons:** outlined candy circles with press physics, same disabled logic:

```swift
Button(action: { withNavAnimation { viewModel.previousStarter() } }) {
    Image(systemName: "chevron.left")
        .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
        .foregroundColor(AppTheme.Retro.ink)
        .frame(width: 64, height: 64)
        .retroPanel(viewModel.hasPrevious ? ConversationStartersStyle.accent : AppTheme.Retro.panel,
                    cornerRadius: 999)
}
.buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
.disabled(!viewModel.hasPrevious)
.opacity(viewModel.hasPrevious ? 1 : 0.4)
.accessibilityLabel("Previous conversation starter")
```
(next button mirrors with `chevron.right`, always enabled; Pass button becomes a tangerine lozenge stack, same action/label.)
- **Empty state / All Done:** replace naked SF heroes (§9) with the game's spot plate + framed heading + `RetroPrimaryButton`:
  - empty: spot plate (66pt `.speechBubbles`), "No Starters Available" in `heading(20)` on a cream panel, body text `panelText`, `RetroPrimaryButton(title: "Back to Settings", accent: accent) { dismiss() }` (fixed width via `.padding(.horizontal, AppTheme.Spacing.xl)`).
  - all done: same recipe with grass accent — heading panel `.retroPanel(AppTheme.Retro.grass)` with **cream** display text (§8 display-only is fine at 20pt Lilita), `RetroPrimaryButton(title: "Start Over", accent: AppTheme.Retro.grass) { viewModel.resetDeck() }`.

- [x] **Step 1: Apply** · **Step 2: Build** · **Step 3: Screenshot** · **Step 4: Commit** `feat(cs): retro in-game screen`.

---

### Task 4: SettingsView + SavedStartersView (sheets)

**Files:** Modify both view files. Keep every binding, `onChange` timer hooks, share-sheet presentation code, list/Form mechanics (DESIGN_GUIDE mechanics still bind).

- **SettingsView:** keep the `Form`; migrate its chrome: `.scrollContentBackground(.hidden)` + `.background(AppTheme.Retro.ground.ignoresSafeArea())` (no motifs behind a dense form — §7 interactive clearance); `.listRowBackground(AppTheme.Retro.panel)`; section headers/footers `.foregroundColor(AppTheme.Retro.cocoa)`; replace both `.foregroundColor(.blue)` checkmarks and the blue/purple icon tints with `ConversationStartersStyle.accent` / `AppTheme.Retro.ink`; toggles `.tint(ConversationStartersStyle.accent)`; "Set Custom Timer" keeps `.borderedProminent` but `.tint(ConversationStartersStyle.accent)` with `.foregroundColor(AppTheme.Retro.ink)`.
- **SavedStartersView:** `List` stays; `.scrollContentBackground(.hidden)` + ground background; each row `.listRowBackground(Color.clear)` + `.listRowSeparator(.hidden)` with row content in `.retroCard()`; category chip + vibe dots use `ConversationStartersStyle` (delete both local color funcs); Share/Remove become lozenge buttons (Share: accent fill/ink text; Remove: tomato fill/ink text) with the same actions; empty state gets the spot-plate + panel-heading recipe (star icon → `.starFace`? No — stay on-game: `.speechBubbles` plate with a mustard star overlay is overkill; use the plain recipe with "No Saved Starters").

- [x] **Step 1: Apply both** · **Step 2: Build** · **Step 3: Screenshots (settings, saved-empty, saved-with-items)** · **Step 4: Commit** `feat(cs): retro settings + saved sheets`.

---

### Task 5: On-simulator gameplay verification

- [x] **Step 1:** Install on BOTH booted simulators by UDID, launch.
- [x] **Step 2:** Walk the invariants list (top of this plan) by scripted taps/swipes: stepper min-clamp, slider, pill toggles, Start, card swipe left/right ×3, prev-disabled on first, star a card, open Saved (star present), share sheet opens+dismiss, Settings timer enable → countdown lozenge appears, <10s turns tomato, background/foreground pause (scene phase), advance past last card → All Done → Start Over resets.
- [x] **Step 3:** Screenshot each screen (setup, card, card-with-timer, all-done, saved, settings); fix visual defects found; re-run affected checks.
- [x] **Step 4:** `git diff --stat` — confirm ONLY the five view-layer files + GameTheme + pbxproj + docs changed. Commit fixes.

---

### Task 6: Playbook + decision log

- [x] **Step 1:** Write `GamesWithFriends/RETRO_MIGRATION_PLAYBOOK.md` — the per-game recipe distilled from this pilot: (1) create `<Game>Style.swift` with candy remaps for the game's semantic colors (+§8 text rule); (2) remap the game's `GameTheme` accent; (3) per screen: ground+exclusions, spot-plate header, `.retroCard()` sections, `RetroPrimaryButton`/`RetroCategoryPill`, lozenge chips/timers, outlined-circle nav buttons, spot-plate empty/celebration states; (4) keep-list (view models, gestures, timers, a11y labels, Form/List mechanics); (5) verification checklist template; (6) pbxproj registration steps; (7) which colors take ink vs cream text (§8 table).
- [x] **Step 2:** Append DECISIONS.md entry (phase-4 pilot landed; GameTheme pull-forward rationale; vibe/category candy ramps; gradient-background retirement).
- [x] **Step 3:** Final full test suite run (all existing tests must stay green — no logic changed). Commit `docs: retro migration playbook + CS pilot decision log`.

---

## Self-Review Notes

- **Gameplay safety:** every task lists what to keep; Task 5 verifies the invariants end-to-end; Task 5 Step 4 proves file-scope discipline via `git diff --stat`.
- **Spec coverage:** Rules 1–6 (outlines, flat+hard shadows, motif grounds with §7 exclusions, framed Lilita headers — Shrikhand correctly NOT used for >8-char game names, lozenge devices, spot-plate faces); §8 contrast (ink-on-chip table, plum→cream, cream display on grass panel only at ≥17pt); §9 retirements (gradients, naked SF heroes, soft shadows, opacity tints).
- **Type consistency:** `ConversationStartersStyle.accent/vibeColor/categoryColor/chipTextColor` used identically across Tasks 2–4.
