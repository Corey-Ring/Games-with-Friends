# Games With Friends — UI & Aesthetics Design Guide

> **For Claude Code Implementation**
> This document defines the visual identity, component patterns, and aesthetic principles for the Games With Friends app. Use this as the single source of truth when implementing or modifying any UI.

---

## 1. Design Philosophy

### Core Principle

> Warm minimalism with purposeful color. Every screen should feel inviting, clean, and alive — like a well-designed living room, not a sterile dashboard. The UI recedes so gameplay takes center stage.

### Design Pillars

**Warm, Not Cold.** Use off-white and cream backgrounds instead of pure white. Rounded shapes over sharp edges. Organic illustrations over flat icons. The app should feel like it was made by humans for humans.

**Clean, Not Sterile.** Generous whitespace and clear hierarchy, but punctuated by bold pops of saturated color. Each game module owns a distinct accent color that makes it immediately recognizable.

**Playful, Not Childish.** Illustrations and color convey energy and fun. Typography stays grounded and readable. Micro-interactions feel polished, not gimmicky. The vibe is confident and inviting.

**Card-Centric Layout.** Content lives in well-defined cards with generous padding, soft shadows, and large corner radii. Cards are the fundamental building block for navigation, game selection, and in-game content.

---

## 2. Color System

The palette is anchored by a warm orange primary with a family of saturated accent colors. Every color has a defined role. **Never use raw SwiftUI system colors (Color.blue, Color.purple, etc.) — always use AppTheme or GameTheme tokens.**

### 2.1 Primary & Background

| Token Name | Hex | SwiftUI Token | Usage |
|---|---|---|---|
| Brand Orange | `#FF6B35` | `AppTheme.brandOrange` | Primary CTAs, active tab indicator |
| Deep Charcoal | `#1C1C1E` | `AppTheme.deepCharcoal` | Primary text, headings |
| Warm Linen | `#F5F3F0` | `AppTheme.warmLinen` | Page background (never use pure gray or blue-gray) |
| Pure White | `#FFFFFF` | `AppTheme.pureWhite` | Card surfaces only (never as page background) |
| Medium Gray | `#636366` | `AppTheme.mediumGray` | Secondary text, metadata, captions |

### 2.2 Game Accent Colors

Each game module is assigned a unique accent color. This color appears in that game's cards, headers, buttons, and illustrations.

| Color Name | Hex | SwiftUI Token | Category |
|---|---|---|---|
| Coral Red | `#E8533F` | `AppTheme.coralRed` | High-energy games |
| Warm Gold | `#D4943A` | `AppTheme.warmGold` | Knowledge games |
| Soft Mauve | `#C48EB0` | `AppTheme.softMauve` | Social/chill games |
| Teal Green | `#4FBFA5` | `AppTheme.tealGreen` | Strategy games |
| Sky Blue | `#5B9BD5` | `AppTheme.skyBlue` | Travel/exploration games |
| Forest Green | `#6DAE6D` | `AppTheme.forestGreen` | Geography games |
| Electric Indigo | `#7B6CF6` | `AppTheme.electricIndigo` | Fast-paced challenge games |

### 2.3 Game-to-Color Mapping

| Game Module | Accent Color | GameTheme Token |
|---|---|---|
| Conversation Starters | Soft Mauve (`#C48EB0`) | `GameTheme.conversationStarters` |
| Border Blitz | Teal Green (`#4FBFA5`) | `GameTheme.borderBlitz` |
| Movie Chain | Warm Gold (`#D4943A`) | `GameTheme.movieChain` |
| Vibe Check | Coral Red (`#E8533F`) | `GameTheme.vibeCheck` |
| Casting Director | Brand Orange (`#FF6B35`) | `GameTheme.castingDirector` |
| License Plate Game | Sky Blue (`#5B9BD5`) | `GameTheme.licensePlate` |
| Country Letter Challenge | Forest Green (`#6DAE6D`) | `GameTheme.countryLetter` |
| Name 5 | Electric Indigo (`#7B6CF6`) | `GameTheme.name5` |

