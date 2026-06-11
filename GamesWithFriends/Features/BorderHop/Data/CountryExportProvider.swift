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

    /// Returns distractor commodities for a "top export" quiz about `countryId`:
    /// other countries' #1 exports that do not appear anywhere in the target
    /// country's own export list (so every wrong answer is genuinely wrong).
    static func distractorExports(excluding countryId: String, count: Int) -> [String] {
        let targetExports = Set((exportData[countryId] ?? []).map { $0.lowercased() })

        var seen: Set<String> = []
        var pool: [String] = []
        for (id, exports) in exportData {
            guard id != countryId, let top = exports.first else { continue }
            let key = top.lowercased()
            guard !targetExports.contains(key), !seen.contains(key) else { continue }
            seen.insert(key)
            pool.append(top)
        }
        return Array(pool.shuffled().prefix(count))
    }
}
