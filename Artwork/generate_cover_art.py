#!/usr/bin/env python3
"""Games with Friends — cover art in the 'Cannery Folk' philosophy.

Vintage tin-label maximalism: plum field in a marigold frame, the gold
script title "Games for Friends" arching over a globe medallion, and
mirrored carnation garlands.
Built as SVG, rendered to PNG with cairosvg.
"""
import math
import os
import sys
import cairosvg
from PIL import ImageFont

W = H = 1024

# ---------------------------------------------------------------- palette
GOLD      = "#EFAD1E"
GOLD_HI   = "#FFC93A"
PLUM      = "#5F2657"
PLUM_DK   = "#4A1C44"
BLUSH     = "#F7CBD9"
BLUSH_DK  = "#EFB3C8"
MAGENTA   = "#DE4C9B"
RED       = "#DD4A31"
RED_DK    = "#B93A26"
GREEN     = "#3B8A57"
GREEN_DK  = "#2C6B43"
BLUE      = "#4B87C7"
BLUE_DK   = "#3A6EA8"
CREAM     = "#FDF2DE"
CREAM_DK  = "#EBD9BC"
INK       = "#22141C"

FONT_DIR = "/root/.fonts"
BSB = ImageFont.truetype(f"{FONT_DIR}/BigShoulders-Bold.ttf", 100)
WSB = ImageFont.truetype(f"{FONT_DIR}/WorkSans-Bold.ttf", 100)
PAC = ImageFont.truetype(f"{FONT_DIR}/Pacifico.ttf", 100)

# medallion center variant: globe (default) | cards | meeples | tiles | question
VARIANT = sys.argv[1] if len(sys.argv) > 1 else "globe"

parts = []
def add(s): parts.append(s)

def P(pts):
    return " ".join(f"{x:.2f},{y:.2f}" for x, y in pts)

# ---------------------------------------------------------------- helpers
def arc_text(text, cx, cy, r, size, fill, font=BSB, family="Big Shoulders",
             weight="bold", spacing=8.0, stroke=None, sw=0, bottom=False):
    """Place text centered on a circle (cx,cy,r): on top of it, or (with
    bottom=True) along its underside so the line arches gently upward."""
    scale = size / 100.0
    widths = [font.getlength(ch) * scale for ch in text]
    adv = [w + spacing for w in widths]
    total = sum(adv) - spacing
    sgn = -1 if bottom else 1
    base = 90 if bottom else -90
    a = base - sgn * math.degrees(total / (2 * r))
    out = []
    for ch, w in zip(text, widths):
        a_mid = a + sgn * math.degrees((w / 2) / r)
        x = cx + r * math.cos(math.radians(a_mid))
        y = cy + r * math.sin(math.radians(a_mid))
        rot = a_mid + sgn * 90
        if ch != " ":
            st = f' stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" paint-order="stroke"' if stroke else ""
            out.append(
                f'<text x="{x:.2f}" y="{y:.2f}" font-family="{family}" '
                f'font-weight="{weight}" font-size="{size}" fill="{fill}"{st} '
                f'text-anchor="middle" '
                f'transform="rotate({rot:.2f} {x:.2f} {y:.2f})">{ch}</text>')
        a += sgn * math.degrees((w + spacing) / r)
    add("".join(out))

def star5(cx, cy, r, fill=GOLD, rot=0.0, sw=3.2):
    pts = []
    for i in range(10):
        rr = r if i % 2 == 0 else r * 0.42
        a = math.radians(rot - 90 + i * 36)
        pts.append((cx + rr * math.cos(a), cy + rr * math.sin(a)))
    add(f'<polygon points="{P(pts)}" fill="{fill}" stroke="{INK}" '
        f'stroke-width="{sw}" stroke-linejoin="round"/>')

def sparkle(cx, cy, r, fill=CREAM, sw=2.6):
    k = r * 0.18
    d = (f"M {cx} {cy-r} Q {cx+k} {cy-k} {cx+r} {cy} Q {cx+k} {cy+k} {cx} {cy+r} "
         f"Q {cx-k} {cy+k} {cx-r} {cy} Q {cx-k} {cy-k} {cx} {cy-r} Z")
    add(f'<path d="{d}" fill="{fill}" stroke="{INK}" stroke-width="{sw}" stroke-linejoin="round"/>')