### 2.4 Semantic Colors

These tokens express meaning, not brand. Use them for feedback states throughout any game.

| Token Name | Hex | SwiftUI Token | Usage |
|---|---|---|---|
| Success Green | `#34C759` | `AppTheme.success` | Correct answers, positive feedback |
| Error Red | `#FF3B30` | `AppTheme.error` | Wrong answers, validation errors |
| Warning Amber | `#FF9500` | `AppTheme.warning` | Warnings, caution states |
| Medal Gold | `#FFD700` | `AppTheme.medalGold` | 1st place / gold ranking |
| Medal Silver | `#C0C0C0` | `AppTheme.medalSilver` | 2nd place / silver ranking |
| Medal Bronze | `#CD7F32` | `AppTheme.medalBronze` | 3rd place / bronze ranking |
| Overlay Black | `rgba(0,0,0,0.4)` | `AppTheme.overlay` | Modal/sheet overlays |

### 2.5 Color Usage Rules

- Background is always Warm Linen (`#F5F3F0`) or white — never pure gray or blue-gray
- Cards use white (`#FFFFFF`) surfaces with subtle drop shadows
- Each game's accent color is used at maximum 30% saturation on its screens; the rest is neutral
- Text is always Deep Charcoal (`#1C1C1E`) for headings and Medium Gray (`#636366`) for body/metadata
- Accent colors appear in: card thumbnails, illustrations, category pills, active tab indicators, and CTAs
- Never place two accent colors side-by-side at full saturation — always separate with white or linen space
- **Never use raw `Color.blue`, `Color.purple`, `Color.green`, etc.** — always reference `AppTheme` or `GameTheme` tokens
- **Gradients**: If a view uses gradient backgrounds, build them from the game's `GameTheme` accent color at varying opacities (e.g., `accentColor.opacity(0.3)` to `accentColor.opacity(0.6)`). Never mix accent colors from different games in a single gradient.
- **UIKit system colors**: `Color(.systemBackground)`, `Color(.systemGray5)`, `Color(.systemGray6)` are acceptable for adaptive surfaces that need to respond to iOS dark/light mode automatically. However, prefer `AppTheme` tokens where possible: use `AppTheme.pureWhite` / `AppTheme.darkCard` (via `.gameCard()`) for card surfaces, and `AppTheme.warmLinen` / `AppTheme.darkBackground` (via `WarmLinenBackground()`) for page backgrounds. Reserve `Color(.systemBackground)` only for views that sit within system-level containers (e.g., sheet content, search bars) where the warm linen look would feel out of place.

### 2.6 Dark Mode Adaptation

| Token Name | Hex | SwiftUI Token | Usage |
|---|---|---|---|
| Dark Background | `#1C1C1E` | `AppTheme.darkBackground` | Base surface |
| Dark Card | `#2C2C2E` | `AppTheme.darkCard` | Elevated cards |
| Dark Elevated | `#3A3A3C` | `AppTheme.darkElevated` | Modals, sheets |
| Dark Muted Text | `#AEAEB2` | `AppTheme.darkMutedText` | Secondary text |

- Accent colors remain the same but reduce opacity to 85% on dark backgrounds (use `GameTheme.darkAccent`)
- Illustrations use slightly muted/desaturated variants
- Card shadows become lighter glows (`rgba(255,255,255,0.04)`) instead of dark drops
- All views **must** use `@Environment(\.colorScheme)` to switch between light/dark token sets

---

## 3. Typography

Typography should feel confident and approachable. Use the iOS system font (SF Pro) via SwiftUI's Dynamic Type styles for native feel and accessibility.

### 3.1 Type Scale

