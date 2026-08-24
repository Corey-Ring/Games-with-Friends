# Artwork

Cover art for **Games with Friends**, in a vintage tin-label / candy-box aesthetic
(think Fishwife tinned seafood and Maeve chocolate packaging): a deep plum field in a
marigold frame, the gold script title "Games for Friends" arching over a globe
medallion, and mirrored carnation garlands.

## Files

| File | Purpose |
|---|---|
| `cover-art.png` | Final render, 1024×1024, opaque — used as the iOS app icon |
| `cover-art.svg` | Vector source of the final render |
| `generate_cover_art.py` | Script that builds the SVG and renders the PNG |
| `DESIGN_PHILOSOPHY.md` | The "Cannery Folk" design philosophy behind the piece |

The app icon lives at
`GamesWithFriends/Assets.xcassets/AppIcon.appiconset/cover-art.png` (same image).

## Medallion variants

The generator takes an optional variant argument that swaps the medallion's
center art while keeping everything else identical:

| Variant | Center art |
|---|---|
| `globe` (default) | The folk globe — writes `cover-art.png` |
| `cards` | A fanned hand of cards with a die |
| `meeples` | Four mural-style friends waving hello |
| `tiles` | Q & A letter tiles |
| `question` | A question mark on a scalloped rosette |

Non-globe variants render to `variants/cover-art-<name>.png`. To adopt one as
the cover, copy it over `cover-art.png` and the app-icon copy named above.

## Regenerating

```bash
pip install cairosvg pillow
python3 Artwork/generate_cover_art.py [globe|cards|meeples|tiles|question]
```

The script expects these fonts installed (all SIL Open Font License, free from
Google Fonts) at the path set by `FONT_DIR` in the script:

- **Pacifico** — the script logotype
- **Big Shoulders** (Bold) — ribbon lettering
- **Work Sans** (Bold) — the small caps line

Note: iOS masks icon corners with a large rounded-rect radius, so the daisies at the
extreme corners of the frame are intentionally decorative — they appear in the full
cover art but crop out of the icon.
