import SwiftUI

/// Projects lat/lon coordinates to canvas space and provides hit testing + camera fitting.
///
/// Projection is Web-Mercator (clamped to ±78° latitude) so local shapes stay accurate at
/// high latitudes — with plain equirectangular, northern countries render squashed and
/// neighborhood framing looks wrong. Rings that cross the antimeridian are unwrapped
/// (longitudes kept continuous, so Russia's path may extend past the right canvas edge
/// instead of smearing across the whole map); `wrapOffsets(for:)` tells the drawing code
/// when to draw a second copy shifted by one world-width.
class MapRenderer {
    struct ProjectedCountry {
        let id: String
        let path: CGPath
        let centroid: CGPoint     // canvas coords, x normalized into [0, canvas width)
        let boundingBox: CGRect   // path bounds — may extend past canvas edges (unwrapped rings)
        let focusBox: CGRect      // mainland-ring bounds, clamped — what the camera should frame
    }

    private(set) var projectedCountries: [String: ProjectedCountry] = [:]
    private(set) var decorativeCountries: [String: ProjectedCountry] = [:]
    let canvasSize: CGSize

    /// Set of game country IDs for distinguishing game vs decorative
    private let gameCountryIds: Set<String>

    /// Maximum latitude rendered (Mercator blows up at the poles)
    private static let maxLatitude: Double = 78.0
    /// Largest extent the camera should ever try to frame for a single country.
    /// Keeps Russia/USA/Canada from forcing a whole-hemisphere zoom-out.
    private static let maxFocusExtent = CGSize(width: 460, height: 340)

    private let mercScale: CGFloat
    private let maxMercY: CGFloat

    /// One combined path of all land masses, for the mini-map overview
    private(set) lazy var combinedLandPath: CGPath = {
        let combined = CGMutablePath()
        for (_, projected) in decorativeCountries { combined.addPath(projected.path) }
        for (_, projected) in projectedCountries { combined.addPath(projected.path) }
        return combined
    }()

    init(countries: [BorderHopCountry], geoPolygons: [String: GeoCountryPolygon], canvasSize requestedWidth: CGFloat = 2000) {
        let scale = requestedWidth / (2 * .pi)
        let maxLatRad = Self.maxLatitude * .pi / 180
        let maxY = CGFloat(log(tan(.pi / 4 + maxLatRad / 2)))
        self.mercScale = scale
        self.maxMercY = maxY
        self.canvasSize = CGSize(width: requestedWidth, height: 2 * maxY * scale)
        self.gameCountryIds = Set(countries.map { $0.id })
        buildProjections(countries: countries, geoPolygons: geoPolygons)
    }

    // MARK: - Mercator Projection

    func project(latitude: Double, longitude: Double) -> CGPoint {
        let x = CGFloat(longitude + 180) / 360 * canvasSize.width
        let clampedLat = min(max(latitude, -Self.maxLatitude), Self.maxLatitude)
        let latRad = clampedLat * .pi / 180
        let mercY = CGFloat(log(tan(.pi / 4 + latRad / 2)))
        let y = (maxMercY - mercY) * mercScale
        return CGPoint(x: x, y: y)
    }

    // MARK: - World Wrapping Helpers

    /// Horizontal offsets at which a country's path must be drawn so unwrapped
    /// rings (crossing the antimeridian) appear on the visible canvas.
    func wrapOffsets(for projected: ProjectedCountry) -> [CGFloat] {
        var offsets: [CGFloat] = [0]
        if projected.boundingBox.maxX > canvasSize.width { offsets.append(-canvasSize.width) }
        if projected.boundingBox.minX < 0 { offsets.append(canvasSize.width) }
        return offsets
    }

    /// The wrapped variant of `point` whose x is closest to `anchor` —
    /// e.g. Alaska's centroid seen from Chukotka should sit just east, not a world away.
    func nearestWrapped(_ point: CGPoint, to anchor: CGPoint) -> CGPoint {
        var best = point
        var bestDist = abs(point.x - anchor.x)
        for dx in [-canvasSize.width, canvasSize.width] {
            let candidate = point.x + dx
            if abs(candidate - anchor.x) < bestDist {
                bestDist = abs(candidate - anchor.x)
                best = CGPoint(x: candidate, y: point.y)
            }
        }
        return best
    }

    // MARK: - Hit Testing