| Role | SwiftUI Token | Mapping |
|---|---|---|
| Hero / Screen Title | `AppTheme.Typography.hero` | `.largeTitle.bold()` (~34pt Bold) |
| Screen Title (smaller) | `AppTheme.Typography.screenTitle` | `.title.bold()` (~28pt Bold) |
| Section Header | `AppTheme.Typography.sectionHeader` | `.title2.bold()` (~22pt Bold) |
| Subsection Header | `AppTheme.Typography.subsectionHeader` | `.title3` (~20pt Regular) |
| Card Title | `AppTheme.Typography.cardTitle` | `.headline` (~17pt Semibold) |
| Body Text | `AppTheme.Typography.body` | `.body` (~15pt Regular) |
| Detail Text | `AppTheme.Typography.detail` | `.callout` (~16pt Regular) |
| Secondary Text | `AppTheme.Typography.secondary` | `.subheadline` (~15pt Regular) |
| Caption / Metadata | `AppTheme.Typography.caption` | `.caption` (~12pt Regular) |
| Footnote | `AppTheme.Typography.footnote` | `.footnote` (~13pt Regular) |
| Button Label | `AppTheme.Typography.buttonLabel` | `.headline` (~17pt Semibold, centered) |
| Tab Bar Label | `AppTheme.Typography.tabLabel` | `.caption2` (~10pt Medium) |
| Pill / Tag Label | `AppTheme.Typography.pillLabel` | `.caption.weight(.semibold)` (~12pt Semibold) |

> **Note**: We use Dynamic Type aliases rather than fixed point sizes. This ensures full accessibility support for users who scale text.

### 3.2 Display-Size Typography (Decorative Icons & Numbers)

Some game views use very large font sizes for decorative SF Symbol icons (e.g., hero illustrations on setup/results screens) or oversized score numbers. These are **exempt** from the standard type scale because they serve as visual focal points, not readable text.

**Allowed pattern** for display-size elements:

```swift
.font(.system(size: 60))              // Hero icons on setup/empty screens
.font(.system(size: 48, weight: .bold, design: .rounded))  // Large score numbers
.font(.system(size: 80))              // Full-screen celebration icons
```

**Rules for display-size usage:**
- Only use `.system(size:)` for decorative icons sized 36pt+ or display score numbers
- Prefer `.design(.rounded)` for score/number displays to match the playful aesthetic
- Never use `.system(size:)` for body text, labels, captions, or any content that should scale with Dynamic Type
- If an element needs to be accessible, use `@ScaledMetric` to make the display size respond to Dynamic Type preferences

### 3.3 Typography Rules

- **Always use `AppTheme.Typography.*` tokens** — never use raw `.font(.title)`, `.font(.headline)`, `.font(.caption)` directly. The only exception is `.font(.system(size:))` for display-size decorative elements as described in Section 3.2.
- Screen titles are always left-aligned, never centered
- Maximum two font weights per screen: Bold for headings + Regular for body. Semibold only for card titles and buttons
- Line height is 1.4x font size for body text, 1.2x for headings
- Never use ALL CAPS except for very small pill labels (caption size or below)
- Color contrast: all text must meet WCAG AA (4.5:1 for body, 3:1 for large text)
- Metadata and secondary info uses `AppTheme.mediumGray` — never a lighter shade

---

## 4. Spatial System & Layout

All spacing is based on an 8pt grid. Consistent spacing creates rhythm and reduces cognitive load during fast-paced party games. **Always use `AppTheme.Spacing.*` tokens — never hardcode numeric padding values.**

### 4.1 Spacing Scale

| Token | Value | SwiftUI Token | Usage |
|---|---|---|---|
| xs | 4pt | `AppTheme.Spacing.xs` | Icon-to-label gaps, inner pill padding |
| sm | 8pt | `AppTheme.Spacing.sm` | Between metadata items, compact card padding |
| md | 16pt | `AppTheme.Spacing.md` | Standard card internal padding, element spacing |
| lg | 24pt | `AppTheme.Spacing.lg` | Section gaps, card-to-card vertical spacing |
| xl | 32pt | `AppTheme.Spacing.xl` | Major section separation |
| 2xl | 48pt | `AppTheme.Spacing.xxl` | Screen top safe area + title padding |

