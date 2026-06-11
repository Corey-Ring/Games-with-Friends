# Remove License Plate Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fully remove the License Plate Game from Games With Friends — code, Xcode project references, SwiftData schema, and all documentation — to narrow the product to active, session-based games.

**Architecture:** The game is one self-contained feature folder (`Features/LicensePlateGame/`, 16 Swift files) plus four leak points into shared code: the game registry, the `GameTheme` palette, the app-level SwiftData container, and a `#Preview` container. The Xcode project is **manually managed** (no file-system-synchronized groups), so every source file is individually referenced in `project.pbxproj` and must be de-registered or the build breaks. Removal happens in two commits: (1) code + project + file deletion as one atomic, compiling change; (2) documentation cleanup.

**Tech Stack:** Swift 5.9 / SwiftUI / SwiftData, single iOS target, Xcode project with a hand-maintained `project.pbxproj`. No unit-test target exists (per `AGENTS.md` §6.2), so verification is a successful `xcodebuild` build plus grep assertions that no dangling references remain.

---

## Judgment calls baked into this plan (review before executing)

Three documentation files are 100% License-Plate-specific and are **deleted** by this plan:
- `LICENSE_PLATE_GAME_README.md` — entirely about the game.
- `IMPLEMENTATION_SUMMARY.md` — entirely about the game.
- `QUICK_START.md` — titled "License Plate Game - Quick Start Guide"; its build/troubleshooting content is license-plate-flavored and stale. Generic build instructions already live in `AGENTS.md` §6.

One file is a closer call and is also **deleted**:
- `BUILD_CHECKLIST.md` — titled "Build Checklist - License Plate Game". `AGENTS.md` §4 frames it as a reusable QA template, but its body is license-plate test steps and it links to `LICENSE_PLATE_GAME_README.md` (being deleted). **Alternative if you'd rather keep a QA template:** instead of deleting it, rewrite it game-agnostic and keep the `AGENTS.md` references. This plan assumes deletion; if you want the alternative, skip the `BUILD_CHECKLIST.md` deletion in Task 2 Step 7 and the related `AGENTS.md` edits in Steps 2–3.

Two files contain **historical** License Plate mentions and are intentionally left **untouched** (editing point-in-time records rewrites history):
- `AUDIT_SUMMARY.txt` (lines 29, 171, 228) — past audit findings, now moot.
- `FinishTheLine_PRD.md` (lines 18, 68) — PRD rationale that referenced License Plate as a comparison.

If you disagree with any of these, resolve it before running Task 2.

---

## File Map

**Code — modify:**
- `Features/GameHub/GameRegistry.swift:8` — remove the `LicensePlateGame()` registry entry.
- `Theme/GameTheme.swift:14` — remove the `licensePlate` theme.
- `GamesWithFriendsApp.swift:18` — drop `RoadTrip`/`SpottedPlate` from the app SwiftData container.
- `Features/GameHub/GameHubView.swift:82` — fix the `#Preview` container (currently uses only the two deleted models).

**Code — delete (entire folder, 16 `.swift` + `.DS_Store`):**
- `Features/LicensePlateGame/`

**Xcode project — modify:**
- `GamesWithFriends.xcodeproj/project.pbxproj` — remove 16 `PBXBuildFile`, 16 `PBXFileReference`, the parent-group membership line, the 5 `PBXGroup` definitions (LicensePlateGame + Models/Resources/ViewModels/Views), and 16 `PBXSourcesBuildPhase` entries.

**Docs — modify:**
- `AGENTS.md` — §1 games list (line 23), §4 doc table (remove 4 rows), §6.3 checklist sentence (line 209).
- `CLAUDE.md:21` — Quick-links "Game-specific specs".
- `DESIGN_GUIDE.md:63` — accent-color table row.
- `README.md` — full rewrite (currently a License-Plate README).
- `DECISIONS.md` — append a `[migration]` entry.

**Docs — delete:**
- `LICENSE_PLATE_GAME_README.md`, `IMPLEMENTATION_SUMMARY.md`, `QUICK_START.md`, `BUILD_CHECKLIST.md`

