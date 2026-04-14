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
