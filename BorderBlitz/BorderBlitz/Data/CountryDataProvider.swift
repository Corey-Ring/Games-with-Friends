//
//  CountryDataProvider.swift
//  Border Blitz
//
//  Provides country data from generated Natural Earth path data
//

import Foundation

struct CountryDataProvider {
    /// Returns all available countries with their SVG path data
    static func getAllCountries() -> [Country] {
        return CountryMetadata.countries.compactMap { entry in
            guard let path = CountryPathData.paths[entry.id] else {
                return nil
            }
            return Country(
                id: entry.id,
                name: entry.name,
                svgPath: path,
                alternateNames: entry.alternateNames
            )
        }
    }
}
