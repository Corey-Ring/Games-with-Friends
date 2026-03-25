#!/usr/bin/env python3
"""
Convert Natural Earth 1:50m shapefile country data to Swift source files
with SVG path strings for the Border Blitz game.

Preserves all points from the source data — the 50m dataset is already
simplified at the source level, so no further simplification is applied.
"""

import shapefile
import math
import os

SHAPEFILE_PATH = "GamesWithFriends/Country Map Download/ne_50m_admin_0_countries.shp"
OUTPUT_DIR = "BorderBlitz/BorderBlitz/Data"

# Target countries: match by ADMIN field
TARGET_COUNTRIES = {
    "Italy", "France", "Spain", "Germany", "United Kingdom",
    "Norway", "Sweden", "Finland", "Greece", "Portugal",
    "Poland", "Romania", "Ukraine", "Ireland", "Iceland",
    "Croatia", "Switzerland", "Austria", "Netherlands", "Denmark",
    "Japan", "India", "China", "South Korea", "Thailand",
    "Vietnam", "Indonesia", "Saudi Arabia", "Turkey", "Philippines",
    "Pakistan", "Iran", "Iraq",
    "United States of America", "Canada", "Mexico", "Brazil",
    "Argentina", "Chile", "Colombia", "Peru", "Cuba",
    "South Africa", "Egypt", "Madagascar", "Nigeria", "Kenya",
    "Morocco", "Ethiopia", "United Republic of Tanzania",
    "Australia", "New Zealand",
}

# Minimum polygon area (in square degrees) to include.
# At 250×250 display in a 1000-unit canvas, a polygon needs roughly
# 0.05 sq-deg to be visually recognizable (~a few pixels).
MIN_POLYGON_AREA = 0.05

# Douglas-Peucker simplification epsilon (in degrees).
# ~0.03 deg ≈ 3 km — smooths coastline jitter while keeping distinctive features.
SIMPLIFY_EPSILON = 0.03

# For USA, skip Alaska and Hawaii — only use contiguous 48 states
USA_SPECIAL = True


def perpendicular_distance(point, line_start, line_end):
    """Distance from a point to a line defined by two endpoints."""
    x0, y0 = point
    x1, y1 = line_start
    x2, y2 = line_end
    dx = x2 - x1
    dy = y2 - y1
    length_sq = dx * dx + dy * dy
    if length_sq == 0:
        return math.hypot(x0 - x1, y0 - y1)
    t = max(0, min(1, ((x0 - x1) * dx + (y0 - y1) * dy) / length_sq))
    proj_x = x1 + t * dx
    proj_y = y1 + t * dy
    return math.hypot(x0 - proj_x, y0 - proj_y)


def simplify_polygon(coords, epsilon):
    """Douglas-Peucker simplification. Reduces points while preserving shape."""
    if len(coords) <= 2:
        return coords

    # Find the point farthest from the line between first and last
    max_dist = 0
    max_idx = 0
    for i in range(1, len(coords) - 1):
        d = perpendicular_distance(coords[i], coords[0], coords[-1])
        if d > max_dist:
            max_dist = d
            max_idx = i

    if max_dist > epsilon:
        # Recurse on both halves
        left = simplify_polygon(coords[:max_idx + 1], epsilon)
        right = simplify_polygon(coords[max_idx:], epsilon)
        return left[:-1] + right
    else:
        # Only keep endpoints
        return [coords[0], coords[-1]]


def get_polygon_parts(shape):
    """Extract individual polygon rings from a shape's parts."""
    points = shape.points
    parts = list(shape.parts)
    polygons = []
    for i, start in enumerate(parts):
        end = parts[i + 1] if i + 1 < len(parts) else len(points)
        polygon = points[start:end]
        polygons.append(polygon)
    return polygons


def polygon_area(coords):
    """Compute absolute area of a polygon using the shoelace formula."""
    n = len(coords)
    if n < 3:
        return 0
    area = 0.0
    for i in range(n):
        j = (i + 1) % n
        area += coords[i][0] * coords[j][1]
        area -= coords[j][0] * coords[i][1]
    return abs(area) / 2.0


def polygon_bbox(coords):
    """Get bounding box of a polygon."""
    xs = [p[0] for p in coords]
    ys = [p[1] for p in coords]
    return min(xs), min(ys), max(xs), max(ys)


def is_contiguous_us(polygon):
    """Check if a polygon is part of the contiguous US (not Alaska/Hawaii).
    Contiguous US is roughly between lat 24-50, lon -125 to -66."""
    min_x, min_y, max_x, max_y = polygon_bbox(polygon)
    center_x = (min_x + max_x) / 2
    center_y = (min_y + max_y) / 2
    return -130 <= center_x <= -60 and 23 <= center_y <= 50