Values that fall between tokens (e.g., 10pt, 12pt, 14pt, 20pt) should generally snap to the nearest token. However, certain component-internal spacing (e.g., vertical padding inside pills, tight gaps in compact layouts) may use intermediate values where snapping to a token would look wrong. In these cases, hardcoded values are acceptable **only inside shared components defined in `Theme/`** — never in game views. If a between-token value appears in more than one game view, it should be promoted to a new token.

### 4.2 Corner Radius

| Token | Value | SwiftUI Token | Usage |
|---|---|---|---|
| small | 8pt | `AppTheme.Radius.small` | Small internal elements |
| medium | 12pt | `AppTheme.Radius.medium` | Inner elements like thumbnails, pills |
| card | 16pt | `AppTheme.Radius.card` | All cards |
| large | 20pt | `AppTheme.Radius.large` | Hero overlapping cards, modals |

**Never use `cornerRadius()` with raw numbers.** Always use `AppTheme.Radius.*`.

### 4.3 Card Specifications

| Property | Value | Token |
|---|---|---|
| Corner Radius | 16pt | `AppTheme.Radius.card` |
| Internal Padding | 16pt all sides | `AppTheme.Spacing.md` |
| Shadow (Light) | 0 2pt 8pt rgba(0,0,0,0.08) | `AppTheme.Shadow.card*` |
| Shadow (Dark) | 0 2pt 8pt rgba(0,0,0,0.24), glow rgba(255,255,255,0.04) | Check `colorScheme` |
| Card Gap (vertical list) | 16pt | `AppTheme.Spacing.md` |
| Card Gap (horizontal scroll) | 12pt | — |
| Min Touch Target | 44pt × 44pt | Always enforce |
| Min Card Height | 120pt | Hub game cards |

Use the `.gameCard()` modifier to apply standard card styling (white background, 16pt radius, standard shadow, 16pt padding).

### 4.4 Layout Patterns

**Home / Hub Screen**: Full-width scrollable feed of cards. Each game module gets a large card (minimum 120pt tall) with: left-aligned title + subtitle, right-aligned illustration or thumbnail, bottom-aligned metadata row. Cards fill horizontal width with 16pt side margins.

**Detail / Content Screen**: Full-bleed hero area (illustration or color block) at top, followed by white/linen card with rounded top corners (`AppTheme.Radius.large`) that overlaps the hero by 16pt. Content inside this card uses the standard type scale and spacing.

**List Screen**: Left-aligned thumbnail (56pt circle or 56pt rounded square), text block (title + subtitle + metadata), right chevron. Rows separated by 1pt hairline in Warm Linen color.

---

## 5. Component Library

Standardized components ensure visual consistency across all game modules. Every component is implemented as a reusable SwiftUI view. **Always use shared components — never reimplement buttons, pills, or cards locally.**

### 5.1 Navigation Bar

| Property | Specification |
|---|---|
| Style | Large title, inline on scroll (standard iOS behavior) |
| Background | Transparent, blurs to linen on scroll |
| Title Font | `AppTheme.Typography.hero` |
| Back Button | SF Symbol `chevron.left`, tinted to accent color of current game |
| Right Actions | Max 2 icons, 24pt, tinted to charcoal |

### 5.2 Game Card (`HubGameCard` + `.gameCard()` modifier)

- Left Column (~60% width): Title (`AppTheme.Typography.cardTitle`), Description (`AppTheme.Typography.caption`, `AppTheme.mediumGray`), Metadata row
- Right Column (~40% width): 56pt accent-tinted circle with SF Symbol icon
- Full card is tappable with `.pressable()` modifier (0.97 scale, spring animation, light haptic)
- Background: white, Corner radius: 16pt, Shadow: standard card shadow
- Min height: 120pt
- Optional status badge: colored dot (8pt, top-left) indicating live/new/updated

### 5.3 Category Pill (`CategoryPill` from SharedComponents.swift)

| Property | Specification |
|---|---|
| Shape | Rounded rectangle, `AppTheme.Radius.medium` |
| Background | Solid accent color when selected, 12% opacity when unselected |
| Text | White (selected) or accent color (unselected), `AppTheme.Typography.pillLabel` |
| Press State | `.pressable()` modifier |
| Layout | 2-column grid, equal width, `AppTheme.Spacing.medium` gaps |