    /// Hit test in canvas coordinates. `tolerance` is in canvas units — the view converts
    /// a constant screen tolerance by dividing by the current zoom.
    func hitTest(point: CGPoint, priorityIds: Set<String>, tolerance: CGFloat = 12) -> String? {
        let offsets: [CGFloat] = [0, -canvasSize.width, canvasSize.width]

        // 1. Exact polygon hit — priority countries first so a frontier wins over
        //    an overlapping fogged shape.
        for prioritized in [true, false] {
            for (id, projected) in projectedCountries {
                guard priorityIds.contains(id) == prioritized else { continue }
                for dx in offsets {
                    let p = CGPoint(x: point.x + dx, y: point.y)
                    if projected.boundingBox.insetBy(dx: -tolerance, dy: -tolerance).contains(p),
                       projected.path.contains(p) {
                        return id
                    }
                }
            }
        }

        // 2. Near-miss on a priority country's bounding box (generous — these are
        //    the countries the player is trying to tap).
        for id in priorityIds {
            guard let projected = projectedCountries[id] else { continue }
            for dx in offsets {
                let p = CGPoint(x: point.x + dx, y: point.y)
                if projected.boundingBox.insetBy(dx: -tolerance * 2, dy: -tolerance * 2).contains(p) {
                    return id
                }
            }
        }

        // 3. Fallback: closest centroid, with priority countries weighted closer
        var closestId: String?
        var closestDist = tolerance * 3
        for (id, projected) in projectedCountries {
            let wrapped = nearestWrapped(projected.centroid, to: point)
            let dist = hypot(point.x - wrapped.x, point.y - wrapped.y)
            let effectiveDist = priorityIds.contains(id) ? dist * 0.6 : dist
            if effectiveDist < closestDist {
                closestDist = effectiveDist
                closestId = id
            }
        }
        return closestId
    }

    // MARK: - Camera Fitting

    /// Canvas rect the camera should frame to show the current country and as many
    /// neighbors as reasonably fit. Each neighbor's pull is clamped so a faraway
    /// centroid (Russia's, seen from Latvia) can't drag the view across the map —
    /// neighbors that don't fit are handled by the view's edge indicators instead.
    func neighborhoodRect(
        currentId: String,
        neighborIds: [String],
        maxNeighborInfluence: CGFloat = 340
    ) -> CGRect? {
        guard let current = projectedCountries[currentId] else { return nil }

        let anchor = current.centroid
        var rect = current.focusBox.insetBy(dx: -30, dy: -24)

        let labelRoom = CGSize(width: 90, height: 48)
        for id in neighborIds {
            guard let neighbor = projectedCountries[id] else { continue }
            let wrapped = nearestWrapped(neighbor.centroid, to: anchor)
            let dx = min(max(wrapped.x - anchor.x, -maxNeighborInfluence), maxNeighborInfluence)
            let dy = min(max(wrapped.y - anchor.y, -maxNeighborInfluence), maxNeighborInfluence)
            let point = CGPoint(x: anchor.x + dx, y: anchor.y + dy)
            rect = rect.union(CGRect(
                x: point.x - labelRoom.width / 2,
                y: point.y - labelRoom.height / 2,
                width: labelRoom.width,
                height: labelRoom.height
            ))
        }

        return rect
    }

    // MARK: - Private

    private func buildProjections(countries: [BorderHopCountry], geoPolygons: [String: GeoCountryPolygon]) {
        // Build game countries — use game lat/lon for centroid (avoids overseas territory issues)
        for country in countries {
            if let geo = geoPolygons[country.id] {
                let gameCentroid = project(latitude: country.latitude, longitude: country.longitude)
                let projected = buildProjectedCountry(id: country.id, geo: geo, knownCentroid: gameCentroid)
                projectedCountries[country.id] = projected
            } else {
                // Microstate fallback — small circle at centroid
                let projected = buildFallbackCountry(country: country)
                projectedCountries[country.id] = projected
            }
        }

        // Build decorative countries (in GeoJSON but not in game)
        for (geoId, geo) in geoPolygons where !gameCountryIds.contains(geoId) {
            let projected = buildProjectedCountry(id: geoId, geo: geo, knownCentroid: nil)
            decorativeCountries[geoId] = projected
        }
    }

    private struct ProjectedRing {
        let points: [CGPoint]
        let bounds: CGRect
        let centroid: CGPoint
    }