def normalize_to_svg(polygons, canvas_size=1000):
    """Convert lat/lon polygons to SVG coordinate space.
    - Flip Y axis
    - Normalize to fit within 0-canvas_size preserving aspect ratio
    - Bounding box is computed across ALL polygons so islands stay
      positioned correctly relative to each other
    """
    # Collect all points from all polygons for global bounding box
    all_points = []
    for poly in polygons:
        all_points.extend(poly)

    if not all_points:
        return []

    xs = [p[0] for p in all_points]
    ys = [p[1] for p in all_points]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)

    width = max_x - min_x
    height = max_y - min_y

    if width == 0 or height == 0:
        return []

    # Scale to fit canvas, preserving aspect ratio
    scale = canvas_size / max(width, height)

    # Center within canvas
    scaled_width = width * scale
    scaled_height = height * scale
    offset_x = (canvas_size - scaled_width) / 2
    offset_y = (canvas_size - scaled_height) / 2

    result = []
    for poly in polygons:
        normalized = []
        for x, y in poly:
            nx = (x - min_x) * scale + offset_x
            # Flip Y: latitude increases up, SVG y increases down
            ny = (max_y - y) * scale + offset_y
            normalized.append((round(nx, 1), round(ny, 1)))
        result.append(normalized)
    return result


def polygons_to_svg_path(normalized_polygons):
    """Convert normalized polygon coordinates to SVG path d string.
    All source points are preserved — no simplification."""
    parts = []
    for poly in normalized_polygons:
        if len(poly) < 3:
            continue
        cmds = [f"M {poly[0][0]} {poly[0][1]}"]
        for x, y in poly[1:]:
            cmds.append(f"L {x} {y}")
        cmds.append("Z")
        parts.append(" ".join(cmds))
    return " ".join(parts)


def process_country(shape, adm0_a3):
    """Process a single country shape into SVG path string.

    - USA: only contiguous 48 states polygons above threshold
    - All other countries: include all polygons above MIN_POLYGON_AREA
    """
    polygons = get_polygon_parts(shape)

    if not polygons:
        return None

    if adm0_a3 == "USA" and USA_SPECIAL:
        # Filter to only contiguous US polygons above threshold
        polygons = [p for p in polygons
                    if is_contiguous_us(p) and polygon_area(p) >= MIN_POLYGON_AREA]
        if not polygons:
            # Fallback: largest contiguous polygon
            contiguous = [p for p in get_polygon_parts(shape) if is_contiguous_us(p)]
            if contiguous:
                contiguous.sort(key=polygon_area, reverse=True)
                polygons = [contiguous[0]]
            else:
                return None
    else:
        # Include all polygons above the minimum area threshold
        polygons = [p for p in polygons if polygon_area(p) >= MIN_POLYGON_AREA]
        if not polygons:
            # Fallback: use the single largest polygon
            all_polys = get_polygon_parts(shape)
            all_polys.sort(key=polygon_area, reverse=True)
            polygons = [all_polys[0]] if all_polys else []

    if not polygons:
        return None

    # Sort largest first for consistent rendering order
    polygons.sort(key=polygon_area, reverse=True)

    normalized = normalize_to_svg(polygons)
    if not normalized:
        return None

    return polygons_to_svg_path(normalized)


def generate_swift_path_data(country_paths):
    """Generate CountryPathData.swift content."""
    lines = [
        "// CountryPathData.swift",
        "// Auto-generated from Natural Earth 1:50m data",
        "// Do not edit manually",
        "",
        "import Foundation",
        "",
        "struct CountryPathData {",
        "    static let paths: [String: String] = [",
    ]

    sorted_codes = sorted(country_paths.keys())
    for i, code in enumerate(sorted_codes):
        path = country_paths[code]
        comma = "," if i < len(sorted_codes) - 1 else ""
        lines.append(f'        "{code}": "{path}"{comma}')

    lines.append("    ]")
    lines.append("}")
    lines.append("")

    return "\n".join(lines)


