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

    func boundingBox(for countryIds: [String]) -> CGRect {
        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude

        for id in countryIds {
            guard let projected = projectedCountries[id] else { continue }
            let box = projected.boundingBox
            minX = min(minX, box.minX)
            minY = min(minY, box.minY)
            maxX = max(maxX, box.maxX)
            maxY = max(maxY, box.maxY)
        }

        guard minX < maxX else { return .zero }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Private

    private func buildProjections(countries: [BorderHopCountry], geoPolygons: [String: GeoCountryPolygon]) {
        // Build game countries
        for country in countries {
            if let geo = geoPolygons[country.id] {
                // Real polygon from GeoJSON
                let projected = buildProjectedCountry(id: country.id, geo: geo)
                projectedCountries[country.id] = projected
            } else {
                // Microstate fallback — small circle at centroid
                let projected = buildFallbackCountry(country: country)
                projectedCountries[country.id] = projected
            }
        }

        // Build decorative countries (in GeoJSON but not in game)
        for (geoId, geo) in geoPolygons where !gameCountryIds.contains(geoId) {
            let projected = buildProjectedCountry(id: geoId, geo: geo)
            decorativeCountries[geoId] = projected
        }
    }

    private func buildProjectedCountry(id: String, geo: GeoCountryPolygon) -> ProjectedCountry {
        let path = CGMutablePath()
        var allPoints: [CGPoint] = []

        for ring in geo.rings {
            guard ring.count >= 3 else { continue }

            for (i, coord) in ring.enumerated() {
                guard coord.count >= 2 else { continue }
                let point = project(latitude: coord[1], longitude: coord[0])

                if i == 0 {
                    path.move(to: point)
                } else {
                    path.addLine(to: point)
                }
                allPoints.append(point)
            }
            path.closeSubpath()
        }

        // Compute centroid as average of all vertices
        let centroid: CGPoint
        if allPoints.isEmpty {
            centroid = .zero
        } else {
            let sumX = allPoints.reduce(0.0) { $0 + $1.x }
            let sumY = allPoints.reduce(0.0) { $0 + $1.y }
            centroid = CGPoint(x: sumX / CGFloat(allPoints.count), y: sumY / CGFloat(allPoints.count))
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