---

## Task 1: Remove the game from code, the Xcode project, and disk (one atomic commit)

The project only compiles in the final state, so all edits in this task land in a single commit. Do every step, then build, then commit.

**Files:**
- Modify: `Features/GameHub/GameRegistry.swift`
- Modify: `Theme/GameTheme.swift`
- Modify: `GamesWithFriendsApp.swift`
- Modify: `Features/GameHub/GameHubView.swift`
- Modify: `GamesWithFriends.xcodeproj/project.pbxproj`
- Delete: `Features/LicensePlateGame/` (whole folder)

- [ ] **Step 1: Remove the registry entry**

In `Features/GameHub/GameRegistry.swift`, delete the License Plate line.

Replace:
```swift
        return [
            AnyGameDefinition(LicensePlateGame()),
            AnyGameDefinition(ConversationStartersGame(
```
with:
```swift
        return [
            AnyGameDefinition(ConversationStartersGame(
```

- [ ] **Step 2: Remove the GameTheme entry**

In `Theme/GameTheme.swift`, delete the `licensePlate` theme.

Replace:
```swift
    // MARK: - Pre-built Themes
    static let licensePlate = GameTheme(accentColor: AppTheme.skyBlue, name: "License Plate Game", iconName: "car.fill")
    static let conversationStarters = GameTheme(accentColor: AppTheme.softMauve, name: "Conversation Starters", iconName: "bubble.left.and.bubble.right.fill")
```
with:
```swift
    // MARK: - Pre-built Themes
    static let conversationStarters = GameTheme(accentColor: AppTheme.softMauve, name: "Conversation Starters", iconName: "bubble.left.and.bubble.right.fill")
```

> Note: `AppTheme.skyBlue` may now be unused. Leave it defined — removing a base design token is out of scope and risks other references.

- [ ] **Step 3: Drop the two models from the app-level SwiftData container**

In `GamesWithFriendsApp.swift`, line 18.

Replace:
```swift
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self, FinishTheLineRoundResult.self])
```
with:
```swift
        .modelContainer(for: [FinishTheLineRoundResult.self])
```

- [ ] **Step 4: Fix the GameHubView preview container**

In `Features/GameHub/GameHubView.swift`, line 82, the preview references only the two deleted models. Point it at the remaining persisted model instead.

Replace:
```swift
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self], inMemory: true)
```
with:
```swift
        .modelContainer(for: FinishTheLineRoundResult.self, inMemory: true)
```

- [ ] **Step 5: Confirm the `project.pbxproj` line ranges still match**

The next step deletes License Plate entries from `project.pbxproj` by line number. Confirm the ranges first (if the file has drifted since this plan was written, regenerate them before running the `sed`).

Run:
```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
grep -n "F[124]0000010000000000000030\|F[124]0000010000000000000045\|/* LicensePlateGame */" GamesWithFriends.xcodeproj/project.pbxproj
```
Expected (line numbers must match the ranges used in Step 6 — 92, 107, 260, 275, 632, 756, 1201, 1216):
- `92:` first `PBXBuildFile` (LicensePlateGame.swift in Sources)
- `107:` last `PBXBuildFile` (TripStatsView.swift in Sources)
- `260:` first `PBXFileReference`
- `275:` last `PBXFileReference`
- `632:` parent-group membership (`/* LicensePlateGame */,`)
- `756:` `LicensePlateGame` group definition opens
- `1201:`/`1216:` sources build-phase range

If any boundary differs, recompute the five ranges before Step 6.

- [ ] **Step 6: Delete all License Plate entries from `project.pbxproj`**

`sed` addresses are evaluated against the original input line numbers in a single pass, so listing the ranges in any order is safe (BSD/macOS `sed` requires the empty `-i ''`).

Run:
```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
sed -i '' \
  -e '1201,1216d' \
  -e '756,810d' \
  -e '632d' \
  -e '260,275d' \
  -e '92,107d' \
  GamesWithFriends.xcodeproj/project.pbxproj
```
These ranges cover: sources build phase (1201–1216), the 5 `PBXGroup` blocks — LicensePlateGame + Models + Resources + ViewModels + Views (756–810), parent-group membership (632), file references (260–275), and build files (92–107).