def generate_swift_metadata():
    """Generate CountryMetadata.swift content."""
    return r'''// CountryMetadata.swift
// Auto-generated from Natural Earth 1:50m data
// Do not edit manually

import Foundation

struct CountryMetadata {
    static let countries: [(id: String, name: String, alternateNames: [String])] = [
        ("ITA", "ITALY", ["Italia"]),
        ("FRA", "FRANCE", ["République française"]),
        ("ESP", "SPAIN", ["España", "Kingdom of Spain"]),
        ("DEU", "GERMANY", ["Deutschland"]),
        ("GBR", "UNITED KINGDOM", ["UK", "Britain", "Great Britain", "England"]),
        ("NOR", "NORWAY", ["Norge"]),
        ("SWE", "SWEDEN", ["Sverige"]),
        ("FIN", "FINLAND", ["Suomi"]),
        ("GRC", "GREECE", ["Hellas", "Ellada"]),
        ("PRT", "PORTUGAL", []),
        ("POL", "POLAND", ["Polska"]),
        ("ROU", "ROMANIA", ["România"]),
        ("UKR", "UKRAINE", ["Ukraina"]),
        ("IRL", "IRELAND", ["Éire"]),
        ("ISL", "ICELAND", ["Ísland"]),
        ("HRV", "CROATIA", ["Hrvatska"]),
        ("CHE", "SWITZERLAND", ["Schweiz", "Suisse", "Svizzera"]),
        ("AUT", "AUSTRIA", ["Österreich"]),
        ("NLD", "NETHERLANDS", ["Holland", "Nederland"]),
        ("DNK", "DENMARK", ["Danmark"]),
        ("JPN", "JAPAN", ["Nippon", "Nihon"]),
        ("IND", "INDIA", ["Bharat"]),
        ("CHN", "CHINA", ["PRC", "People\'s Republic of China"]),
        ("KOR", "SOUTH KOREA", ["Korea", "Republic of Korea", "ROK"]),
        ("THA", "THAILAND", ["Siam"]),
        ("VNM", "VIETNAM", ["Viet Nam"]),
        ("IDN", "INDONESIA", []),
        ("SAU", "SAUDI ARABIA", ["KSA"]),
        ("TUR", "TURKEY", ["Türkiye"]),
        ("PHL", "PHILIPPINES", []),
        ("PAK", "PAKISTAN", []),
        ("IRN", "IRAN", ["Persia"]),
        ("IRQ", "IRAQ", []),
        ("USA", "UNITED STATES", ["USA", "America", "US", "United States of America"]),
        ("CAN", "CANADA", []),
        ("MEX", "MEXICO", ["México"]),
        ("BRA", "BRAZIL", ["Brasil"]),
        ("ARG", "ARGENTINA", []),
        ("CHL", "CHILE", []),
        ("COL", "COLOMBIA", []),
        ("PER", "PERU", ["Perú"]),
        ("CUB", "CUBA", []),
        ("ZAF", "SOUTH AFRICA", ["RSA"]),
        ("EGY", "EGYPT", ["Misr"]),
        ("MDG", "MADAGASCAR", []),
        ("NGA", "NIGERIA", []),
        ("KEN", "KENYA", []),
        ("MAR", "MOROCCO", ["Al Maghrib"]),
        ("ETH", "ETHIOPIA", []),
        ("TZA", "TANZANIA", []),
        ("AUS", "AUSTRALIA", []),
        ("NZL", "NEW ZEALAND", ["Aotearoa"]),
    ]
}
'''


def main():
    sf = shapefile.Reader(SHAPEFILE_PATH)
    fields = [f[0] for f in sf.fields[1:]]

    country_paths = {}
    found_countries = set()

    for shape_rec in sf.iterShapeRecords():
        rec = dict(zip(fields, shape_rec.record))
        admin = rec.get("ADMIN", "")
        adm0_a3 = rec.get("ADM0_A3", "")

        if admin not in TARGET_COUNTRIES:
            continue

        found_countries.add(admin)

        # Count total polygons and those above threshold for logging
        all_polys = get_polygon_parts(shape_rec.shape)
        above_threshold = [p for p in all_polys if polygon_area(p) >= MIN_POLYGON_AREA]

        svg_path = process_country(shape_rec.shape, adm0_a3)
        if svg_path:
            country_paths[adm0_a3] = svg_path
            total_pts = sum(len(p) for p in all_polys)
            # Count simplified points from the SVG path (each M or L = 1 point)
            simp_pts = svg_path.count(" M ") + svg_path.count(" L ") + 1
            print(f"  {admin} ({adm0_a3}): {len(above_threshold)} polys, "
                  f"{total_pts} raw → {simp_pts} simplified pts, {len(svg_path)} chars")

    # Check for missing countries
    missing = TARGET_COUNTRIES - found_countries
    if missing:
        print(f"\nWARNING: Missing countries: {missing}")

    # Write Swift files
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    path_data_file = os.path.join(OUTPUT_DIR, "CountryPathData.swift")
    with open(path_data_file, "w") as f:
        f.write(generate_swift_path_data(country_paths))
    print(f"\nWrote {path_data_file} ({len(country_paths)} countries)")

    metadata_file = os.path.join(OUTPUT_DIR, "CountryMetadata.swift")
    with open(metadata_file, "w") as f:
        f.write(generate_swift_metadata())
    print(f"Wrote {metadata_file}")


if __name__ == "__main__":
    main()
