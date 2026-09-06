import Foundation

/// A place players reasonably name that is not on the country list. Carries
/// the one-line reason so the game can say *why* instead of "Not recognized".
struct NotACountry: Equatable, NameMatchable {
    let name: String
    let alternateNames: [String]
    /// Completes the sentence "\(name) …".
    let reason: String

    init(_ name: String, _ reason: String, alternateNames: [String] = []) {
        self.name = name
        self.reason = reason
        self.alternateNames = alternateNames
    }

    var labels: [String] { [name] + alternateNames }

    var explanation: String { "\(name) \(reason)" }
}

extension CountriesData {
    private static let netherlands = "is part of the Kingdom of the Netherlands, so it isn't counted as its own country here."
    private static let unitedStates = "is a United States territory, so it isn't counted as its own country here."
    private static let unitedKingdom = "is part of the United Kingdom, so it isn't counted as its own country here."
    private static let britishTerritory = "is a British territory, so it isn't counted as its own country here."
    private static let france = "is part of France, so it isn't counted as its own country here."
    private static let denmark = "is part of the Kingdom of Denmark, so it isn't counted as its own country here."
    private static let china = "is a special administrative region of China, so it isn't counted as its own country here."
    private static let notListed = "isn't on this game's list of 195 countries."
    private static let continent = "is a continent, not a country."

    /// Well-known territories, regions, continents and former countries.
    /// Keep every label clear of `all` — a test enforces it.
    static let notCountries: [NotACountry] = [
        // Caribbean & Atlantic
        NotACountry("Curaçao", netherlands, alternateNames: ["Curacao"]),
        NotACountry("Aruba", netherlands),
        NotACountry("Sint Maarten", netherlands, alternateNames: ["Saint Martin", "St Martin"]),
        NotACountry("Puerto Rico", unitedStates),
        NotACountry("US Virgin Islands", unitedStates, alternateNames: ["Virgin Islands", "U S Virgin Islands"]),
        NotACountry("Bermuda", britishTerritory),
        NotACountry("Cayman Islands", britishTerritory, alternateNames: ["Caymans"]),
        NotACountry("British Virgin Islands", britishTerritory),
        NotACountry("Turks and Caicos", britishTerritory, alternateNames: ["Turks and Caicos Islands"]),
        NotACountry("Anguilla", britishTerritory),
        NotACountry("Montserrat", britishTerritory),
        NotACountry("Falkland Islands", britishTerritory, alternateNames: ["Falklands"]),
        NotACountry("Guadeloupe", france),
        NotACountry("Martinique", france),
        NotACountry("French Guiana", france),

        // Europe
        NotACountry("Scotland", unitedKingdom),
        NotACountry("Wales", unitedKingdom),
        NotACountry("Northern Ireland", unitedKingdom),
        NotACountry("Gibraltar", britishTerritory),
        NotACountry("Greenland", denmark),
        NotACountry("Faroe Islands", denmark, alternateNames: ["Faroes"]),
        NotACountry("Kosovo", notListed),
        NotACountry("Sicily", "is an island in Italy, not a country."),
        NotACountry("Corsica", "is an island in France, not a country."),
        NotACountry("Catalonia", "is a region of Spain, not a country."),

        // Asia & Pacific
        NotACountry("Hong Kong", china),
        NotACountry("Macau", china, alternateNames: ["Macao"]),
        NotACountry("Taiwan", notListed),
        NotACountry("Tibet", notListed),
        NotACountry("Guam", unitedStates),
        NotACountry("American Samoa", unitedStates),
        NotACountry("Hawaii", "is a state of the United States, not a country."),
        NotACountry("Bali", "is an island in Indonesia, not a country."),
        NotACountry("Dubai", "is a city in the United Arab Emirates, not a country."),
        NotACountry("French Polynesia", france, alternateNames: ["Tahiti"]),
        NotACountry("New Caledonia", france),
        NotACountry("Western Sahara", notListed),

        // Continents & the like
        NotACountry("Africa", continent),
        NotACountry("Asia", continent),
        NotACountry("Europe", continent),
        NotACountry("North America", continent),
        NotACountry("South America", continent),
        NotACountry("Oceania", continent),
        NotACountry("Antarctica", "has no government of its own, so it isn't a country."),
        NotACountry("Scandinavia", "is a region, not a country. Try Sweden, Norway or Denmark."),
        NotACountry("Middle East", "is a region, not a country."),
        NotACountry("Caribbean", "is a region, not a country."),

        // Former names & countries
        NotACountry("Yugoslavia", "no longer exists. Try Serbia, Croatia or Bosnia and Herzegovina."),
        NotACountry("Czechoslovakia", "split into Czechia and Slovakia in 1993."),
        NotACountry("Soviet Union", "broke up in 1991. Try Russia.", alternateNames: ["USSR", "U S S R"]),
        NotACountry("Persia", "is the old name for Iran."),
        NotACountry("Siam", "is the old name for Thailand."),
        NotACountry("Ceylon", "is the old name for Sri Lanka."),
        NotACountry("Rhodesia", "is the old name for Zimbabwe."),
        NotACountry("Abyssinia", "is the old name for Ethiopia."),
    ]

    /// The not-a-country entry a typed guess refers to, if any. Uses the same
    /// forgiving matcher as real countries so a misspelt territory still gets
    /// its explanation.
    static func notACountry(matching input: String) -> NotACountry? {
        CountryMatcher.resolve(input, in: notCountries)
    }
}
