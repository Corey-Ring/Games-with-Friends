import Foundation

// MARK: - CountryFlagProvider

/// Generates emoji flags from ISO alpha-3 country codes and provides
/// similar-flag distractor groups for flag quiz generation.
struct CountryFlagProvider {

    // MARK: - Public API

    /// Returns an emoji flag string for an ISO alpha-3 country code.
    /// Returns nil if no alpha-2 mapping is found.
    static func flag(for alpha3Code: String) -> String? {
        guard let alpha2 = alpha3ToAlpha2[alpha3Code] else { return nil }
        return emojiFlag(for: alpha2)
    }

    /// Returns other countries in the same similar-flag group as `alpha3Code`.
    /// Used to pick visually confusing distractors for flag quizzes.
    static func similarCountries(to alpha3Code: String) -> [String] {
        for group in similarFlagGroups {
            if group.contains(alpha3Code) {
                return group.filter { $0 != alpha3Code }
            }
        }
        return []
    }

    // MARK: - Flag Emoji Generation

    private static func emojiFlag(for alpha2: String) -> String {
        let base: UInt32 = 127397 // Unicode scalar offset for regional indicators
        var flag = ""
        for scalar in alpha2.uppercased().unicodeScalars {
            if let regionalIndicator = Unicode.Scalar(base + scalar.value) {
                flag.append(String(regionalIndicator))
            }
        }
        return flag
    }

    // MARK: - Alpha-3 → Alpha-2 Mapping (all 152 Border Hop countries)

    static let alpha3ToAlpha2: [String: String] = [
        "AFG": "AF", // Afghanistan
        "AGO": "AO", // Angola
        "ALB": "AL", // Albania
        "AND": "AD", // Andorra
        "ARE": "AE", // United Arab Emirates
        "ARG": "AR", // Argentina
        "ARM": "AM", // Armenia
        "AUT": "AT", // Austria
        "AZE": "AZ", // Azerbaijan
        "BDI": "BI", // Burundi
        "BEL": "BE", // Belgium
        "BEN": "BJ", // Benin
        "BFA": "BF", // Burkina Faso
        "BGD": "BD", // Bangladesh
        "BGR": "BG", // Bulgaria
        "BIH": "BA", // Bosnia and Herzegovina
        "BLR": "BY", // Belarus
        "BLZ": "BZ", // Belize
        "BOL": "BO", // Bolivia
        "BRA": "BR", // Brazil
        "BRN": "BN", // Brunei
        "BTN": "BT", // Bhutan
        "BWA": "BW", // Botswana
        "CAF": "CF", // Central African Republic
        "CAN": "CA", // Canada
        "CHE": "CH", // Switzerland
        "CHL": "CL", // Chile
        "CHN": "CN", // China
        "CIV": "CI", // Ivory Coast
        "CMR": "CM", // Cameroon
        "COD": "CD", // DR Congo
        "COG": "CG", // Republic of the Congo
        "COL": "CO", // Colombia
        "CRI": "CR", // Costa Rica
        "CZE": "CZ", // Czech Republic
        "DEU": "DE", // Germany
        "DJI": "DJ", // Djibouti
        "DNK": "DK", // Denmark
        "DZA": "DZ", // Algeria
        "ECU": "EC", // Ecuador
        "EGY": "EG", // Egypt
        "ERI": "ER", // Eritrea
        "ESP": "ES", // Spain
        "EST": "EE", // Estonia
        "ETH": "ET", // Ethiopia
        "FIN": "FI", // Finland
        "FRA": "FR", // France
        "GAB": "GA", // Gabon
        "GEO": "GE", // Georgia
        "GHA": "GH", // Ghana
        "GIN": "GN", // Guinea
        "GMB": "GM", // Gambia
        "GNB": "GW", // Guinea-Bissau
        "GNQ": "GQ", // Equatorial Guinea
        "GRC": "GR", // Greece
        "GTM": "GT", // Guatemala
        "GUF": "GF", // French Guiana
        "GUY": "GY", // Guyana
        "HND": "HN", // Honduras
        "HRV": "HR", // Croatia
        "HUN": "HU", // Hungary
        "IDN": "ID", // Indonesia
        "IND": "IN", // India
        "IRN": "IR", // Iran
        "IRQ": "IQ", // Iraq
        "ISR": "IL", // Israel
        "ITA": "IT", // Italy
        "JOR": "JO", // Jordan
        "KAZ": "KZ", // Kazakhstan
        "KEN": "KE", // Kenya
        "KGZ": "KG", // Kyrgyzstan
        "KHM": "KH", // Cambodia
        "KOR": "KR", // South Korea
        "KWT": "KW", // Kuwait
        "LAO": "LA", // Laos
        "LBN": "LB", // Lebanon
        "LBR": "LR", // Liberia
        "LBY": "LY", // Libya
        "LIE": "LI", // Liechtenstein
        "LSO": "LS", // Lesotho
        "LTU": "LT", // Lithuania
        "LUX": "LU", // Luxembourg
        "LVA": "LV", // Latvia
        "MAR": "MA", // Morocco
        "MCO": "MC", // Monaco
        "MDA": "MD", // Moldova
        "MEX": "MX", // Mexico
        "MKD": "MK", // North Macedonia
        "MLI": "ML", // Mali
        "MMR": "MM", // Myanmar
        "MNE": "ME", // Montenegro
        "MNG": "MN", // Mongolia
        "MOZ": "MZ", // Mozambique
        "MRT": "MR", // Mauritania
        "MWI": "MW", // Malawi
        "MYS": "MY", // Malaysia
        "NAM": "NA", // Namibia
        "NER": "NE", // Niger
        "NGA": "NG", // Nigeria
        "NIC": "NI", // Nicaragua
        "NLD": "NL", // Netherlands
        "NOR": "NO", // Norway
        "NPL": "NP", // Nepal
        "OMN": "OM", // Oman
        "PAK": "PK", // Pakistan
        "PAN": "PA", // Panama
        "PER": "PE", // Peru
        "PNG": "PG", // Papua New Guinea
        "POL": "PL", // Poland
        "PRK": "KP", // North Korea
        "PRT": "PT", // Portugal
        "PRY": "PY", // Paraguay
        "QAT": "QA", // Qatar
        "ROU": "RO", // Romania
        "RUS": "RU", // Russia
        "RWA": "RW", // Rwanda
        "SAU": "SA", // Saudi Arabia
        "SDN": "SD", // Sudan
        "SEN": "SN", // Senegal
        "SLE": "SL", // Sierra Leone
        "SLV": "SV", // El Salvador
        "SMR": "SM", // San Marino
        "SOM": "SO", // Somalia
        "SRB": "RS", // Serbia
        "SSD": "SS", // South Sudan
        "SUR": "SR", // Suriname
        "SVK": "SK", // Slovakia
        "SVN": "SI", // Slovenia
        "SWE": "SE", // Sweden
        "SWZ": "SZ", // Eswatini
        "SYR": "SY", // Syria
        "TCD": "TD", // Chad
        "TGO": "TG", // Togo
        "THA": "TH", // Thailand
        "TJK": "TJ", // Tajikistan
        "TKM": "TM", // Turkmenistan
        "TLS": "TL", // Timor-Leste
        "TUN": "TN", // Tunisia
        "TUR": "TR", // Turkey
        "TZA": "TZ", // Tanzania
        "UGA": "UG", // Uganda
        "UKR": "UA", // Ukraine
        "URY": "UY", // Uruguay
        "USA": "US", // United States
        "UZB": "UZ", // Uzbekistan
        "VAT": "VA", // Vatican City
        "VEN": "VE", // Venezuela
        "VNM": "VN", // Vietnam
        "YEM": "YE", // Yemen
        "ZAF": "ZA", // South Africa
        "ZMB": "ZM", // Zambia
        "ZWE": "ZW", // Zimbabwe
    ]