    /// Project one ring with longitude unwrapping: consecutive points never jump more
    /// than half a world, so antimeridian-crossing rings stay contiguous (extending
    /// past a canvas edge) instead of streaking across the map.
    private func projectRing(_ ring: [[Double]]) -> ProjectedRing? {
        var points: [CGPoint] = []
        points.reserveCapacity(ring.count)

        var lonOffset: Double = 0
        var previousLon: Double?

        for coord in ring {
            guard coord.count >= 2 else { continue }
            var lon = coord[0]
            if let prev = previousLon {
                if lon + lonOffset - prev > 180 { lonOffset -= 360 }
                else if lon + lonOffset - prev < -180 { lonOffset += 360 }
            }
            lon += lonOffset
            previousLon = lon
            points.append(project(latitude: coord[1], longitude: lon))
        }

        guard points.count >= 3 else { return nil }

        var minX = points[0].x, maxX = points[0].x, minY = points[0].y, maxY = points[0].y
        var sumX: CGFloat = 0, sumY: CGFloat = 0
        for p in points {
            minX = min(minX, p.x); maxX = max(maxX, p.x)
            minY = min(minY, p.y); maxY = max(maxY, p.y)
            sumX += p.x; sumY += p.y
        }
        let count = CGFloat(points.count)
        return ProjectedRing(
            points: points,
            bounds: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY),
            centroid: CGPoint(x: sumX / count, y: sumY / count)
        )
    }

    /// Build projected country from GeoJSON polygons.
    /// - `knownCentroid`: if provided (from game data), used as the centroid and as the
    ///   anchor for picking the "mainland" ring (so France's focus box is metropolitan
    ///   France, not the bbox including French Guiana).
    private func buildProjectedCountry(id: String, geo: GeoCountryPolygon, knownCentroid: CGPoint?) -> ProjectedCountry {
        let path = CGMutablePath()
        var rings: [ProjectedRing] = []

        for rawRing in geo.rings {
            guard let ring = projectRing(rawRing) else { continue }
            path.move(to: ring.points[0])
            for point in ring.points.dropFirst() {
                path.addLine(to: point)
            }
            path.closeSubpath()
            rings.append(ring)
        }

        // Centroid: known game centroid, or centroid of the largest ring
        let largestRing = rings.max { $0.points.count < $1.points.count }
        var centroid = knownCentroid ?? largestRing?.centroid ?? .zero
        centroid.x = normalizedX(centroid.x)

        // Mainland ring: nearest to the game centroid (wrap-aware), else the largest
        let mainlandRing: ProjectedRing?
        if let knownCentroid {
            mainlandRing = rings.min {
                wrappedDistance($0.centroid, to: knownCentroid) < wrappedDistance($1.centroid, to: knownCentroid)
            }
        } else {
            mainlandRing = largestRing
        }

        let focusBox = clampedFocusBox(mainlandRing?.bounds ?? path.boundingBox, anchor: centroid)

        return ProjectedCountry(
            id: id,
            path: path,
            centroid: centroid,
            boundingBox: path.boundingBox,
            focusBox: focusBox
        )
    }

    /// Shrink an oversized mainland box around the anchor point so giant countries
    /// (Russia, Canada) get a playable frame instead of a hemisphere.
    private func clampedFocusBox(_ box: CGRect, anchor: CGPoint) -> CGRect {
        var result = box
        // Align the anchor into the box's (possibly unwrapped) coordinate range
        var alignedAnchor = anchor
        if abs(anchor.x - box.midX) > canvasSize.width / 2 {
            alignedAnchor.x += anchor.x < box.midX ? canvasSize.width : -canvasSize.width
        }

        if box.width > Self.maxFocusExtent.width {
            let x = min(max(alignedAnchor.x - Self.maxFocusExtent.width / 2, box.minX), box.maxX - Self.maxFocusExtent.width)
            result = CGRect(x: x, y: result.minY, width: Self.maxFocusExtent.width, height: result.height)
        }
        if box.height > Self.maxFocusExtent.height {
            let y = min(max(alignedAnchor.y - Self.maxFocusExtent.height / 2, box.minY), box.maxY - Self.maxFocusExtent.height)
            result = CGRect(x: result.minX, y: y, width: result.width, height: Self.maxFocusExtent.height)
        }
        return result
    }

    private func wrappedDistance(_ point: CGPoint, to anchor: CGPoint) -> CGFloat {
        let wrapped = nearestWrapped(point, to: anchor)
        return hypot(wrapped.x - anchor.x, wrapped.y - anchor.y)
    }

    private func normalizedX(_ x: CGFloat) -> CGFloat {
        var result = x.truncatingRemainder(dividingBy: canvasSize.width)
        if result < 0 { result += canvasSize.width }
        return result
    }

    /// Fallback for microstates without GeoJSON data — renders as a small circle
    private func buildFallbackCountry(country: BorderHopCountry) -> ProjectedCountry {
        let centroid = project(latitude: country.latitude, longitude: country.longitude)
        let radius: CGFloat = 4
        let box = CGRect(x: centroid.x - radius, y: centroid.y - radius, width: radius * 2, height: radius * 2)
        let path = CGMutablePath()
        path.addEllipse(in: box)

        return ProjectedCountry(
            id: country.id,
            path: path,
            centroid: centroid,
            boundingBox: box,
            focusBox: box
        )
    }
}
