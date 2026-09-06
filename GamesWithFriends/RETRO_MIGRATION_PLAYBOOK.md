# Retro Migration Playbook (per-game)

> Distilled from the Conversation Starters pilot (phase 4, 2026-08-23).
> Read `ART_DIRECTION.md` first — this is the *how*, that is the *what*.
> A screen is fully migrated or untouched, never a blend (see ART_DIRECTION header).

## 0. Ground rules

- **Views only.** Never touch ViewModels, Models, Data, gesture thresholds,
  timer logic, haptics calls, or persistence. Before committing, run
  `git diff --stat` and confirm only view-layer files (+ `GameTheme.swift`,
  pbxproj, docs) changed.
- Keep every `accessibilityLabel`/`accessibilityHint`, every `.onChange`/
  `.onAppear` hook, every `withAnimation`/Reduce Motion branch, and Form/List
  mechanics exactly as found.
- Build after each screen; screenshot on iPhone 17 (`xcrun simctl`) and
  install on **all booted simulators by UDID** (installing to `booted` with
  two devices booted only hits one).

## 1. Create `<Game>Style.swift` in the game's Views folder

One enum, e.g. `ConversationStartersStyle`, holding:
- `static let accent` = the game's candy accent from ART_DIRECTION §3.2.
- Candy remaps for the game's *semantic* colors (difficulty ramps, category
  colors, status colors). Old palette → candy equivalents; every value must
  come from `AppTheme.Retro`.
- `chipTextColor(on:)` if any chip uses plum (§8: ink passes on every accent
  except plum → cream; cream/white body text passes ONLY on plum).

Register the new file in pbxproj (4 places: PBXBuildFile, PBXFileReference,
the game's Views group children, Sources phase). Copy the ID pattern of a
neighboring file; verify uniqueness with grep before writing.

## 2. Remap the game's `GameTheme` entry

Change only the `accentColor:` to the §3.2 candy value, with the comment
marking it retro-migrated. Safe because the hub reads
`AppTheme.Retro.accent(forGameID:)`, not GameTheme — but grep for other
cross-feature consumers of that GameTheme entry first.

## 3. Per-screen recipe

| Element | Treatment |
|---|---|
| Background | `GeometryReader { MotifGroundView(exclusions: [...]) }.ignoresSafeArea()`. Exclude the interactive content column and any dense header; the generator adds the 12pt clearance itself, so pass the *actual* content rects. Distinct `seed` per screen. No motifs behind forms/keyboards — for those use plain `AppTheme.Retro.ground`. |
| Screen header | Spot plate (`Circle().fill(panel)` + ink stroke + `RetroSpotIllustration(kind:)`) + game title in **Lilita One** (`heading(22)`) on an accent `retroPanel` with hard-shadow background rect and ±1° tilt. Never Shrikhand for game names (>8 chars, §4). Tagline in a `retroLozenge()`. |
| Setting/content cards | `.retroCard()` (replaces `cardSurface` + `clipShape` + soft `shadow`). Section labels: `Retro.Typography.cardTitle` + `panelText`. |
| Primary CTA | `RetroPrimaryButton(title:icon:accent:)`. No gradients ever. |
| Selection pills | `RetroCategoryPill` with the game accent (one game accent per screen; semantic variety belongs on chips inside cream cards). |
| Chips/badges | `Capsule().fill(semanticColor)` + ink stroke 2 + `chipTextColor(on:)`. |
| Progress/timer | Ink-on-cream `retroLozenge()`; urgent state text turns `Retro.tomato` (keep the trigger condition untouched). |
| Round nav buttons | Ink glyph, 60pt frame, `.retroPanel(accent, cornerRadius: 999)` + `.buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))`. Disabled: `panel` fill + `.opacity(0.4)`, same `.disabled` logic. |
| Steppers | 44pt circles, accent fill, ink stroke + bold ink `plus`/`minus` glyphs. |
| Sliders/Toggles/Pickers | Keep the system control, `.tint(accent)`. |
| Empty/celebration states | Spot plate + Lilita heading on accent panel (+1° tilt) + body lozenge + `RetroPrimaryButton`. Celebration accent: grass (cream display text ≥17pt is OK on grass). Never a naked SF hero (§9). |
| Forms (Settings sheets) | Keep `Form`; `.scrollContentBackground(.hidden)` + `ground` background, `.listRowBackground(Retro.panel)` per section, headers/footers `Retro.cocoa`, `.tint(accent)`, checkmarks/icons ink. |
| Lists | Keep `List`; `.listStyle(.plain)`, `.scrollContentBackground(.hidden)`, ground behind, row content in `.retroCard()` with `.listRowBackground(Color.clear)` + `.listRowSeparator(.hidden)`. |
| Toolbar | Functional SF glyphs only, ink (`.tint(Retro.ink)` on the nav content). |

## 4. Gotchas found in the pilot (do not rediscover these)

1. **Buttons in List rows:** custom-label buttons default to a style where a
   row tap fires EVERY button. Add `.buttonStyle(.plain)` to each.
2. **Presenting UIKit sheets from a SwiftUI sheet:** walk
   `presentedViewController` to the top before `present(...)` — presenting
   from the root VC fails silently.
3. **Card press physics:** interactive cards/buttons get their shadow from
   `RetroRaisedButtonStyle`; non-interactive cards use `.retroCard()`'s
   static shadow. Don't stack both.
4. **`.retroCard()` already pads** (`Spacing.md`) — drop the old `.padding()`.
5. Motif exclusions: sparkles reach 0.8× their size beyond their center; the
   layout keeps them on-screen, but exclusion rects must cover the real
   interactive frame or spikes peek from behind panels.
6. Vibe/status dot meters: unfilled = `ink.opacity(0.15)` + 1pt ink stroke
   (Rule 1 — outlines on everything).

## 5. Verification checklist (run on-simulator, per game)

- [ ] Every setup control operates (steppers clamp, sliders update copy,
      pills toggle, CTA consumes the filters).
- [ ] Core loop: advance/back, disabled states, end-of-deck/round state,
      reset.
- [ ] Persistence actions (save/star/score) round-trip to their list/screen.
- [ ] Timers: enable, preset change, countdown, urgent color, backgrounding
      pause (scene phase).
- [ ] Share/system sheets open and dismiss.
- [ ] Screenshots: setup, in-game, end state, sheets — check against the six
      rules (§2) and the §8 contrast table.
- [ ] Full test suite green; `git diff --stat` shows view-layer scope only.

## 6. Wrap-up

Append a DECISIONS.md entry (what migrated, deviations, gotchas), update the
game's row in the tracking table below, commit per screen with
`feat(<game>):` prefixes.

## 7. Phase-4 tracking

| Game | Accent | Spot | Status |
|---|---|---|---|
| Conversation Starters | bubblegum | speechBubbles | ✅ 2026-08-23 (pilot) |
| Country Letter Challenge | grass | globe | ✅ 2026-08-23 |
| Name 5 | lilac | bubbleFive | ✅ 2026-08-23 |
| Border Blitz | poolBlue | borderMap | ✅ 2026-08-23 |
| Movie Chain | tomato | filmFrame | ✅ 2026-08-23 (Fable-direct) |
| Casting Director | tangerine | starFace | ✅ 2026-08-23 (Fable-direct) |
| VibeCheck | berry | heart | ✅ 2026-08-23 |
| Border Hop | cornflower | hopMap | ✅ 2026-08-23 |
| Finish the Line | plum | quoteBubble | ✅ 2026-08-23 |
