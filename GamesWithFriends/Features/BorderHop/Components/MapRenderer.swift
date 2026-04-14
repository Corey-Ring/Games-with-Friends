import SwiftUI

/// Projects lat/lon coordinates to screen space and provides hit testing
class MapRenderer {
    struct ProjectedCountry {
        let id: String
        let path: CGPath
        let centroid: CGPoint
        let boundingBox: CGRect
    }

    private(set) var projectedCountries: [String: ProjectedCountry] = [:]
    private(set) var decorativeCountries: [String: ProjectedCountry] = [:]
    let canvasSize: CGSize

    /// Set of game country IDs for distinguishing game vs decorative
    private let gameCountryIds: Set<String>

    init(countries: [BorderHopCountry], geoPolygons: [String: GeoCountryPolygon], canvasSize: CGSize) {
        self.canvasSize = canvasSize
        self.gameCountryIds = Set(countries.map { $0.id })
        buildProjections(countries: countries, geoPolygons: geoPolygons)
    }

    // MARK: - Equirectangular Projection

    func project(latitude: Double, longitude: Double) -> CGPoint {
        let x = (longitude + 180) / 360 * canvasSize.width
        let y = (90 - latitude) / 180 * canvasSize.height
        return CGPoint(x: x, y: y)
    }

    // MARK: - Hit Testing

    func hitTest(point: CGPoint) -> String? {
        hitTest(point: point, priorityIds: [])
    }

    func hitTest(point: CGPoint, priorityIds: Set<String>) -> String? {
        // 1. Check priority countries (frontier/destination) first with generous tolerance
        for id in priorityIds {
            guard let projected = projectedCountries[id] else { continue }
            if projected.boundingBox.insetBy(dx: -30, dy: -30).contains(point) {
                if projected.path.contains(point) {
                    return id
                }
            }
        }

        // 2. Check priority countries with expanded bounding box (looser — catches near-misses)
        for id in priorityIds {
            guard let projected = projectedCountries[id] else { continue }
            if projected.boundingBox.insetBy(dx: -30, dy: -30).contains(point) {
                return id
            }
        }

        // 3. Standard exact-path hit test for all game countries
        for (id, projected) in projectedCountries {
            if projected.boundingBox.insetBy(dx: -10, dy: -10).contains(point) {
                if projected.path.contains(point) {
                    return id
                }
            }
        }

        // 4. Fallback: find closest centroid within 35pt, prioritizing active countries
        var closestId: String?
        var closestDist: CGFloat = 35

        for (id, projected) in projectedCountries {
            let dist = hypot(point.x - projected.centroid.x, point.y - projected.centroid.y)
            // Give priority countries a distance bonus (effectively larger hit area)
            let effectiveDist = priorityIds.contains(id) ? dist * 0.6 : dist
            if effectiveDist < closestDist {
                closestDist = effectiveDist
                closestId = id
            }
        }
        return closestId
    }

    /// Compute the anchor point and canvas extent the camera must fit when showing
    /// `currentId` and its neighbors. Anchors on the current country's centroid so the
    /// player stays visually centered, sizes the view from the current country's actual
    /// polygon so zoom adapts to country size, and clamps each neighbor's pull at
    /// `maxNeighborInfluence` so a faraway centroid (e.g. Russia's Siberian centroid
    /// when the player is in Latvia) can't drag the view across the map.
    func neighborhoodFit(
        currentId: String,
        neighborIds: [String],
        maxNeighborInfluence: CGFloat = 300
    ) -> (anchor: CGPoint, size: CGSize)? {
        guard let current = projectedCountries[currentId] else { return nil }

        let anchor = current.centroid
        let polyBox = current.boundingBox

        var halfWidth = max(anchor.x - polyBox.minX, polyBox.maxX - anchor.x)
        var halfHeight = max(anchor.y - polyBox.minY, polyBox.maxY - anchor.y)

        let neighborPad: CGFloat = 40
        for id in neighborIds {
            guard let neighbor = projectedCountries[id] else { continue }
            let dx = min(abs(neighbor.centroid.x - anchor.x), maxNeighborInfluence)
            let dy = min(abs(neighbor.centroid.y - anchor.y), maxNeighborInfluence)
            halfWidth = max(halfWidth, dx + neighborPad)
            halfHeight = max(halfHeight, dy + neighborPad)
        }

        return (anchor, CGSize(width: halfWidth * 2, height: halfHeight * 2))
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

    /// Build projected country from GeoJSON polygons.
    /// - `knownCentroid`: if provided (from game data), used as the centroid.
    ///   Otherwise, uses the centroid of the largest polygon ring.
    private func buildProjectedCountry(id: String, geo: GeoCountryPolygon, knownCentroid: CGPoint?) -> ProjectedCountry {
        let path = CGMutablePath()
        var largestRingPoints: [CGPoint] = []
        var largestRingCount = 0

        for ring in geo.rings {
            guard ring.count >= 3 else { continue }

            var ringPoints: [CGPoint] = []
            for (i, coord) in ring.enumerated() {
                guard coord.count >= 2 else { continue }
                let point = project(latitude: coord[1], longitude: coord[0])

                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
                ringPoints.append(point)
            }
            path.closeSubpath()

            // Track the largest ring for fallback centroid
            if ringPoints.count > largestRingCount {
                largestRingCount = ringPoints.count
                largestRingPoints = ringPoints
            }
        }

        // Use known centroid (from game data) or compute from largest polygon
        let centroid: CGPoint
        if let knownCentroid {
            centroid = knownCentroid
        } else if !largestRingPoints.isEmpty {
            let sumX = largestRingPoints.reduce(0.0) { $0 + $1.x }
            let sumY = largestRingPoints.reduce(0.0) { $0 + $1.y }
            centroid = CGPoint(x: sumX / CGFloat(largestRingPoints.count), y: sumY / CGFloat(largestRingPoints.count))
        } else {
            centroid = .zero
        }

        return ProjectedCountry(
            id: id,
            path: path,
            centroid: centroid,
            boundingBox: path.boundingBox
        )
    }

    /// Fallback for microstates without GeoJSON data — renders as a small circle
    private func buildFallbackCountry(country: BorderHopCountry) -> ProjectedCountry {
        let centroid = project(latitude: country.latitude, longitude: country.longitude)
        let radius: CGFloat = 8
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(
            x: centroid.x - radius,
            y: centroid.y - radius,
            width: radius * 2,
            height: radius * 2
        ))

        return ProjectedCountry(
            id: country.id,
            path: path,
            centroid: centroid,
            boundingBox: CGRect(x: centroid.x - radius, y: centroid.y - radius, width: radius * 2, height: radius * 2)
        )
    }
}