- [ ] **Step 7: Verify no License Plate references remain in the project file**

Run:
```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
grep -in "LicensePlate\|PlateRegion\|RoadTrip\|SpottedPlate\|PlateData\|AchievementsView\|LifetimeStatsView\|PlateDetailView\|PlateGridView\|SpotPlateView\|TripSelectionView\|TripStatsView\|Achievement.swift" GamesWithFriends.xcodeproj/project.pbxproj
```
Expected: no output (exit code 1).

Also sanity-check the file isn't structurally broken (balanced PBXGroup count is unchanged elsewhere):
```bash
grep -c "isa = PBXGroup;" GamesWithFriends.xcodeproj/project.pbxproj
```
Expected: 5 fewer than before removal (the LicensePlate group + 4 subgroups are gone).

- [ ] **Step 8: Delete the feature folder from disk**

Run:
```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
rm -rf Features/LicensePlateGame
```

Verify it's gone:
```bash
test ! -e Features/LicensePlateGame && echo "removed"
```
Expected: `removed`.

- [ ] **Step 9: Verify no License Plate references remain anywhere in source**

Run:
```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
grep -rn "LicensePlate\|licensePlate\|RoadTrip\|SpottedPlate\|PlateRegion\|PlateData" --include="*.swift" .
```
Expected: no output (exit code 1).

- [ ] **Step 10: Build to verify the project compiles**

Run:
```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
xcodebuild \
  -project GamesWithFriends.xcodeproj \
  -scheme GamesWithFriends \
  -destination 'generic/platform=iOS Simulator' \
  clean build 2>&1 | tail -30
```
Expected: `** BUILD SUCCEEDED **`. If the build fails with "Build input file cannot be found" or "cannot find type … in scope", a `project.pbxproj` range or a code reference was missed — fix before committing. Do not commit a red build.

- [ ] **Step 11: Commit**

