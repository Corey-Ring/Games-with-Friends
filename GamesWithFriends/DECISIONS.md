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
