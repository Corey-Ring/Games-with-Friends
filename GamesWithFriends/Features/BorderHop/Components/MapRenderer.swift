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
    let canvasSize: CGSize

    init(countries: [BorderHopCountry], canvasSize: CGSize) {
        self.canvasSize = canvasSize
        buildProjections(countries: countries, canvasSize: canvasSize)
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
                return id
            }
        }

        // 2. Standard exact-path hit test with expanded bounding box
        for (id, projected) in projectedCountries {
            if projected.boundingBox.insetBy(dx: -20, dy: -20).contains(point) {
                if projected.path.contains(point) {
                    return id
                }
            }
        }

        // 3. Fallback: find closest centroid within 35pt, prioritizing active countries
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

    private func buildProjections(countries: [BorderHopCountry], canvasSize: CGSize) {
        for country in countries {
            let centroid = project(latitude: country.latitude, longitude: country.longitude)

            // Create a simple circular/rectangular shape for each country
            // centered at the projected centroid. The size varies by rough area.
            let size = countrySize(for: country)
            let path = CGMutablePath()
            let rect = CGRect(
                x: centroid.x - size.width / 2,
                y: centroid.y - size.height / 2,
                width: size.width,
                height: size.height
            )
            path.addRoundedRect(in: rect, cornerWidth: size.width * 0.2, cornerHeight: size.height * 0.2)

            projectedCountries[country.id] = ProjectedCountry(
                id: country.id,
                path: path,
                centroid: centroid,
                boundingBox: rect
            )
        }
    }

    /// Rough sizing based on country significance — larger countries get bigger shapes
    private func countrySize(for country: BorderHopCountry) -> CGSize {
        let neighborCount = country.neighbors.count
        let baseSize: CGFloat

        switch country.id {
        case "RUS": baseSize = 90
        case "CHN", "USA", "CAN", "BRA": baseSize = 65
        case "IND", "ARG", "KAZ", "DZA", "COD", "SAU": baseSize = 50
        case "MEX", "IDN", "IRN", "MNG", "PER", "TCD", "NER", "MLI", "AGO", "ZAF", "ETH", "EGY", "LBY", "SDN", "COL": baseSize = 40
        default:
            if neighborCount >= 6 { baseSize = 35 }
            else if neighborCount >= 4 { baseSize = 28 }
            else if neighborCount >= 2 { baseSize = 22 }
            else { baseSize = 22 }
        }

        // Slightly randomize aspect ratio to avoid uniform look
        let aspect = 0.8 + CGFloat(country.id.hashValue & 0xFF) / 640.0
        return CGSize(width: baseSize * aspect, height: baseSize / aspect)
    }
}