```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
git add -A
git commit -m "Remove License Plate Game to narrow the product

Delete the Features/LicensePlateGame feature, its Xcode project
references, the GameTheme.licensePlate palette entry, and drop
RoadTrip/SpottedPlate from the SwiftData container. License Plate was
the only passive, solo, long-running collection tracker in an otherwise
active, session-based party-game library.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Task 2: Update and remove documentation (one commit)

**Files:**
- Modify: `AGENTS.md`, `CLAUDE.md`, `DESIGN_GUIDE.md`, `README.md`, `DECISIONS.md`
- Delete: `LICENSE_PLATE_GAME_README.md`, `IMPLEMENTATION_SUMMARY.md`, `QUICK_START.md`, `BUILD_CHECKLIST.md`

- [ ] **Step 1: Update the games list in `AGENTS.md` §1**

Line 23. Remove "License Plate Game" and add "Finish the Line" (currently registered but missing from this list).

Replace:
```
License Plate Game, Conversation Starters, Country Letter Game, Name 5, Border Blitz, Movie Chain, Casting Director, Vibe Check, Border Hop.
```
with:
```
Conversation Starters, Country Letter Game, Name 5, Border Blitz, Movie Chain, Casting Director, Vibe Check, Border Hop, Finish the Line.
```

- [ ] **Step 2: Remove the four deleted-doc rows from the `AGENTS.md` §4 table**

Replace:
```
| `README.md` | Quick project overview for humans. |
| `LICENSE_PLATE_GAME_README.md` | Deep dive on the first shipped game's data model + features. Useful as a reference implementation when building new games. |
| `IMPLEMENTATION_SUMMARY.md` | Historical implementation notes for License Plate Game. |
| `QUICK_START.md` | How to get the project building locally. |
| `BUILD_CHECKLIST.md` | License-Plate-specific QA checklist. Template to copy when shipping a new game. |
| `BorderHop_PRD.docx` / `BorderHop_DesignHandoff.docx` / `BorderHop_ImplementationPlan.docx` | Active spec for the Border Hop game. Read before touching `Features/BorderHop/`. |
```
with:
```
| `README.md` | Quick project overview for humans. |
| `BorderHop_PRD.docx` / `BorderHop_DesignHandoff.docx` / `BorderHop_ImplementationPlan.docx` | Active spec for the Border Hop game. Read before touching `Features/BorderHop/`. |
| `FinishTheLine_PRD.md` | Active spec for the Finish the Line game. Read before touching `Features/FinishTheLine/`. |
```

- [ ] **Step 3: Drop the `BUILD_CHECKLIST.md` reference in `AGENTS.md` §6.3**

Line 209.

Replace:
```
5. For shipping-grade work, copy the relevant sections of `BUILD_CHECKLIST.md` into a per-game checklist and walk through it.
```
with:
```
5. For shipping-grade work, walk through a manual QA pass (light + dark mode, empty/edge states, persistence) before considering the game done.
```

- [ ] **Step 4: Fix the Quick-links "Game-specific specs" line in `CLAUDE.md`**

Line 21.

Replace:
```
- Game-specific specs → `LICENSE_PLATE_GAME_README.md`, `BorderHop_PRD.docx` (+ handoff + plan)
```
with:
```
- Game-specific specs → `BorderHop_PRD.docx` (+ handoff + plan), `FinishTheLine_PRD.md`
```

- [ ] **Step 5: Remove the accent-color row in `DESIGN_GUIDE.md`**

Line 63. Delete the License Plate row.

Replace:
```
| License Plate Game | Sky Blue (`#5B9BD5`) | `GameTheme.licensePlate` |
```
with:
```
```
(i.e., remove the line entirely.)

- [ ] **Step 6: Rewrite `README.md`**

The current `README.md` is essentially the License Plate game's README. Replace the whole file with a roster-accurate overview that points at `AGENTS.md` as source of truth.

Overwrite `README.md` with:
```markdown
# Games with Friends

Building connections through games.

## Overview

GamesWithFriends is a native iOS app (SwiftUI + SwiftData) that bundles a growing
collection of quick party and road-trip games behind a single Game Hub. Pick a
game, play a round with the people around you, hand the phone off.

## Games

- **Conversation Starters** — break the ice and spark great conversations
- **Country Letter Challenge** — pick a letter and name every country that starts with it
- **Name 5** — race the clock to name 5 things
- **Border Blitz** — guess countries by their borders
- **Movie Chain** — connect movies through their actors
- **Casting Director** — guess the actor from progressive clues
- **Vibe Check** — get on the same wavelength
- **Border Hop** — a solo geography trainer; navigate the world one border at a time
- **Finish the Line** — race the clock to shout the missing word from iconic quotes

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Swift 5.9 or later

## Getting Started

1. Open `GamesWithFriends.xcodeproj` in Xcode.
2. Build and run on an iOS 17+ simulator or device (⌘R).
3. Pick a game from the hub and play.

## Architecture

- **SwiftUI** for the UI (no UIKit view controllers)
- **MVVM** with the `@Observable` macro (iOS 17 Observation framework)
- **SwiftData** (`@Model`) for persistence — zero external dependencies
- **Protocol-oriented** game registry: each game conforms to `GameDefinition` and
  is registered in `Features/GameHub/GameRegistry.swift`

For the full stack, architecture, coding rules, and "add a new game" workflow, see
[`AGENTS.md`](AGENTS.md) — the single source of truth for this repo.

## Contributing

This is a personal project, but suggestions and feedback are welcome.

## License

All rights reserved.

---

Made with ❤️ for game lovers everywhere.
```

- [ ] **Step 7: Delete the four License-Plate-specific docs**

```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
git rm LICENSE_PLATE_GAME_README.md IMPLEMENTATION_SUMMARY.md QUICK_START.md BUILD_CHECKLIST.md
```
(If you chose the "keep a QA template" alternative from the Judgment Calls section, omit `BUILD_CHECKLIST.md` here and skip Steps 2–3's `BUILD_CHECKLIST.md` edits.)

- [ ] **Step 8: Append a `[migration]` entry to `DECISIONS.md`**

Insert this entry as the newest entry — immediately after the `---` on line 29 (the separator below the template), before the `## 2026-06-11 — Border Hop scoring …` entry.

