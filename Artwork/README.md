# Artwork

Cover art for **Games with Friends**, in a vintage tin-label / candy-box aesthetic
(think Fishwife tinned seafood and Maeve chocolate packaging): a deep plum field in a
marigold frame, an arched ribbon, a globe medallion, mirrored carnation garlands, and
a rolling script logotype.

## Files

| File | Purpose |
|---|---|
| `cover-art.png` | Final render, 1024×1024, opaque — used as the iOS app icon |
| `cover-art.svg` | Vector source of the final render |
| `generate_cover_art.py` | Script that builds the SVG and renders the PNG |
| `DESIGN_PHILOSOPHY.md` | The "Cannery Folk" design philosophy behind the piece |

The app icon lives at
`GamesWithFriends/Assets.xcassets/AppIcon.appiconset/cover-art.png` (same image).

## Regenerating

```bash
pip install cairosvg pillow
python3 Artwork/generate_cover_art.py
```

The script expects these fonts installed (all SIL Open Font License, free from
Google Fonts) at the path set by `FONT_DIR` in the script:

- **Pacifico** — the script logotype
- **Big Shoulders** (Bold) — ribbon lettering
- **Work Sans** (Bold) — the small caps line

Note: iOS masks icon corners with a large rounded-rect radius, so the daisies at the
extreme corners of the frame are intentionally decorative — they appear in the full
cover art but crop out of the icon.