**Always use `CategoryPill`** — never create custom chip/pill implementations in individual game views.

### 5.4 Content Row (List Item)

| Property | Specification |
|---|---|
| Thumbnail | 56pt circle or rounded square (`AppTheme.Radius.medium`) |
| Title | `AppTheme.Typography.cardTitle`, single line, truncate with ellipsis |
| Subtitle | `AppTheme.Typography.caption`, `AppTheme.mediumGray`, single line |
| Accessory | Chevron right, 14pt, `#C7C7CC` |
| Row Height | 72pt minimum |
| Separator | 1pt, Warm Linen color, inset 72pt from left edge |
| Tap State | Background dims to `AppTheme.warmLinen` |

### 5.5 Buttons (`PrimaryButton` / `SecondaryButton` from SharedComponents.swift)

**Primary Button**: `AppTheme.brandOrange` background, white text, `AppTheme.Typography.buttonLabel`, 14pt corner radius, 52pt height (scaled via `@ScaledMetric`), full-width.

**Secondary Button**: Transparent background, 1.5pt `AppTheme.brandOrange` border, orange text, same typography and sizing.

Both include `.pressable()` with haptic feedback built in. **Always use these shared components — never build custom buttons.**

### 5.6 Game Spinner (`GameSpinner` from SharedComponents.swift)

Replaces `ProgressView()` for loading states that need an indeterminate indicator (e.g., database decompression, network loading). Takes a `color` parameter — pass the current game's accent color.

```swift
GameSpinner(color: GameTheme.castingDirector.accentColor)
```

Use `.skeletonLoading()` for content placeholder shimmer. Use `GameSpinner` only when there's no known content shape to preview.

### 5.6 Accent-Aware Buttons

When a button should use the current game's accent color instead of Brand Orange, pass the game's accent color. Consider adding `AccentPrimaryButton` and `AccentSecondaryButton` variants that accept a color parameter.

---

## 6. Illustrations & Visual Language

### Illustration Style Rules

- Use abstract, organic shapes as backgrounds for card illustrations (blobs, waves, soft geometry)
- Color fills are flat and saturated — no gradients within a single shape (gradients only between shapes)
- Illustrations live within rounded containers and never bleed past card edges
- Each game's illustration family uses that game's accent color as the dominant hue

### Iconography

- Use SF Symbols exclusively for system icons (navigation, actions, tab bar)
- Prefer filled variants for active/selected states, outline for inactive
- Icon size: 24pt for navigation, 20pt for inline, 28pt for empty states
- Icon color: `AppTheme.deepCharcoal` for primary, `AppTheme.mediumGray` for secondary, game accent for interactive

### Empty States & Loading

- Empty states use a centered illustration (max 160pt tall) + headline + subhead + optional CTA button
- **Loading states use skeleton shimmer animation** (`.skeletonLoading()` modifier) on placeholder shapes — **never use `ProgressView()` spinners**
- Skeleton shapes match the actual content layout: rectangle for text lines, circle for avatars, rounded rect for cards

---

## 7. Animation & Micro-Interactions

Animations should feel responsive and natural. They communicate state changes and provide satisfying feedback.

### 7.1 Timing Standards

| Interaction | Duration & Curve | Token |
|---|---|---|
| Button press scale | 200ms, spring(response: 0.3, dampingFraction: 0.6) | `AppTheme.Animation.buttonPress` |
| Card tap feedback | 150ms, spring(response: 0.3, dampingFraction: 0.7) | `AppTheme.Animation.cardTap` |
| Screen transition (push) | 350ms, default iOS spring | — |
| Modal present (sheet) | 400ms, spring with damping | — |
| Tab switch content | 200ms, easeInOut | — |
| Correct answer celebration | 600ms, spring(response: 0.5, dampingFraction: 0.5) | — |
| Score counter increment | 300ms per digit, easeOut | `AppTheme.Animation.scoreCounter` |
| Card enter (list appear) | 300ms stagger, 50ms delay per item | `AppTheme.Animation.cardEnter*` |