Insert:
```markdown
## 2026-06-11 — Removed the License Plate Game [migration]

**What:** Deleted `Features/LicensePlateGame/` (16 files), its `project.pbxproj` references, `GameTheme.licensePlate`, and the registry entry. Dropped `RoadTrip` and `SpottedPlate` from the SwiftData container in `GamesWithFriendsApp.swift` (now `[FinishTheLineRoundResult.self]`). Deleted the license-plate-era docs (`LICENSE_PLATE_GAME_README.md`, `IMPLEMENTATION_SUMMARY.md`, `QUICK_START.md`, `BUILD_CHECKLIST.md`).

**Why:** License Plate was the only passive, solo, long-running *collection tracker* in a library that is otherwise active, session-based party games. It read as off-format next to the rest of the hub. This is a deliberate product-narrowing decision, not a quality issue with the game.

**Impact:**
- **SwiftData:** `RoadTrip`/`SpottedPlate` are no longer in any container. There is no `VersionedSchema`/`MigrationPlan` in this project, so SwiftData applies default lightweight handling. Any existing install's saved trips/spotted plates become unreachable (acceptable — the game is gone). New installs are unaffected.
- The `AppTheme.skyBlue` token is now unused but left defined.
- License Plate was previously the codebase's "reference implementation." Use Border Hop or Finish the Line as the current reference for a new game.

**Alternatives considered:** Keeping it but grouping the hub into "Party" vs "Solo/Road Trip" sections (rejected — the goal was to narrow the product, not recategorize it).
```

- [ ] **Step 9: Verify no required docs still reference the game**

Run:
```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
grep -rIn -i "license plate\|licenseplate\|gametheme.licenseplate" \
  AGENTS.md CLAUDE.md DESIGN_GUIDE.md README.md
```
Expected: no output. (Historical mentions remain only in `AUDIT_SUMMARY.txt`, `FinishTheLine_PRD.md`, and `DECISIONS.md`, which are intentionally retained.)

- [ ] **Step 10: Commit**

```bash
cd /Users/coreyring/Games-with-Friends/GamesWithFriends
git add -A
git commit -m "Docs: drop License Plate Game references after removal

Update AGENTS.md, CLAUDE.md, DESIGN_GUIDE.md, and README.md; delete the
four license-plate-era docs; record the removal in DECISIONS.md.

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
```

---

## Self-Review (run after the plan is written; already applied)

**1. Spec coverage** — The ask was "delete it and update the appropriate markdown files."
- Delete the game (code) → Task 1 Steps 1–4, 8.
- Don't break the build (manual pbxproj) → Task 1 Steps 5–7, 10.
- SwiftData container fixed → Task 1 Steps 3–4; documented as `[migration]` → Task 2 Step 8.
- Update markdown → Task 2 Steps 1–6 (AGENTS, CLAUDE, DESIGN_GUIDE, README) + delete stale docs (Step 7) + DECISIONS (Step 8). Covered.

**2. Placeholder scan** — No "TBD"/"handle edge cases"/"similar to". Every edit shows exact before/after text or an exact command. The only deliberate openness is the documented Judgment Call on `BUILD_CHECKLIST.md`/`QUICK_START.md`, with an explicit alternative.

**3. Type consistency** — `FinishTheLineRoundResult` is the real remaining `@Model` (from `GamesWithFriendsApp.swift:18`); used identically in Task 1 Steps 3 and 4. The five `sed` ranges match the four `project.pbxproj` sections enumerated in the File Map and verified in Task 1 Step 5.

**Note on verification rigor:** This project has no test target (`AGENTS.md` §6.2), so "verify it fails / passes" is expressed as a clean `xcodebuild` build plus grep assertions rather than unit tests. Don't fabricate a test target.
