# Border Hop: edge-indicator pills and mini-map collide with the top HUD

**Status:** diagnosed, ready to implement. Work on `main`.
**Reviewer:** Fable (diagnosis + post-change check). **Implementer:** another model.

## Symptom

In the Border Hop game screen, the blue "neighbor is off-screen this way" pills
(e.g. "Saudi Arabia ▸") stack in the top-left directly under the X (quit) button.
The X plate covers the first pill; the second pill is clipped by the plate's
raised shadow. In the same screenshot the "🚶 0" hop-counter lozenge sits on top
of the mini-map, and a yellow destination pill is hidden behind the mini-map at
the right edge. All three are the same bug.

## Root cause

`BorderHopGameView` renders the map full-bleed:

```swift
BorderHopMapView(viewModel: viewModel)
    .ignoresSafeArea()          // BorderHopGameView.swift:15-16
topHUD
    .padding(.horizontal, AppTheme.Spacing.md)
    .padding(.top, AppTheme.Spacing.sm)   // laid out INSIDE the safe area
```

So the map's `GeometryReader` coordinate space starts at the physical top of the
device, while the HUD is offset by the status-bar / Dynamic Island inset
(≈59pt on current iPhones) plus 8pt. The HUD row therefore occupies roughly
**y = 67…111pt in map coordinates** (44pt plate) plus a 5pt raised shadow
(`AppTheme.Retro.shadowOffset`).

The map's own chrome uses hard-coded constants that assume the HUD starts near
y = 0 of the map (they date from commit d0dae9c and were never inset-aware):

| Element | Code | Actual rect in map coords |
|---|---|---|
| Edge pills clearance | `safeArea = CGRect(x: 16, y: 72, …)`; pill center clamped to `minY + 16` → **y 88** ([BorderHopMapView.swift:623-649](../../../GamesWithFriends/Features/BorderHop/Components/BorderHopMapView.swift)) | pill spans 72…104 → inside the X plate (67…111) |
| Pill stacking nudge | `clamped.y += 36` only avoids *other pills* ([:655-658]) | 2nd pill at 124, still under the plate shadow |
| Mini-map | `.padding(.top, 64)` ([:73-77]) | top at 64 → under the hop-counter lozenge |
| Pill trailing clearance | `safeArea` only insets 16pt on the right | pills land behind the 112pt-wide mini-map |

Screenshot check (iPhone 17 Pro, 2.29 px/pt): X centre ≈ 92pt, first pill
centre ≈ 89pt, second ≈ 124pt, mini-map top ≈ 63pt. Matches the arithmetic
exactly, so no simulator run was needed to confirm.

## Fix (follow the existing codebase pattern)

The hub already publishes the device safe-area insets as an environment value
for exactly this situation: `\.systemChromeInsets` (defined in
`Theme/MotifGroundView.swift:130-142`, set in `GameHubView.swift:17`, consumed by
Country Letter's `GamePlayView.swift:7,17`). Border Hop is pushed inside that
`NavigationStack`, so the value is available. Use it; do not add a second
mechanism (no `safeAreaInset`, no new GeometryReader tricks).

### Steps — all in `BorderHopMapView.swift`

1. Add `@Environment(\.systemChromeInsets) private var chrome` to
   `BorderHopMapView`.

2. Add one derived constant and pass it down (do not duplicate the arithmetic):

   ```swift
   /// Bottom edge of the HUD row in map coordinates: status bar/Dynamic Island,
   /// the HUD's top padding, the 44pt close plate, and its raised shadow.
   private var hudBottom: CGFloat {
       chrome.top + AppTheme.Spacing.sm + 44 + AppTheme.Retro.shadowOffset
   }
   ```

3. Mini-map: replace `.padding(.top, 64)` with
   `.padding(.top, hudBottom + AppTheme.Spacing.sm)`.

4. Edge pills: `AnimatedMapContent` is a separate private struct. Give it two new
   `let` inputs, `topClearance: CGFloat` and `miniMapRect: CGRect`, set from
   `BorderHopMapView` (`hudBottom + AppTheme.Spacing.sm` and the mini-map's
   frame: width 112, height `112 * canvas.height / canvas.width`, origin
   `(viewSize.width - 16 - 112, hudBottom + Spacing.sm)`). Then in `edgeTargets`:
   - `safeArea.origin.y = topClearance`, `safeArea.height = bounds.height - topClearance - 104`
     (leave the bottom constant alone; the destination bar is not part of this bug).
   - Seed `placedRects` with `miniMapRect.insetBy(dx: -8, dy: -8)` before the
     loop, so the existing nudge loop pushes pills below the mini-map instead of
     behind it. Keep the 8-attempt cap.

   Hoist the mini-map width/height into a small helper (e.g.
   `private func miniMapFrame(viewSize:) -> CGRect`) so the overlay and the
   pill exclusion cannot drift apart. `miniMap(viewSize:)` should read its size
   from the same helper.

5. Nothing else. No changes to `BorderHopGameView`, the HUD, or the bottom bar.

### Test

The placement logic is private and view-bound. Add the smallest pure seam that
makes it testable: a `static func` (e.g. `BorderHopEdgePillLayout.place(...)`)
taking the candidate real points, `viewSize`, `topClearance`, and exclusion
rects, returning positions. Then one unit test in `GamesWithFriendsTests`:
viewSize 402×874, topClearance 120, a real point at (-100, 50) → the returned
pill rect (110×32 centred on the position) has `minY >= 120`; and a point at
(600, 50) with the mini-map rect excluded → the pill rect does not intersect
the mini-map rect. Write the test first and watch it fail against the current
constants.

### Verification (implementer, then reviewer)

- `xcodebuild` for the iPhone simulator compiles with no new warnings.
- Run the app (headless simctl harness, see repo tooling notes), start Border
  Hop, pan so a neighbor is off-screen top-left. Screenshot: no pill overlaps
  the X plate or the HUD row; the "🚶" lozenge no longer sits on the mini-map;
  a destination pill near the top-right appears below the mini-map, not behind it.
- Dark mode and a device without a Dynamic Island (e.g. iPhone SE, `chrome.top`
  ≈ 20) both still leave a visible gap between the HUD and the first pill.

## Out of scope (noted, not part of this change)

- A country label ("Arabia") draws under the Dynamic Island at the very top.
  That is the canvas legitimately extending under system chrome; if it bothers
  us it is a separate label-culling change.
- The bottom constants (`104` for pills, `96` for the recenter button) are also
  hard-coded but currently have enough slack; leave them.