### 7.2 Haptic Feedback

| Event | Haptic Type | HapticManager Call |
|---|---|---|
| Correct guess | `.success` (UINotificationFeedbackGenerator) | `HapticManager.success()` |
| Wrong guess | `.error` (UINotificationFeedbackGenerator) | `HapticManager.error()` |
| Button tap | `.light` (UIImpactFeedbackGenerator) | `HapticManager.light()` |
| Game start countdown | `.rigid` per tick | — |
| Score reveal / milestone | `.heavy` + custom pattern | `HapticManager.heavy()` |
| Pass-and-play handoff | `.medium` double-tap pattern | `HapticManager.medium()` |
| Selection change | selection feedback | `HapticManager.selection()` |

**Every interactive element must have haptic feedback.** Use `.pressable()` for buttons (includes light haptic automatically). Add explicit `HapticManager` calls for game-specific moments.

### 7.3 Key Animation Moments

- **Game hub card entrance**: cards slide up with staggered delay (50ms between each), use `.staggeredAppear(index:)` modifier
- **Score reveal**: numbers count up from 0 with easeOut, paired with accent color confetti for perfect scores
- **Timer**: smooth circular progress with color shift from accent to `AppTheme.error` in final 25%
- **Correct answer**: card scales to 1.05 briefly then settles, paired with success checkmark that fades in
- **Hint reveal**: letters animate in individually from left with 30ms stagger, subtle bounce

### 7.4 Accessibility: Reduce Motion