    // MARK: - Similar Flag Groups (alpha-3 codes)
    // Countries within the same group have visually similar flags.
    // Used to select challenging distractors for flag quizzes.

    static let similarFlagGroups: [[String]] = [
        ["ROU", "TCD"],                          // Romania / Chad (nearly identical tricolors)
        ["MCO", "IDN"],                          // Monaco / Indonesia (red-white bicolors)
        ["IRL", "CIV"],                          // Ireland / Ivory Coast (reversed green-white-orange)
        ["MLI", "SEN", "GIN"],                   // Pan-African vertical tricolors
        ["NLD", "LUX", "HRV"],                   // Red-white-blue variants
        ["AUS", "NZL"],                          // Southern Cross + Union Jack
        ["NOR", "ISL", "DNK"],                   // Nordic crosses
        ["SWE", "FIN"],                          // Nordic blue crosses
        ["COL", "ECU", "VEN"],                   // South American yellow-blue-red tricolors
        ["RUS", "SVN", "SVK"],                   // Slavic white-blue-red tricolors
        ["HUN", "BGR"],                          // Red-white-green / similar horizontal tricolors
        ["EGY", "IRQ", "SYR", "YEM"],            // Pan-Arab horizontal tricolors
        ["IND", "NER"],                          // Orange-white-green horizontal
        ["POL", "IDN", "MCO"],                   // White-red bicolors
        ["BEL", "DEU"],                          // Black-red-gold vertical tricolors
        ["ITA", "MEX"],                          // Green-white-red vertical tricolors
        ["USA", "LBR", "MYS"],                   // Stars and stripes variants
        ["SLV", "HND", "NIC", "GTM"],            // Central American blue-white-blue
        ["BHR", "QAT"],                          // Serrated-edge flags (note: BHR not in pool)
        ["JPN", "BGD"],                          // Circle on solid field
        ["CHN", "VNM"],                          // Red field with yellow star(s)
        ["FRA", "NLD", "LUX"],                   // Blue-white-red vertical tricolors
        ["CMR", "SEN"],                          // Green-red vertical with detail
        ["GHA", "GIN", "SEN"],                   // Pan-African horizontal tricolors
        ["EST", "LVA", "LTU"],                   // Baltic horizontal tricolors
        ["KAZ", "UZB", "TKM"],                   // Central Asian blue/green with detail
        ["COD", "COG", "CAF"],                   // Central African diagonal/tricolor
    ]
}
