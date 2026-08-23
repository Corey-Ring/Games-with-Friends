# DECISIONS.md — running log

> A lightweight, append-only log of architectural decisions, gotchas, and "things I learned the hard way" for Games With Friends.
>
> **Who writes here:** Corey, or any AI assistant (Claude Code, Cursor, etc.) working in this repo. When you make a non-obvious choice — or discover a non-obvious constraint — add an entry so the next session inherits the context instead of re-deriving it.
>
> **Format:** newest entries at the top. Each entry: one `##` heading with the date and a short title, 1–5 sentences of body, and an optional "Context / alternatives considered / links" block if it's a genuinely sharp-edged call. Keep it short — this is not a PRD, it's a changelog for your brain.

---

## How to add an entry (template)

Copy-paste and fill in:

```
## YYYY-MM-DD — Short imperative title

**What:** One sentence stating the decision or the gotcha.

**Why:** One or two sentences on the reasoning.

**Impact:** What this means for future work (files affected, patterns to follow, things to avoid).

**Alternatives considered:** (optional) What you rejected and why.
```

Tag the entry with `[decision]`, `[gotcha]`, `[convention]`, or `[migration]` at the end of the title if it helps future search.

---

## 2026-08-23 — Retro phase 4 pilot: Conversation Starters migrated [migration]

**What:** All four Conversation Starters screens (setup, in-game, settings sheet, saved sheet) re-skinned to Retro Maximalist. New `ConversationStartersStyle` centralizes the candy remaps (vibe ramp: Ice poolBlue → Casual grass → Fun tangerine → Deep plum → Daring tomato; categories each get a distinct candy color, plum chips take cream text per §8). `GameTheme.conversationStarters` accent pulled forward to Bubblegum (phase-3 item; safe — hub reads the Retro accent map). The per-game recipe is documented in `RETRO_MIGRATION_PLAYBOOK.md` for the remaining eight games.

**Gameplay untouched:** view models, models, data, gestures, timers, haptics unchanged (verified via `git diff --stat` + on-simulator invariant walk: stepper clamp, pill filters, card swipe/prev-next, star→saved, share, timer enable/countdown).