All animations must check `@Environment(\.accessibilityReduceMotion)` and degrade gracefully:
- When Reduce Motion is on, skip scale/slide/bounce animations
- Content should appear instantly (opacity 1, no offset)
- Haptic feedback still fires (it's not visual motion)

---

## 8. Screen-by-Screen Specifications

### 8.1 Game Hub (Home Screen)

- Background: `WarmLinenBackground()`
- Header: "Games", `AppTheme.Typography.hero`, left-aligned, `AppTheme.Spacing.xxl` top padding
- Layout: Vertical scroll of game cards, full-width minus `AppTheme.Spacing.md` side margins
- Each card follows `HubGameCard` anatomy with `.gameCard()` + `.pressable()` + `.staggeredAppear(index:)`
- Optional: Horizontal pill row at top for filtering using `CategoryPill`

### 8.2 Game Detail / Lobby Screen

- Hero section: full-width color block using `GameTheme.*.accentColor`, centered illustration (200pt max height)
- Overlapping white card with `AppTheme.Radius.large` top corners
- Card content: title (`AppTheme.Typography.sectionHeader`), description (`AppTheme.Typography.body`), player count (pill badge), estimated time (pill badge)
- CTA: `PrimaryButton` ("Start Game") pinned above safe area
- Settings: optional collapsible section

### 8.3 In-Game Screen

- Minimal chrome: thin top bar with game name (small, centered) + close (X) button + score
- Content area fills remaining space
- Background: `GameBackground(gameTheme:)` at 8% accent opacity, or white
- All interactive elements use the game's accent color
- Timer: circular ring, accent-colored, shrinks smoothly, shifts to `AppTheme.error` in final 25%

### 8.4 Results Screen

- White background
- Large score number (`AppTheme.Typography.hero` or 48pt Bold) centered with accent color
- Stats breakdown in cards below
- CTAs: `PrimaryButton` ("Play Again") + `SecondaryButton` ("Back to Home")
- Optional confetti on high scores

---

## 9. SwiftUI Implementation Rules

### 9.1 Theme System

`AppTheme` stores all design tokens as static properties. `GameTheme` provides per-game accent colors with computed convenience properties:

```swift
// AppTheme usage
AppTheme.warmLinen          // Page background
AppTheme.pureWhite          // Card surface
AppTheme.deepCharcoal       // Primary text
AppTheme.mediumGray         // Secondary text
AppTheme.Spacing.md         // Standard 16pt
AppTheme.Radius.card        // 16pt card radius
AppTheme.Typography.hero    // Screen titles

// GameTheme usage
GameTheme.vibeCheck.accentColor       // Full accent
GameTheme.vibeCheck.lightBackground   // 8% opacity
GameTheme.vibeCheck.mediumBackground  // 15% opacity
GameTheme.vibeCheck.darkAccent        // 85% opacity (for dark mode)
```

### 9.2 Shared Modifiers (always use these)

| Modifier | Purpose |
|---|---|
| `.gameCard()` | White background, 16pt radius, standard shadow, 16pt padding |
| `.accentPill(color:)` | Colored background, 12pt radius, white text styling |
| `.pressable()` | Scale-down + haptic on press |
| `.skeletonLoading()` | Shimmer placeholder animation |
| `.staggeredAppear(index:)` | Slide-up + fade with staggered delay |

### 9.3 Key Implementation Patterns

- Use `@Environment(\.colorScheme)` to switch between light/dark token sets in every view
- Card shadows via the `.gameCard()` ViewModifier — must read colorScheme for dark mode
- Game accent colors accessed via `GameTheme.*.accentColor` — never hardcode colors
- All animations use `.spring()` with values from the timing standards
- Use shared components (`PrimaryButton`, `SecondaryButton`, `CategoryPill`) — never reimplement

### 9.4 Mandatory Checklist for Every New View

1. Uses `AppTheme.Typography.*` for all readable text (`.system(size:)` only for decorative display icons/numbers 36pt+)
2. Uses `AppTheme.Spacing.*` for padding/spacing (intermediate values only inside shared components)
3. Uses `AppTheme.Radius.*` for all corner radii
4. Uses `GameTheme.*.accentColor` (not raw system colors) for game-specific color
5. Uses `AppTheme` semantic colors for success/error/warning states
6. Uses `AppTheme.medalGold`/`.medalSilver`/`.medalBronze` for rankings
7. Uses shared components (`PrimaryButton`, `SecondaryButton`, `CategoryPill`, `GameSpinner`)
8. Uses `.pressable()` on all tappable elements
9. Uses `.staggeredAppear(index:)` on list items
10. Includes haptic feedback via `HapticManager` on key interactions
11. Respects `@Environment(\.accessibilityReduceMotion)`
12. Supports dark mode via `@Environment(\.colorScheme)` or uses dark-mode-aware shared components
13. Uses `.skeletonLoading()` or `GameSpinner` for async content (never `ProgressView()`)

---

## 10. Do / Don't Quick Reference

### DO

- Use warm off-white backgrounds (`AppTheme.warmLinen`)
- Apply generous 16pt padding inside cards via `.gameCard()`
- Use one accent color per game consistently via `GameTheme`
- Add spring animations to all tappable elements via `.pressable()`
- Use SF Symbols for all system icons
- Maintain 16pt side margins on all screens
- Include haptic feedback on key interactions via `HapticManager`
- Use skeleton loading (`.skeletonLoading()`) for async content
- Support both light and dark mode from day one
- Use large, left-aligned screen titles
- Use `AppTheme.success` / `AppTheme.error` for feedback states
- Use `CategoryPill` for all filter/selection chips

### DON'T

- Use pure white (`#FFFFFF`) as page background
- Use sharp corners (radius < 12pt) on cards
- Mix multiple accent colors from different games on one screen
- Use `ProgressView()` spinners for loading — use `GameSpinner` or `.skeletonLoading()`
- Use custom icon assets when SF Symbols exist
- Crowd the screen with tight spacing
- Skip press-state feedback on buttons
- Use raw `Color.blue`, `Color.purple`, `Color.green`, etc.
- Use hardcoded `.font(.title)`, `.font(.headline)`, etc. — use `AppTheme.Typography.*`
- Use `.font(.system(size:))` for readable text (only for decorative display icons 36pt+)
- Use hardcoded `cornerRadius(15)` with raw numbers — use `AppTheme.Radius.*`
- Design only for light mode
- Center screen titles or use small header text
- Create custom button/pill implementations when shared components exist
- Use gradients that mix colors from different games
