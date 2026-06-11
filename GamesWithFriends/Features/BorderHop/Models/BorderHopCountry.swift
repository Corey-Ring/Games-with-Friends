import Foundation

struct BorderHopCountry: Identifiable, Codable, Hashable {
    let id: String              // ISO 3166-1 alpha-3 ("FRA")
    let name: String            // Display name ("France")
    let capital: String         // Primary/administrative capital ("Paris")
    let region: String          // "Europe", "Asia", "Africa", "Americas", "Oceania"
    let subRegion: String       // "Western Europe", "Southeast Asia", etc.
    let latitude: Double
    let longitude: Double
    let neighbors: [String]     // Adjacent country IDs (land borders only)

    var coordinate: (lat: Double, lon: Double) {
        (latitude, longitude)
    }
}

enum CountryState: Equatable {
    case fogged
    case frontier
    case visited
    case current
    case destination
}