def dot(cx, cy, r, fill=CREAM, sw=0):
    st = f' stroke="{INK}" stroke-width="{sw}"' if sw else ""
    add(f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{fill}"{st}/>')

def crescent(cx, cy, r, rot=0, fill=GOLD):
    d = (f"M 0 {-r} A {r} {r} 0 1 1 0 {r} "
        f"A {r*0.78} {r*0.78} 0 1 0 0 {-r} Z")
    add(f'<g transform="translate({cx} {cy}) rotate({rot})">'
        f'<path d="{d}" fill="{fill}" stroke="{INK}" stroke-width="3.2" stroke-linejoin="round"/></g>')

def leaf(cx, cy, L, rot, fill=GREEN):
    w = L * 0.42
    d = (f"M 0 0 C {-w} {-L*0.35} {-w*0.72} {-L*0.82} 0 {-L} "
         f"C {w*0.72} {-L*0.82} {w} {-L*0.35} 0 0 Z")
    add(f'<g transform="translate({cx} {cy}) rotate({rot})">'
        f'<path d="{d}" fill="{fill}" stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>'
        f'<line x1="0" y1="{-L*0.16}" x2="0" y2="{-L*0.8}" stroke="{INK}" stroke-width="2.2"/></g>')

def stem(x1, y1, x2, y2, bend, width=6.5):
    mx, my = (x1 + x2) / 2 + bend, (y1 + y2) / 2
    d = f"M {x1} {y1} Q {mx} {my} {x2} {y2}"
    add(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="{width+5}" stroke-linecap="round"/>')
    add(f'<path d="{d}" fill="none" stroke="{GREEN}" stroke-width="{width}" stroke-linecap="round"/>')

def petal_path(r, w):
    """Petal pointing up from origin, scalloped tip (3 bumps)."""
    return (f"M 0 0 "
            f"C {-w*0.55} {-r*0.28} {-w} {-r*0.62} {-w*0.82} {-r*0.86} "
            f"Q {-w*0.55} {-r*1.02} {-w*0.30} {-r*0.90} "
            f"Q {0} {-r*1.06} {w*0.30} {-r*0.90} "
            f"Q {w*0.55} {-r*1.02} {w*0.82} {-r*0.86} "
            f"C {w} {-r*0.62} {w*0.55} {-r*0.28} 0 0 Z")

def carnation(cx, cy, r, c_outer, c_inner, rot=0.0):
    layers = [(1.00, 8, c_outer, 0), (0.70, 6, c_inner, 22), (0.44, 4, c_outer, 8)]
    g = [f'<g transform="translate({cx} {cy}) rotate({rot})">']
    for k, n, col, off in layers:
        pr, pw = r * k, r * k * 0.46
        d = petal_path(pr, pw)
        for i in range(n):
            a = off + i * 360.0 / n
            g.append(f'<g transform="rotate({a})"><path d="{d}" fill="{col}" '
                     f'stroke="{INK}" stroke-width="3" stroke-linejoin="round"/></g>')
    g.append(f'<circle r="{r*0.13}" fill="{INK}"/>')
    g.append("</g>")
    add("".join(g))

def daisy(cx, cy, r, fill=CREAM, center=GOLD):
    g = [f'<g transform="translate({cx} {cy})">']
    for i in range(8):
        g.append(f'<ellipse cx="0" cy="{-r*0.62}" rx="{r*0.30}" ry="{r*0.62}" '
                 f'fill="{fill}" stroke="{INK}" stroke-width="2.4" '
                 f'transform="rotate({i*45})"/>')
    g.append(f'<circle r="{r*0.30}" fill="{center}" stroke="{INK}" stroke-width="2.4"/></g>')
    add("".join(g))

def boat(cx, cy, s):
    """Tiny fishing boat, homage charm."""
    g = [f'<g transform="translate({cx} {cy}) scale({s})">']
    # hull
    g.append(f'<path d="M -30 0 L 30 0 L 22 14 Q 0 20 -22 14 Z" fill="{GREEN}" '
             f'stroke="{INK}" stroke-width="3" stroke-linejoin="round"/>')
    # cabin
    g.append(f'<rect x="-12" y="-16" width="24" height="16" rx="3" fill="{CREAM}" '
             f'stroke="{INK}" stroke-width="3"/>')
    g.append(f'<circle cx="0" cy="-8" r="4" fill="{BLUE}" stroke="{INK}" stroke-width="2.4"/>')
    # mast + flag
    g.append(f'<line x1="18" y1="0" x2="18" y2="-26" stroke="{INK}" stroke-width="3"/>')
    g.append(f'<path d="M 18 -26 L 34 -21 L 18 -16 Z" fill="{RED}" stroke="{INK}" '
             f'stroke-width="2.6" stroke-linejoin="round"/>')
    g.append("</g>")
    add("".join(g))

def die(cx, cy, s, rot=0):
    g = [f'<g transform="translate({cx} {cy}) rotate({rot}) scale({s})">']
    g.append(f'<rect x="-16" y="-16" width="32" height="32" rx="7" fill="{CREAM}" '
             f'stroke="{INK}" stroke-width="3.4"/>')
    for px, py in [(-7, -7), (7, 7), (7, -7), (-7, 7), (0, 0)]:
        g.append(f'<circle cx="{px}" cy="{py}" r="3.1" fill="{INK}"/>')
    g.append("</g>")
    add("".join(g))

# ---------------------------------------------------------------- canvas
add(f'<rect width="{W}" height="{H}" fill="{GOLD}"/>')
# frame pinstripes
add(f'<rect x="10" y="10" width="{W-20}" height="{H-20}" rx="26" fill="none" stroke="{INK}" stroke-width="3"/>')
# plum panel
add(f'<rect x="52" y="52" width="{W-104}" height="{H-104}" rx="20" fill="{PLUM}" stroke="{INK}" stroke-width="5"/>')
add(f'<rect x="66" y="66" width="{W-132}" height="{H-132}" rx="14" fill="none" stroke="{GOLD}" stroke-width="2.6" opacity="0.85"/>')

# frame corner daisies
for dx, dy in [(31, 31), (W-31, 31), (31, H-31), (W-31, H-31)]:
    daisy(dx, dy, 15, CREAM, MAGENTA)

# ---------------------------------------------------------------- title
# script title arching over the medallion, gold with an ink outline
RIB_C = (512.0, 1490.0)      # arc circle center far below the canvas
def arc_pt(r, adeg):
    return (RIB_C[0] + r * math.cos(math.radians(adeg)), RIB_C[1] + r * math.sin(math.radians(adeg)))
TITLE = "Games for Friends"
t_size = min(92.0, 740.0 / (PAC.getlength(TITLE) / 100.0))
base_r = 1318.0              # baseline y = 172 at center
ba = 24
bp1 = arc_pt(base_r, -90 - ba); bp2 = arc_pt(base_r, -90 + ba)
add(f'<defs><path id="titlearc" d="M {bp1[0]:.1f} {bp1[1]:.1f} '
    f'A {base_r} {base_r} 0 0 1 {bp2[0]:.1f} {bp2[1]:.1f}"/></defs>')
add(f'<text font-family="Pacifico" font-size="{t_size:.1f}" fill="{GOLD_HI}" '
    f'stroke="{INK}" stroke-width="7" stroke-linejoin="round" paint-order="stroke">'
    f'<textPath href="#titlearc" startOffset="50%" text-anchor="middle">{TITLE}</textPath></text>')

# ---------------------------------------------------------------- medallion
# drawn about (512, 428) then scaled up and settled toward the center
MC = (512.0, 428.0)
MR = 178.0
add('<g transform="translate(512 474) scale(1.13) translate(-512 -428)">')
add(f'<circle cx="{MC[0]}" cy="{MC[1]}" r="{MR+14}" fill="{GOLD}" stroke="{INK}" stroke-width="5"/>')
add(f'<circle cx="{MC[0]}" cy="{MC[1]}" r="{MR-8}" fill="{BLUSH}" stroke="{INK}" stroke-width="4.5"/>')
# ring dots
for i in range(28):
    a = math.radians(i * 360 / 28)
    dot(MC[0] + (MR + 3) * math.cos(a), MC[1] + (MR + 3) * math.sin(a), 2.6, PLUM)

# ---- medallion center art: pick with `python3 generate_cover_art.py <variant>`
GR = 108.0
gx, gy = MC

def center_globe():
    add(f'<circle cx="{gx}" cy="{gy}" r="{GR}" fill="{BLUE}" stroke="{INK}" stroke-width="5"/>')
    # graticule
    add(f'<g stroke="{CREAM}" stroke-width="2.6" fill="none" opacity="0.9">'
        f'<ellipse cx="{gx}" cy="{gy}" rx="{GR*0.55}" ry="{GR}"/>'
        f'<line x1="{gx}" y1="{gy-GR}" x2="{gx}" y2="{gy+GR}"/>'
        f'<line x1="{gx-GR}" y1="{gy}" x2="{gx+GR}" y2="{gy}"/>'
        f'<path d="M {gx-GR*0.87} {gy-GR*0.5} Q {gx} {gy-GR*0.72} {gx+GR*0.87} {gy-GR*0.5}"/>'
        f'<path d="M {gx-GR*0.87} {gy+GR*0.5} Q {gx} {gy+GR*0.72} {gx+GR*0.87} {gy+GR*0.5}"/>'
        f'</g>')
    # continents (stylized folk blobs), clipped to globe
    add(f'<clipPath id="globeclip"><circle cx="{gx}" cy="{gy}" r="{GR-2}"/></clipPath>')
    cont = []
    # americas
    cont.append(f'<path d="M {gx-92} {gy-52} Q {gx-56} {gy-74} {gx-34} {gy-56} '
                f'Q {gx-22} {gy-44} {gx-38} {gy-30} Q {gx-28} {gy-18} {gx-40} {gy-2} '
                f'Q {gx-34} {gy+18} {gx-48} {gy+46} Q {gx-58} {gy+70} {gx-66} {gy+44} '
                f'Q {gx-62} {gy+16} {gx-78} {gy-2} Q {gx-98} {gy-22} {gx-92} {gy-52} Z" '
                f'fill="{GREEN}" stroke="{INK}" stroke-width="3.4" stroke-linejoin="round"/>')
    # africa / eurasia
    cont.append(f'<path d="M {gx+4} {gy-70} Q {gx+40} {gy-84} {gx+72} {gy-64} '
                f'Q {gx+96} {gy-46} {gx+84} {gy-28} Q {gx+64} {gy-16} {gx+52} {gy-24} '
                f'Q {gx+40} {gy-10} {gx+48} {gy+10} Q {gx+52} {gy+40} {gx+30} {gy+58} '
                f'Q {gx+12} {gy+68} {gx+8} {gy+40} Q {gx+2} {gy+16} {gx+12} {gy-6} '
                f'Q {gx-4} {gy-24} {gx-10} {gy-44} Q {gx-8} {gy-64} {gx+4} {gy-70} Z" '
                f'fill="{GREEN}" stroke="{INK}" stroke-width="3.4" stroke-linejoin="round"/>')
    # australia
    cont.append(f'<path d="M {gx+58} {gy+64} Q {gx+76} {gy+56} {gx+88} {gy+68} '
                f'Q {gx+92} {gy+84} {gx+74} {gy+88} Q {gx+56} {gy+90} {gx+54} {gy+76} '
                f'Q {gx+54} {gy+68} {gx+58} {gy+64} Z" '
                f'fill="{GREEN}" stroke="{INK}" stroke-width="3.2" stroke-linejoin="round"/>')
    add(f'<g clip-path="url(#globeclip)"><g transform="translate(-8,-14)">{cont[2]}</g>{cont[0]}{cont[1]}</g>')
    # ocean sparkles
    sparkle(gx - 52, gy + 74, 7, CREAM, sw=2.2)
    dot(gx + 76, gy + 34, 3.4, CREAM)

def playing_card(x, y, rot, symbol, sym_fill):
    """One folk playing card, 76x106, centered at local origin."""
    g = [f'<g transform="translate({x} {y}) rotate({rot})">']
    g.append(f'<rect x="-38" y="-53" width="76" height="106" rx="9" fill="{CREAM}" '
             f'stroke="{INK}" stroke-width="4.2"/>')
    g.append(f'<rect x="-30" y="-45" width="60" height="90" rx="6" fill="none" '
             f'stroke="{sym_fill}" stroke-width="2.2" opacity="0.55"/>')
    if symbol == "heart":
        g.append(f'<path d="M 0 16 C -22 0 -22 -18 -10 -18 C -4 -18 0 -13 0 -8 '
                 f'C 0 -13 4 -18 10 -18 C 22 -18 22 0 0 16 Z" '
                 f'fill="{sym_fill}" stroke="{INK}" stroke-width="3.2" stroke-linejoin="round"/>')
    elif symbol == "star":
        pts = []
        for i in range(10):
            rr = 19 if i % 2 == 0 else 8
            a = math.radians(-90 + i * 36)
            pts.append((rr * math.cos(a), rr * math.sin(a)))
        g.append(f'<polygon points="{P(pts)}" fill="{sym_fill}" stroke="{INK}" '
                 f'stroke-width="3.2" stroke-linejoin="round"/>')
    elif symbol == "diamond":
        g.append(f'<path d="M 0 -19 Q 8 -8 15 0 Q 8 8 0 19 Q -8 8 -15 0 Q -8 -8 0 -19 Z" '
                 f'fill="{sym_fill}" stroke="{INK}" stroke-width="3.2" stroke-linejoin="round"/>')
    g.append("</g>")
    add("".join(g))

def center_cards():
    """A fanned hand of cards with a die: game night in one glance."""
    add(f'<g transform="translate({gx} {gy}) scale(1.28)">')
    # fan pivots below center so the cards spread like a held hand
    add('<g transform="translate(0 6)">')
    add('<g transform="rotate(-26) translate(0 -44)">'); playing_card(0, 0, 0, "diamond", BLUE); add('</g>')
    add('<g transform="rotate(26) translate(0 -44)">');  playing_card(0, 0, 0, "star", GOLD); add('</g>')
    add('<g transform="rotate(0) translate(0 -50)">');   playing_card(0, 0, 0, "heart", RED); add('</g>')
    add('</g>')
    # die tucked at the lower right of the hand
    add(f'<g transform="translate(52 68) rotate(14)">')
    add(f'<rect x="-24" y="-24" width="48" height="48" rx="10" fill="{MAGENTA}" '
        f'stroke="{INK}" stroke-width="4.2"/>')
    for px, py in [(-10, -10), (10, 10), (10, -10), (-10, 10), (0, 0)]:
        dot(px, py, 4.4, CREAM)
    add('</g>')
    sparkle(-78, 58, 8, GOLD_HI)
    dot(-62, -78, 4, MAGENTA)
    add('</g>')

# classic board-game meeple silhouette: round head, wing arms angled
# down-and-out, chunky base with a narrow notch between the legs
MEEPLE = ("M0,-50 C12,-50 20,-42 20,-32 C20,-25 16,-19 10,-16 "
          "C24,-15 38,-12 44,-6 C48,-1 45,6 38,5 C30,4 22,2 16,2 "
          "C17,12 22,22 28,32 C31,38 32,43 31,46 C30,50 26,52 21,52 L9,52 "
          "C5,52 3,49 3,45 C3,38 4,32 0,28 C-4,32 -3,38 -3,45 "
          "C-3,49 -5,52 -9,52 L-21,52 C-26,52 -30,50 -31,46 "
          "C-32,43 -31,38 -28,32 C-22,22 -17,12 -16,2 "
          "C-22,2 -30,4 -38,5 C-45,6 -48,-1 -44,-6 "
          "C-38,-12 -24,-15 -10,-16 C-16,-19 -20,-25 -20,-32 "
          "C-20,-42 -12,-50 0,-50 Z")

def meeple(x, y, rot, scale, fill, trim):
    """One folk meeple with a face and a personal touch, drawn like the
    reference tins: closed happy eyes, rosy cheeks, ink outline."""
    add(f'<g transform="translate({x} {y}) rotate({rot}) scale({scale})">')
    add(f'<path d="{MEEPLE}" fill="{fill}" stroke="{INK}" stroke-width="4.2" '
        f'stroke-linejoin="round"/>')
    # face: closed eyes + smile + blush
    add(f'<g stroke="{INK}" stroke-width="2.6" fill="none" stroke-linecap="round">'
        f'<path d="M -11 -36 Q -7 -31 -3 -36"/>'
        f'<path d="M 3 -36 Q 7 -31 11 -36"/>'
        f'<path d="M -6 -27 Q 0 -22 6 -27"/></g>')
    dot(-14, -29, 3.0, BLUSH)
    dot(14, -29, 3.0, BLUSH)
    if trim == "scarf":
        add(f'<path d="M -11 -14 L 11 -14 L 1 0 Z" fill="{GOLD}" stroke="{INK}" '
            f'stroke-width="2.6" stroke-linejoin="round"/>')
    elif trim == "star":
        pts = []
        for i in range(10):
            rr = 9 if i % 2 == 0 else 3.8
            a = math.radians(-90 + i * 36)
            pts.append((rr * math.cos(a), 0 + rr * math.sin(a)))
        add(f'<polygon points="{P(pts)}" fill="{GOLD}" stroke="{INK}" '
            f'stroke-width="2.4" stroke-linejoin="round"/>')
    add('</g>')

def center_meeples():
    """A little crowd of meeples: game night, everyone's invited."""
    add(f'<g transform="translate({gx} {gy})">')
    # back row peeks over the front row
    meeple(-35, -26, -5, 0.78, GREEN, "star")
    meeple(35, -26, 5, 0.78, MAGENTA, None)
    # front row
    meeple(-54, 28, -9, 1.0, BLUE, "scarf")
    meeple(54, 28, 9, 1.0, RED, None)
    # shared star overhead
    pts = []
    for i in range(10):
        rr = 17 if i % 2 == 0 else 7
        a = math.radians(-90 + i * 36)
        pts.append((rr * math.cos(a), -92 + rr * math.sin(a)))
    add(f'<polygon points="{P(pts)}" fill="{GOLD}" stroke="{INK}" '
        f'stroke-width="3.2" stroke-linejoin="round"/>')
    sparkle(-92, -58, 8, GOLD_HI)
    sparkle(92, -58, 8, GOLD_HI)
    # spray of stars below the medallion circle
    star5(-56, 206, 10, GOLD, rot=-12)
    star5(0, 222, 14, GOLD_HI, rot=8)
    star5(56, 206, 10, GOLD, rot=12)
    dot(-96, 190, 4, BLUSH)
    dot(96, 190, 4, BLUSH)
    add('</g>')

def center_tiles():
    """Question-and-answer letter tiles: trivia of every flavor."""
    add(f'<g transform="translate({gx} {gy}) scale(1.18)">')
    for x, y, rot, ch, accent in [(-40, -30, -10, "Q", MAGENTA), (38, 32, 8, "A", BLUE)]:
        add(f'<g transform="translate({x} {y}) rotate({rot})">')
        add(f'<rect x="-37" y="-37" width="74" height="74" rx="10" fill="{CREAM}" '
            f'stroke="{INK}" stroke-width="4.4"/>')
        add(f'<rect x="-29" y="-29" width="58" height="58" rx="6" fill="none" '
            f'stroke="{accent}" stroke-width="2.2" opacity="0.55"/>')
        add(f'<text x="0" y="17" font-family="Big Shoulders" font-weight="bold" '
            f'font-size="52" fill="{INK}" text-anchor="middle">{ch}</text>')
        add('</g>')
    star5(52, -52, 13, GOLD, rot=12)
    sparkle(-66, 58, 8, GOLD_HI)
    dot(-74, -74, 4, MAGENTA)
    dot(80, -14, 4, MAGENTA)
    add('</g>')

def center_question():
    """A bold question mark on a scalloped rosette: every game starts with one."""
    add(f'<g transform="translate({gx} {gy})">')
    # scalloped seal
    n, r_in = 14, 92
    d = []
    for i in range(n):
        a0 = 2 * math.pi * i / n - math.pi / 2
        a1 = 2 * math.pi * (i + 1) / n - math.pi / 2
        x0, y0 = r_in * math.cos(a0), r_in * math.sin(a0)
        x1, y1 = r_in * math.cos(a1), r_in * math.sin(a1)
        am = (a0 + a1) / 2
        xm, ym = r_in * 1.16 * math.cos(am), r_in * 1.16 * math.sin(am)
        d.append(f"{'M' if i == 0 else 'L'} {x0:.1f} {y0:.1f} Q {xm:.1f} {ym:.1f} {x1:.1f} {y1:.1f}")
    add(f'<path d="{" ".join(d)} Z" fill="{MAGENTA}" stroke="{INK}" '
        f'stroke-width="4.4" stroke-linejoin="round"/>')
    add(f'<circle r="74" fill="{BLUE}" stroke="{INK}" stroke-width="4"/>')
    add(f'<text x="0" y="34" font-family="Big Shoulders" font-weight="bold" '
        f'font-size="120" fill="{CREAM}" stroke="{INK}" stroke-width="5" '
        f'stroke-linejoin="round" paint-order="stroke" text-anchor="middle">?</text>')
    sparkle(-58, -50, 9, GOLD_HI)
    sparkle(60, 44, 8, CREAM)
    add('</g>')

CENTERS = {"globe": center_globe, "cards": center_cards,
           "meeples": center_meeples, "tiles": center_tiles,
           "question": center_question}
CENTERS[VARIANT]()

# charms inside medallion (blush zone)
sparkle(MC[0]-142, MC[1]-38, 11)
sparkle(MC[0]+142, MC[1]-38, 11)
star5(MC[0]-120, MC[1]+86, 12, GOLD)
star5(MC[0]+120, MC[1]+86, 12, GOLD)
dot(MC[0]-146, MC[1]+34, 4, MAGENTA)
dot(MC[0]+146, MC[1]+34, 4, MAGENTA)
dot(MC[0]-96, MC[1]-116, 4, MAGENTA)
dot(MC[0]+96, MC[1]-116, 4, MAGENTA)
add('</g>')

# ---------------------------------------------------------------- side ribbons
def side_ribbon(cx, cy, w, h, rot, text):
    g = [f'<g transform="translate({cx} {cy}) rotate({rot})">']
    x0, y0 = -w/2, -h/2
    # tails
    tw = 26
    g.append(f'<path d="M {x0} {y0+4} L {x0-tw} {y0+8} L {x0-tw*0.45} {0} L {x0-tw} {h/2+4} L {x0} {h/2} Z" '
             f'fill="{CREAM_DK}" stroke="{INK}" stroke-width="3.6" stroke-linejoin="round"/>')
    g.append(f'<path d="M {-x0} {y0+4} L {-x0+tw} {y0+8} L {-x0+tw*0.45} {0} L {-x0+tw} {h/2+4} L {-x0} {h/2} Z" '
             f'fill="{CREAM_DK}" stroke="{INK}" stroke-width="3.6" stroke-linejoin="round"/>')
    # band, gently bowed
    g.append(f'<path d="M {x0} {y0} Q 0 {y0-10} {-x0} {y0} L {-x0} {h/2} Q 0 {h/2+10} {x0} {h/2} Z" '
             f'fill="{CREAM}" stroke="{INK}" stroke-width="4" stroke-linejoin="round"/>')
    g.append(f'<text x="0" y="{h/2-13}" font-family="Big Shoulders" font-weight="bold" '
             f'font-size="30" fill="{INK}" text-anchor="middle" letter-spacing="2.5">{text}</text>')
    g.append("</g>")
    add("".join(g))


# ---------------------------------------------------------------- garlands
def garland(side):
    """side=-1 left, +1 right; mirrored carnation column."""
    s = side
    ax = 512 + s * 350
    # stems
    stem(ax - s*10, 892, ax + s*28, 700, s*40)
    stem(ax - s*10, 892, ax - s*46, 738, -s*30)
    stem(ax - s*10, 892, ax + s*4, 596, s*54)
    # leaves
    leaf(ax + s*38, 800, 42, s*52)
    leaf(ax - s*52, 812, 40, -s*40)
    leaf(ax + s*10, 668, 38, s*74)
    leaf(ax - s*30, 700, 36, -s*66)
    leaf(ax + s*48, 742, 34, s*30)
    # base tuft (points outward, clear of the bottom line)
    leaf(ax + s*20, 902, 40, s*112)
    leaf(ax + s*46, 884, 32, s*134)
    # blooms
    carnation(ax + s*4, 570, 46, RED, MAGENTA, rot=s*10)
    carnation(ax + s*34, 690, 40, BLUSH, CREAM, rot=-s*14)
    carnation(ax - s*50, 726, 36, MAGENTA, BLUSH, rot=s*22)
    # buds
    for bx, by, br in [(ax - s*20, 630, 12), (ax + s*58, 636, 10)]:
        add(f'<circle cx="{bx}" cy="{by}" r="{br}" fill="{RED}" stroke="{INK}" stroke-width="3"/>')
        add(f'<circle cx="{bx}" cy="{by}" r="{br*0.38}" fill="{BLUSH}"/>')

add('<g transform="translate(162 912) scale(1.13) translate(-162 -912)">')
garland(-1)
add('</g>')
add('<g transform="translate(862 912) scale(1.13) translate(-862 -912)">')
garland(+1)
add('</g>')

# ---------------------------------------------------------------- charms on plum
star5(216, 252, 11, GOLD, rot=-8)
sparkle(96, 158, 9, GOLD_HI)
# sun (top right, below ribbon tail)
add(f'<g transform="translate(886 316)">'
    f'<circle r="17" fill="{GOLD}" stroke="{INK}" stroke-width="3.4"/>' +
    "".join(f'<line x1="0" y1="-23" x2="0" y2="-31" stroke="{INK}" stroke-width="3.2" '
            f'stroke-linecap="round" transform="rotate({a})"/>' for a in range(0, 360, 45)) +
    f'</g>')
sparkle(926, 156, 9, GOLD_HI)
star5(808, 246, 11, GOLD, rot=10)
star5(256, 548, 11, GOLD)
star5(768, 548, 11, GOLD)
sparkle(150, 662, 9, CREAM)
sparkle(874, 662, 9, CREAM)
dot(232, 300, 4.5, GOLD)
dot(792, 300, 4.5, GOLD)
dot(104, 372, 4, BLUSH)
dot(938, 350, 4, BLUSH)
star5(250, 888, 11, GOLD, rot=14)
star5(774, 888, 11, GOLD, rot=-14)

# ---------------------------------------------------------------- bottom charms
# the little boat sails the bottom of the label, flanked by stars
boat(512, 928, 1.18)
star5(424, 934, 9, GOLD, rot=10)
star5(600, 934, 9, GOLD, rot=-12)
sparkle(512, 856, 8, GOLD_HI)
dot(452, 876, 4, BLUSH)
dot(572, 876, 4, BLUSH)

svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" '
       f'viewBox="0 0 {W} {H}">' + "".join(parts) + "</svg>")

out_dir = os.path.dirname(os.path.abspath(__file__))
if VARIANT == "globe":
    base = f"{out_dir}/cover-art"
else:
    os.makedirs(f"{out_dir}/variants", exist_ok=True)
    base = f"{out_dir}/variants/cover-art-{VARIANT}"
with open(f"{base}.svg", "w") as f:
    f.write(svg)
cairosvg.svg2png(bytestring=svg.encode(), write_to=f"{base}.png",
                 output_width=1024, output_height=1024)
print("rendered", f"{base}.png")
