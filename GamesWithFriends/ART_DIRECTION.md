# Games With Friends — Art Direction: Retro Maximalist

> **Status: adopted 2026-08-22.** This document is the visual north star for the app's re-skin.
> It was chosen from three explored intensities ("Option C — Full Maximalist") on the
> [Retro Aesthetic Explorer canvas](https://claude.ai/code/artifact/3971b3d8-bb93-4d2e-8d79-bbba81408593).
> Reference photography lives in [`docs/design/inspiration/`](../docs/design/inspiration/README.md).
>
> **Relationship to `DESIGN_GUIDE.md`:** the design guide remains the source of truth for
> *mechanics* — spacing grid, Dynamic Type, haptics, keyboard handling, Reduce Motion,
> component checklist. This document supersedes its *aesthetic* sections (§1 Philosophy,
> §2 Color, §3 display typography, §4.2–4.3 shape/shadow, §6 Illustration, §10 Do/Don't)
> as screens migrate. A screen is either fully migrated (this doc governs) or not yet
> touched (old guide governs) — never a blend.

---

## 1. North Star

The app should feel like **candy packaging from a 1970s corner store**: the Maeve
chocolate box, a Fishwife tin, a hand-painted shop window. Dense, joyful, saturated,
hand-drawn. Every screen is a little package you get to open. The UI does not recede —
it *is* the fun. Confidence comes from craft: thick clean linework and disciplined
color, not from minimal restraint.

One test for any new screen: **would it look at home printed on a candy box?**

---

## 2. The Six Rules (non-negotiable)

These are the style DNA. Every migrated screen must satisfy all six.

1. **Ink outlines on everything.** Every shape, panel, illustration and display
   letterform carries a uniform Ink outline (2–3 pt at 1x; use `AppTheme.Retro.strokeWidth`).
   Nothing floats without a line. The outline is what unifies the chaos.

2. **Flat fills, hard shadows.** No gradients. No blurred/soft shadows. Color is
   applied in flat saturated blocks; depth comes from **hard offset shadows**
   (`x: 5, y: 5, blur: 0`, Ink) like misregistered print. Soft `rgba` drop shadows are
   retired on migrated screens.

3. **Fill every gap.** Backgrounds are populated, not empty: daisies, sparkles, dots,
   hearts, squiggles occupy negative space. Density rules in §7 — motifs live on
   *grounds*, never inside text panels or on top of interactive controls.

4. **Chunky framed lettering.** Display type is fat and treated like a physical object:
   cream/white letterforms with a colored hard offset, locked inside a framed panel or
   lozenge. Display type never sits naked on the background.

5. **Banners & framed panels.** Information lives in devices: lozenge pills, ribbon
   banners, double-ruled frames, cream panels. This is also the accessibility strategy —
   body text always sits on a cream/white panel, never directly on a saturated accent
   (§8).

6. **Everything has a face.** Illustrations get dot-eyes and a smile where it makes
   sense (globes, stars, suns, bubbles). Mascots carry the emotional beats — celebration,
   failure, waiting — that chrome used to mumble through.

---

## 3. Color System

### 3.1 The Candy Palette

Flat, saturated, warm. Proposed SwiftUI tokens under `AppTheme.Retro` (implementation
adds these; raw hexes below are canonical).

| Token | Hex | Role |
|---|---|---|
| `mustard` | `#F2B417` | Primary ground — the hub's page background |
| `cream` | `#FBF2E0` | Panels, lozenges, illustration plates; the "paper" color |
| `ink` | `#1B1B1B` | Outlines, primary text, hard shadows |
| `cocoa` | `#55351D` | Secondary text on cream, dark-mode ground base |
| `bubblegum` | `#F387B8` | Accent |
| `tomato` | `#E8442E` | Accent, error/energy |
| `tangerine` | `#F07C24` | Accent |
| `cornflower` | `#6C9BD2` | Accent |
| `poolBlue` | `#5BC0DF` | Accent |
| `grass` | `#57A34F` | Accent, success |
| `lilac` | `#A08BE0` | Accent |
| `berry` | `#C64B7E` | Accent (from the Fishwife magenta box) |
| `plum` | `#8E4585` | Accent (from the Fishwife purple box) |

Pure gray, blue-gray, and the old soft pastels are retired on migrated screens.
`warmLinen` survives only on unmigrated screens.

### 3.2 Per-Game Accent Remap

Game identity colors move from the old muted set to the candy palette. Same
`GameTheme` API, new values:

Assignments follow the adopted Option C artboard; Vibe Check, Border Hop and Finish
the Line (below the fold there) take the remaining distinct accents. Mustard is never
a game accent — it is the ground.

| Game | Old | New |
|---|---|---|
| Conversation Starters | Soft Mauve `#C48EB0` | Bubblegum `#F387B8` |
| Country Letter Challenge | Forest Green `#6DAE6D` | Grass `#57A34F` |
| Name 5 | Electric Indigo `#7B6CF6` | Lilac `#A08BE0` |
| Border Blitz | Teal Green `#4FBFA5` | Pool Blue `#5BC0DF` |
| Movie Chain | Warm Gold `#D4943A` | Tomato `#E8442E` |
| Casting Director | Brand Orange `#FF6B35` | Tangerine `#F07C24` |
| Vibe Check | Coral Red `#E8533F` | Berry `#C64B7E` |
| Border Hop | Compass Rose `#D4785A` | Cornflower `#6C9BD2` |
| Finish the Line | Spotlight Plum `#8E3B5D` | Plum `#8E4585` |

Rule carried forward from the old guide: one game's accent per screen. On the hub,
each card wears its own accent — that juxtaposition *is* the shelf-of-packages look,
and it is the one sanctioned place multiple accents meet. Separate adjacent accents
with Ink outlines, never bare edges.

### 3.3 Dark Mode

Dark mode is "the shop at night," not a desaturated retreat:

- Ground: deep cocoa `#2A1A10` (token `Retro.darkGround`), replacing mustard.
- Cream panels become `#3A2A1C` with cream text; accents stay at **full saturation** —
  they pop harder on the dark ground, which is correct.
- Hard shadows stay Ink; add a 1 pt cream outer rule on cards if separation suffers.
- Motif layer drops to ~60% density and uses accents only (no cream motifs).

---

## 4. Typography

| Role | Face | Usage |
|---|---|---|
| Logo lockups | **Shrikhand** | App/game title lockups only. Never body, never labels. Always white/cream fill + colored hard offset (`text-shadow` style), inside a framed panel. |
| Headings, card titles, buttons, pills | **Lilita One** | The workhorse display face. Ink on light fills; cream on dark fills. |
| Body, metadata, all reading text | **SF Pro** (system) | Unchanged from the design guide. Dynamic Type styles, weights per old §3. |

- Both display faces are Google Fonts under the SIL Open Font License — bundle them in
  the app target and register in Info.plist. Verify the OFL files ship with the fonts.
- Display faces must scale with Dynamic Type via `@ScaledMetric` or
  `.custom(_:size:relativeTo:)`. They are exempt from the "SF only" rule of the old
  guide, which this section supersedes.
- Maximum stack on one screen: one Shrikhand lockup, Lilita One headings, SF body.
  Never Shrikhand for more than ~8 characters at a time.
- ALL CAPS is allowed **only** in Lilita One pill labels (the old caption-size rule
  relaxes to include the "presents"-style banner pill).

---

## 5. Shape Language

| Property | Value |
|---|---|
| Outline | 2.5–3 pt Ink, uniform weight, rounded joins |
| Corner radius | Cards 18 pt, pills full-round (999), inner elements 10–12 pt |
| Shadow | Hard offset: `5pt x, 5pt y, 0 blur`, Ink. Interactive press state: shadow collapses to `2,2` and the element translates `+3,+3` (feels like pressing a physical button) |
| Rotation jitter | Cards and lockup panels may rotate ±0.5–1.5°, alternating direction down a list. Never on body text, never more than 2°. |
| Card anatomy (hub) | Accent-filled card, Ink outline, hard shadow; game name in a cream lozenge (Ink outline); description below it; illustration in a 66 pt cream circle plate (Ink outline) on the right |
| Touch targets | ≥ 44 pt, unchanged |

The `.gameCard()` modifier gets a migrated implementation (`.retroCard(accent:)`);
`.pressable()` gains the shadow-collapse behavior. Shared components migrate once,
in `Theme/` — games never hand-roll these.

---

## 6. Illustration & Iconography

- **Spot illustrations replace SF Symbols** everywhere a symbol was decorative: hub
  cards, empty states, results, celebration moments. Style: flat candy fills, 3 pt Ink
  outlines, rounded joins, faces per Rule 6, one sparkle/star garnish maximum per spot.
- SF Symbols survive only as *functional* glyphs: navigation chevrons, close ✕,
  settings gear, share — always Ink, 20–24 pt.
- Each game owns a spot illustration family keyed to its accent (the canvas artboards
  contain the first nine as SVG references).
- Illustrations are allowed to bleed past panel edges by up to ~8 pt (a paw over the
  frame, Maeve-bear style) — this is the one sanctioned overlap.

## 7. Motif Library & Density

Approved motifs: **daisy** (two-ring), **4-point sparkle**, **dot**, **squiggle**,
**heart**, **scallop edge**, **ribbon banner**.

- Grounds (page backgrounds, hero areas): 1 motif per ~90×90 pt cell, mixed sizes
  (4–18 pt), colors drawn from cream + 3 accents. Hand-placed or seeded-random with a
  fixed seed — never visibly gridded.
- Panels and cards: motifs only as deliberate garnish (a sparkle at a corner), never
  behind text.
- Interactive areas (inputs, keyboards, timers): no motifs within 12 pt.
- Motif layers are decorative: `accessibilityHidden(true)`, excluded from hit testing,
  and static when Reduce Motion is on (they may gently drift/twinkle otherwise —
  see design guide §7.4, which still governs).

---

## 8. Accessibility Guardrails (hard requirements)

The maximalist look must not cost legibility. These are checked per screen:

- **Body text never sits on a saturated accent.** It sits on cream/white panels
  (Rule 5). Ink on cream ≈ 13:1 — always safe.
- On accent fills: Ink text passes on mustard, bubblegum, poolBlue, cream, tangerine.
  On tomato, grass, lilac, cornflower, berry, white/cream text is **display-only**
  (≥ 17 pt Lilita One); body copy on those accents must move into a cream lozenge.
  Plum is the one accent dark enough for white body text (≈ 6:1). When in doubt,
  panel it.
- WCAG AA (4.5:1 body / 3:1 large) still binds — the pre-launch review already caught
  white-on-accent failures once; the lozenge pattern exists to make them structurally
  impossible.
- Dynamic Type, VoiceOver labels, Reduce Motion, 44 pt targets: all rules from
  `DESIGN_GUIDE.md` §3/§7/§9 remain in force unchanged.

---

## 9. What We Leave Behind

On migrated screens these are defects, not options:

- Soft blurred drop shadows, gradients of any kind
- Empty warm-linen fields as "breathing room" (populate or panel it)
- SF Symbols as hero/decorative art; 12%-opacity tint circles
- Outline-less shapes; naked text on accent fills
- Centered timid headers; whisper-gray metadata on busy grounds
- Exclamation-mark tagline energy substituting for actual visual energy —
  the *drawing* is exuberant so the *copy* can stay dry

---

## 10. Migration Path

Phased, screen-by-screen; each phase ships a coherent look:

1. **Tokens + shared components** — add `AppTheme.Retro`, bundle fonts, implement
   `.retroCard`, retro `PrimaryButton`/`CategoryPill`/pressable, motif-ground view.
2. **Hub** — the storefront; establishes the lockup and card language (Option C
   artboard is the spec).
3. **Game accent remap** (§3.2) — one commit, all `GameTheme` values.
4. **Per-game screens** — one game at a time, setup → in-game → results, using the
   shared components only.
5. **Dark mode + accessibility audit pass** per phase, not at the end.

Screens keep the old guide's look until their phase lands (see the status note at top).

---

## 11. Reference Material

- `docs/design/inspiration/` — the source photographs with per-photo take/ignore notes.
- [Retro Aesthetic Explorer canvas](https://claude.ai/code/artifact/3971b3d8-bb93-4d2e-8d79-bbba81408593)
  — Style DNA board, current-app baseline, and the three explored intensities.
  Option C is the adopted direction; A and B are kept as the record of what was
  considered. The "Party games for your table" tagline on the C artboard is
  placeholder copy, not adopted.
