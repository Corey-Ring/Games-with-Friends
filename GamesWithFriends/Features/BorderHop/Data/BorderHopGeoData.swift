import Foundation

/// Parsed polygon data for a single country from GeoJSON
struct GeoCountryPolygon {
    let id: String                    // ADM0_A3 code (mapped to game ID)
    let rings: [[[Double]]]           // Array of polygon outer rings; each ring is [[lon, lat], ...]
}

/// Loads and parses the bundled Natural Earth GeoJSON for real country boundaries
enum BorderHopGeoData {

    // MARK: - ID Mapping

    /// GeoJSON ADM0_A3 codes that differ from our game country IDs
    private static let idMapping: [String: String] = [
        "SDS": "SSD"   // South Sudan
    ]

    /// Features to skip entirely
    private static let skipIds: Set<String> = [
        "ATA"  // Antarctica — no land borders
    ]

    // MARK: - Public

    /// Load and parse GeoJSON features, keyed by game-compatible country ID
    static func loadFeatures() -> [String: GeoCountryPolygon] {
        guard let url = Bundle.main.url(forResource: "ne_110m_admin_0_countries", withExtension: "geojson") else {
            print("[BorderHopGeoData] GeoJSON file not found in bundle")
            return [:]
        }

        guard let data = try? Data(contentsOf: url) else {
            print("[BorderHopGeoData] Failed to read GeoJSON data")
            return [:]
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            print("[BorderHopGeoData] Failed to parse GeoJSON structure")
            return [:]
        }

        var result: [String: GeoCountryPolygon] = [:]

        for feature in features {
            guard let properties = feature["properties"] as? [String: Any],
                  let rawId = properties["ADM0_A3"] as? String,
                  let geometry = feature["geometry"] as? [String: Any],
                  let geometryType = geometry["type"] as? String else {
                continue
            }

            // Skip excluded features
            if skipIds.contains(rawId) { continue }

            // Map to game ID if needed
            let countryId = idMapping[rawId] ?? rawId

            // Extract outer rings based on geometry type
            var rings: [[[Double]]] = []

            if geometryType == "Polygon" {
                // Polygon: coordinates is [ring1, ring2, ...] — take only outer ring (first)
                if let coordinates = geometry["coordinates"] as? [[[Double]]],
                   let outerRing = coordinates.first {
                    rings.append(outerRing)
                }
            } else if geometryType == "MultiPolygon" {
                // MultiPolygon: coordinates is [polygon1, polygon2, ...] — take outer ring of each
                if let coordinates = geometry["coordinates"] as? [[[[Double]]]] {
                    for polygon in coordinates {
                        if let outerRing = polygon.first {
                            rings.append(outerRing)
                        }
                    }
                }
            }

            guard !rings.isEmpty else { continue }

            result[countryId] = GeoCountryPolygon(id: countryId, rings: rings)
        }

        return result
    }
}