**Deviations:** vibe-tinted background gradient retired (§2 bans gradients; vibe still reads from the card's dot meter); naked SF-symbol empty/done heroes replaced with spot-plate + panel recipe (§9).

**Fixed in passing:** (1) custom-label buttons in List rows need `.buttonStyle(.plain)` or a row tap fires every button (Share also fired Remove); (2) pre-existing silent failure — the saved-list share sheet presented from the root VC while the Saved sheet was up; now presents from the top-most presented VC.

---

## 2026-08-22 — Retro phase 2: hub re-skin landed [migration]

**What:** `GameHubView` is the first migrated shipped screen: motif ground, Shrikhand "GAMES" lockup, candy shelf cards with alternating ±0.6° tilt and press physics. New primitives: `AppTheme.Retro.accent(forGameID:)` (candy accents per §3.2) and `RetroSpotIllustrations.swift` (`RetroSpotKind` mapped from game ids + nine `Canvas`-drawn spots — six ported from the Option C artboard SVGs, three new: berry heart, cornflower suitcase, plum clapperboard). Verified on-simulator light + scrolled + navigation tap; system-dark renders consistently light because the app pins `.preferredColorScheme(.light)` (protected app-level config, deliberately untouched).

**Why:** ART_DIRECTION.md §10 phase 2; the Option C artboard is the spec.

**Deliberate deviations from the artboard:** (1) "Party games for your table" tagline omitted — §11 calls it placeholder copy. (2) Card descriptions sit in cream mini-panels rather than naked on accents — §8 requires the cream device on 6 of 9 accents; uniform treatment keeps the shelf consistent and makes contrast failures structurally impossible. (3) Logo stays 40 pt (artboard 44 px) for Dynamic Type headroom.

**Impact / gotchas:** Hub cards read accents from `AppTheme.Retro.accent(forGameID:)`, NOT `game.accentColor` — do not "simplify" back to `GameTheme` until phase 3 remaps it. Motif exclusion rects cover the header zone and card column; the layout generator adds its own 12 pt clearance, so pass the actual content rects (sparkles are up to 18 pt and will poke out from behind corners otherwise). Future games need a `RetroSpotKind` case + mapping (test enforces distinctness); unmapped ids fall back to the SF Symbol on a tangerine plate.

---

## 2026-08-22 — Retro phase 1: foundations landed [migration]

**What:** `AppTheme.Retro` tokens, bundled Shrikhand/Lilita One (runtime CTFontManager registration — project uses GENERATE_INFOPLIST_FILE, so no UIAppFonts plist), `.retroPanel/.retroCard/.retroLozenge`, `RetroRaisedButtonStyle` (shadow collapse + travel press physics), `MotifFieldLayout` (pure, seeded, tested) + `MotifGroundView`. No shipped screen changed; visual surface is `RetroShowcaseView` (Xcode Previews only), verified on-simulator against the Option C artboard.

**Why:** ART_DIRECTION.md §10 phase 1. Runtime font registration chosen over Info.plist keys for determinism with the generated plist.

**Impact:** Phase 2 (hub) builds only on these primitives — do not hand-roll outlines/shadows in views. `RetroFonts.registerAll()` is called from the app init and is idempotent; tests call it directly. Motif grounds take `exclusions` rects for interactive areas. Note the tests folder is `GamesWithFriends/GamesWithFriendsTests/` (nested), not a repo-root sibling.

---

## 2026-08-22 — Adopt Retro Maximalist art direction [decision] [migration]

**What:** The app is re-skinning from "warm minimalism" to a retro-maximalist candy-packaging aesthetic, formalized in `ART_DIRECTION.md`. Direction was picked from three mocked intensities on the [Retro Aesthetic Explorer canvas](https://claude.ai/code/artifact/3971b3d8-bb93-4d2e-8d79-bbba81408593) (Option C won); source photos + take/ignore notes live in `docs/design/inspiration/`.

**Why:** Corey wanted the app to carry the energy of Maeve/Fishwife packaging and 70s hand-painted murals; the minimal UI made that impossible to express beyond illustrations.

**Impact:** `DESIGN_GUIDE.md` now carries a supersession banner — its aesthetic sections (§1, §2, §3 display type, §4.2–4.3, §6, §10) yield to `ART_DIRECTION.md` on migrated screens; mechanics sections still bind everywhere. Migration is phased (tokens/components → hub → accent remap → per-game); a screen is either fully migrated or untouched, never blended. Per-game accent colors will be remapped (`ART_DIRECTION.md` §3.2) in one commit during phase 3.

**Alternatives considered:** Option A (retro illustrations inside the existing minimal shell — rejected as garnish) and Option B (ink outlines + candy palette on the existing card system — rejected in favor of C's full energy).

---

## 2026-07-12 — Launch-readiness pass: Vibe Check is Competition-only for 1.0 [decision]

**What:** Vibe Check ships Competition-only. After post-fix code review flagged the original "default `selectedMode = .competition`" routing as fragile (the classic state machine stayed live behind it), `VibeCheckRootView` was rewritten to drive `CompetitionVibeCheckViewModel` directly — the classic `VibeCheckViewModel` is never instantiated, and the dead classic setup UI (mode picker, `TeamSetupView`, stepper cards) was deleted from `VibeCheckHomeView`. Classic gameplay views and the classic VM remain in the target but have no entry point.

**Why:** Classic mode had a wrong-team reveal attribution bug (`finalizeRound()` appends to `rounds` before reveal, shifting `promptSetterTeam`), no dark-mode support, a single-team default that breaks the guessing premise, and the largest unremediated design-token debt in the app (per the 2026-03-22 audit). Competition mode is close to the quality bar; fixing Classic was the single biggest work item between here and launch.

**Impact:** To revive Classic in 1.1: fix the reveal ordering bug, the team-count default (min 2), dark mode (`pureWhite` card fills), and the `[.purple,.blue]` gradient/token debt — then restore the mode picker section deleted from `VibeCheckHomeView` (git history has it). `ScoringZone.color` is now tokenized (success/tealGreen/medalGold/warning/error) and shared by both modes.

---

## 2026-07-12 — Launch-readiness pass: gameplay & config decisions [decision]

**What:** One batch of pre-launch decisions, all landed together:
1. **Border Blitz** is capped at 10 rounds per session (`maxRounds`), "I Said It!" no longer earns the perfect bonus (`endRound(correct:manual:)`), `endRound` guards re-entrancy (`gameState == .playing`), Start requests mic permission when `.notDetermined`, and the whole game sits on `GameBackground` (was unreadable in dark mode).
2. **Casting Director**: the Era filter is now real — `ClueGenerator.pickRandomActor(era:)` samples up to 60 candidates and matches on the *median release year* of the actor's filmography (classic &lt;1990, modern 1990–2009, recent ≥2010), falling back to unfiltered rather than failing. The first clue is free (base 1,000 is achievable); the results breakdown is derived from the same state the VM scored with, so line items always sum to the round score.
3. **Name 5** pass-and-play now derives per-player standings from `RoundResult.playerNumber` and crowns a winner (ties supported) — no schema change, standings are computed at display time.
4. **Movie Chain**: Speed Round (`.timed`) gets the End Game button (was unreachable standings); the shared DB moved from Documents to **Application Support with `isExcludedFromBackup`** (557 MB no longer lands in iCloud backups; legacy Documents copies are migrated); actor search is ranked by `MAX(movie votes)` via the `movie_actors` join.
5. **Config**: iPhone-only (`TARGETED_DEVICE_FAMILY = 1`), portrait-only, privacy strings cover both mic games.
6. **Border Hop**: frontier taps now require adjacency to the *current* country (matching the destination branch) so recorded routes are always geographically valid; route-generation failure shows a message instead of a dead Start button, with `BorderHopRouteGenerationTests` as the regression net.

**Why:** Full pre-launch review (2026-07-12) found ten first-session player-facing bugs plus App Store submission issues; these were the fixes that changed gameplay behavior or device posture and needed explicit decisions.

**Impact:** No SwiftData schema changes anywhere in this pass. Saved Border Blitz-era scores don't exist (no persistence there). Expanding back to iPad/landscape later only requires reverting the two build settings — but re-test Vibe Check sliders and Movie Chain layout first.

---

## 2026-06-11 — Finish the Line fun-upgrade pass: live scoring, reveal beat, synthesized audio [decision]

**What:** Landed the approved game-feel slate for Finish the Line: (1) **Reveal Beat** — the source is now hidden while a card is live, fading in after 6s of being stuck as a lifeline hint; on correct/skip the blank fills with the answer (green/amber) for a ~0.9s beat before the next card. (2) **Live per-answer scoring** — difficulty now sets points per correct (easy 100 / medium 150 / hard 200) instead of an end-of-round score multiplier; `QuoteDifficulty.multiplier` still exists but is no longer used in scoring. (3) **Free skips** (streak reset is the only price) with the answer revealed on skip. (4) **On Fire** at streak 5: +2s per correct, capped at a 90s clock. (5) **Encore**: final 10s double points with per-second ticks. (6) **Pass-the-phone gauntlet**: session-only `scoreToBeat` (in-memory, not persisted). (7) **Mic trust**: matching only considers speech spoken after the current card appeared, and single-word answers of ≤4 letters must be among the last 3 words heard (stops ambient "it"/"go"/"back" from auto-scoring). (8) **Synthesized audio** via `FinishTheLineSoundPlayer` — tones rendered into `AVAudioPCMBuffer`s at runtime through `AVAudioEngine`; zero bundled assets, zero licensing. Also a full quote-library audit (~33 entries fixed/re-tiered/replaced; library is 201 quotes).

**Why:** Playtests read flat: the always-visible source line spoiled the tip-of-tongue tension and silently broke difficulty tiers; the end-of-round multiplier made the on-screen score a lie; whole-transcript matching gave false positives on common words; skips were doubly punished.

**Impact:**
- **SwiftData:** schema untouched. Saved `FinishTheLineRoundResult.score` values from the multiplier era remain comparable in magnitude (medium 1.5× ≈ 150/answer) but are not exactly equivalent — acceptable for a personal-best display.
- The audio session is shared with `FinishTheLineSpeechRecognitionManager` (`.playAndRecord`, `.defaultToSpeaker`); synthesized sounds therefore play **regardless of the silent switch**. Revisit if users complain.
- PG-13 judgment call: kept Taken's "I will ___ you → kill" at medium; cut "Welcome to the O.C., bitch" (profanity).
- New file `Features/FinishTheLine/Services/FinishTheLineSoundPlayer.swift` is registered in `project.pbxproj` with the `FTL…99` ID pair.

---

## 2026-06-11 — Removed the License Plate Game [migration]

**What:** Deleted `Features/LicensePlateGame/` (16 files), its `project.pbxproj` references, `GameTheme.licensePlate`, and the registry entry. Dropped `RoadTrip` and `SpottedPlate` from the SwiftData container in `GamesWithFriendsApp.swift` (now `[FinishTheLineRoundResult.self]`). Deleted the license-plate-era docs (`LICENSE_PLATE_GAME_README.md`, `IMPLEMENTATION_SUMMARY.md`, `QUICK_START.md`, `BUILD_CHECKLIST.md`).

**Why:** License Plate was the only passive, solo, long-running *collection tracker* in a library that is otherwise active, session-based party games. It read as off-format next to the rest of the hub. This is a deliberate product-narrowing decision, not a quality issue with the game.

**Impact:**
- **SwiftData:** `RoadTrip`/`SpottedPlate` are no longer in any container. There is no `VersionedSchema`/`MigrationPlan` in this project, so SwiftData applies default lightweight handling. Any existing install's saved trips/spotted plates become unreachable (acceptable — the game is gone). New installs are unaffected.
- The `AppTheme.skyBlue` token is now unused but left defined.
- License Plate was previously the codebase's "reference implementation." Use Border Hop or Finish the Line as the current reference for a new game.

**Alternatives considered:** Keeping it but grouping the hub into "Party" vs "Solo/Road Trip" sections (rejected — the goal was to narrow the product, not recategorize it).

---

## 2026-06-11 — Border Hop scoring is Route + Knowledge; time no longer scores [decision]

**What:** Border Hop's round score changed from `(efficiency + timeBonus) × streak` to `(Route + Knowledge) / 2 × streak`. Route is the existing hop-efficiency formula; Knowledge is per-question quiz credit (1.0 first try, 0.5 second, 0.25 third, 0 on reveal). The streak now continues on ≥75% round accuracy instead of beating a time benchmark. The −3s quiz reward, +5s backtrack penalty, and benchmark haptics are gone; the stopwatch remains as a display-only pace stat. The 3-strikes random-teleport was replaced with "reveal the answer and cross anyway" (zero credit).

**Why:** The game's north star is a solo geography *trainer*. Time pressure trained skimming — the optimal strategy was to rush past the educational content — and the teleport punished a wrong answer with disorientation right before the player would have seen the correct answer.

**Impact:**
- `BorderHopRoundResult` is a plain struct (no SwiftData involvement anywhere in Border Hop) — no migration concerns.
- The VM logs a `LearnedFact` per question; the results screen recaps them ("What you learned"). Any future quiz type must produce a one-line takeaway in `BorderHopViewModel.makeTakeaway(for:credit:)`.
- `BorderHopDifficulty.benchmarkTime` still exists but is unused by scoring; safe to remove later.

**Alternatives considered:** Keeping a small time bonus (rejected — any time scoring rewards skipping the facts); blocking passage on 3 strikes (rejected — progress-blocking in a trainer is pure frustration).

---

## 2026-06-11 — country_fun_facts.json replaced with short anonymous facts [decision]

**What:** The quiz fact bank (`Features/BorderHop/Data/country_fun_facts.json`) was replaced wholesale: 152 entries (exactly the playable set in `BorderHopCountryData`), 3 facts each, all ≤75 characters, phrased anonymously ("Westernmost country in mainland Europe") so they work as multiple-choice options. The old file held ~230-character CIA-factbook paragraphs; reading four of them per question was the single biggest usability failure in the game.

**Why:** Quiz content must be glanceable and quiz-able. Facts are derived from the already-curated short facts in `BorderHopCountryData.swift` plus well-established geography knowledge, biased toward superlatives and proper nouns so each fact uniquely identifies its country (a distractor fact must be *false* for the quizzed country — avoid generic claims like "over half is forest" that are true of several neighbors).

**Impact:**
- Same filename and schema (`{id, name, funFacts[]}`) — no pbxproj changes, `QuizEngine` decoding untouched. Old content is in git history; `facts_for_review.md` describes the old bank.
- When adding countries, add a JSON entry with 2–3 *anonymous, uniquely-identifying, ≤75-char* facts.
- Export quizzes also switched to single-commodity answers (`CountryExportProvider.distractorExports` filters out anything in the target's own top-5 list).

---

## 2026-06-11 — Border Hop map camera lives in canvas space with an Animatable view [decision]

**What:** `BorderHopMapView` now models the camera as `MapCamera { center, zoom }` in canvas coordinates, rendered by a private view conforming to `Animatable` (`animatableData` = center + zoom) so SwiftUI interpolates the camera itself. Labels/markers/trail are drawn in screen space at constant size; shapes are drawn through a `GraphicsContext` transform with stroke widths divided by zoom. `MapRenderer` switched to a Mercator projection (clamped ±78°), unwraps antimeridian-crossing rings (Russia), and exposes a per-country `focusBox` (mainland ring, clamped) for camera fitting.

**Why:** The old `scaleEffect + offset` approach arced/overshot when both animated, rasterized blurry at zoom, and framed countries by full-polygon bbox — so France framed French Guiana and Russia's bbox spanned the whole canvas.

**Impact:**
- Never animate the map by `scaleEffect`/`offset`; mutate `camera` (gestures set it directly, programmatic moves use `withAnimation`).
- Off-screen frontier countries and the destination render as tappable edge-indicator pills — camera fitting deliberately does *not* zoom out to include far neighbors.
- A Canvas does not interpolate plain `@State` — anything that must animate inside the map Canvas has to ride through `animatableData` (this is why the old "pulsing glow" never actually pulsed; glows are now static).

---

## 2026-04-13 — Finish the Line speech manager is a verbatim duplicate of Border Blitz's [gotcha]

**What:** `FinishTheLineSpeechRecognitionManager` is an intentional copy of `BorderBlitzSpeechRecognitionManager` — same class shape, same `matchHandler: ((String) -> Void)?` callback, same audio-engine tap, same auto-restart-on-silence behavior. Only the class name and the permission-status enum prefix differ.

**Why:** The existing manager is already generic enough to reuse as-is — the fuzzy-matching logic (sliding-window + normalization) lives in each game's ViewModel, not in the manager. A real shared `Core/Services/SpeechRecognitionManager.swift` would be nice, but hoisting it also means reconciling audio-session teardown behavior across two games while introducing a new feature. The duplication is the smaller risk for now.

**Impact:**
- Two managers to keep in sync until consolidation. Bug fixes to the audio session / SFSpeechRecognizer path must be applied to both files.
- A consolidation `TODO` comment has been added at the top of both managers referencing `FinishTheLine_PRD.md §6`. When Finish the Line ships and stabilizes, extract the common logic to `Core/Services/SpeechRecognitionManager.swift`.

**Alternatives considered:** Extract-first — rejected because the refactor would block the Finish the Line feature and put Border Blitz into regression risk for a purely internal cleanup.

---

## 2026-04-13 — Spotlight Plum (#8E3B5D) picked for Finish the Line accent [decision]

**What:** Finish the Line's accent color is `AppTheme.spotlightPlum` (`#8E3B5D`). Lives in `Theme/AppTheme.swift` alongside the other game accents and is wired through `GameTheme.finishTheLine`.

**Why:** The FinishTheLine PRD proposed a terracotta (~`#C4654E`), but Border Hop already owns `compassRose` (`#D4785A`) which is effectively the same warm terracotta. A deep plum reads as theatrical velvet-curtain — fits "spotlight on a quote" — while staying visually distinct from every other game's accent.

**Impact:**
- Do not reuse `compassRose` / `coralRed` / `brandOrange` for new warm-toned games — we're running out of warm hues and the Finish the Line / Border Hop pairing is already the closest collision.
- `GameTheme.finishTheLine.darkAccent` / `lightBackground` computed colors inherit from the plum automatically — no per-shade constants needed.

**Alternatives considered:** The PRD's terracotta (too close to Border Hop); a cooler navy (loses the "stage spotlight" warmth); reusing `softMauve` (already Conversation Starters).

---

## 2026-04-11 — Seeded agent memory with CLAUDE.md + AGENTS.md + DECISIONS.md [convention]

**What:** Adopted `AGENTS.md` as the single cross-tool source of truth for AI coding assistants. `CLAUDE.md` is a thin pointer that intentionally contains no rules of its own. `DECISIONS.md` (this file) is the running log.

**Why:** Prevents drift between CLAUDE.md and AGENTS.md as AI tooling conventions evolve. Also gives Claude Code a lightweight persistent memory without inventing a bespoke format.

**Impact:**
- All project-wide rules live in `AGENTS.md`.
- UI rules continue to live in `DESIGN_GUIDE.md` (already authoritative, already written for a Claude-Code audience).
- Append new architectural decisions to this file, newest at the top.

**Alternatives considered:** Duplicating rules into CLAUDE.md (rejected — two-file drift is inevitable). Putting rules in README.md (rejected — README is for humans discovering the project).

---

## Seed entries — things already true about this repo as of 2026-04-11

These are pre-existing conventions, captured so they're discoverable from one place. They are **not** new decisions made today.

### [convention] `GameRegistry.allGames()` is the single registration point

Every game must be added to `Features/GameHub/GameRegistry.swift` — this is the single most-forgotten step when adding a new game. If it's not in the registry, it does not appear in the hub regardless of how complete the game code is.

### [convention] Observation framework, not ObservableObject

View models use `@Observable` (iOS 17 Observation framework). Do not introduce `ObservableObject` / `@Published` for new view models.

### [convention] SwiftData, zero external dependencies

Persistence is SwiftData (`@Model`). There are no external SPM packages and none should be added without an explicit decision recorded here first.

### [gotcha] `Text("\(int)")` applies locale formatting

`Text("\(2019)")` renders as `"2,019"`. For years and raw integer displays, use `Text(verbatim: "\(n)")` or `Text(String(n))`. See `DESIGN_GUIDE.md` §9.4.

### [gotcha] Horizontal card pairs need `maxHeight: .infinity`, not fixed heights

When two cards sit side-by-side in an `HStack` (e.g., compact stepper pairs in Vibe Check setup), use `.frame(maxWidth: .infinity, maxHeight: .infinity)` so SwiftUI equalizes heights. Labels need `.lineLimit(1)` + `.minimumScaleFactor(0.75)` to prevent wrapping-induced uneven heights. See `DESIGN_GUIDE.md` §5.7.

### [gotcha] Keyboard-aware search screens must overlay, not push

Movie Chain and Casting Director have search fields. When the keyboard is up, results must **overlay** the middle content area rather than pushing it — otherwise the content zone collapses. Keep at least 2–3 result rows visible with keyboard up. See `DESIGN_GUIDE.md` §4.4 and §6.

### [convention] `.skeletonLoading()` and `GameSpinner`, never `ProgressView()`

Loading UI uses `.skeletonLoading()` for content-shaped placeholders, or `GameSpinner(color: <game accent>)` when there is no content shape. `ProgressView()` is banned.

### [convention] All design tokens flow through `AppTheme` / `GameTheme`

No raw `Color.blue`, no hardcoded padding numbers, no hardcoded corner radii, no `.font(.title)` in game views. See `DESIGN_GUIDE.md` §2, §3, §4, §9.5.
