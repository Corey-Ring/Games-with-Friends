import Foundation

struct CountryExport: Codable {
    let id: String        // alpha-3
    let name: String      // display name
    let exports: [String] // 3-5 commodity strings, ordered by value
}

struct CountryExportProvider {

    /// All export data keyed by alpha-3 country ID
    private static var exportData: [String: [String]] = {
        guard let url = Bundle.main.url(forResource: "country_exports", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([CountryExport].self, from: data) else {
            return [:]
        }
        var map: [String: [String]] = [:]
        for entry in entries {
            map[entry.id] = entry.exports
        }
        return map
    }()

    /// Returns the export list for a country, or nil if not available
    static func exports(for countryId: String) -> [String]? {
        let list = exportData[countryId]
        return (list?.isEmpty == false) ? list : nil
    }

    /// Returns random distractor country IDs whose top-export lists can serve
    /// as wrong answers for the country whose ID is `countryId`. Truly random
    /// across all countries with export data — no region weighting.
    static func distractorCountries(excluding countryId: String, count: Int) -> [String] {
        let candidates = exportData.keys.filter { $0 != countryId }
        return Array(candidates.shuffled().prefix(count))
    }
}
