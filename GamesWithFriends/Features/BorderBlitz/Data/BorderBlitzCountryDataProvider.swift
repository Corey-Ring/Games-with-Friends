//
//  CountryDataProvider.swift
//  BorderBlitz
//
//  Provides country data from generated Natural Earth path data
//

import Foundation

struct BorderBlitzCountryDataProvider {
    /// Returns all available countries with their SVG path data
    static func getAllCountries() -> [BorderBlitzCountry] {
        return BorderBlitzCountryMetadata.countries.compactMap { entry in
            guard let path = BorderBlitzCountryPathData.paths[entry.id] else {
                return nil
            }
            return BorderBlitzCountry(
                id: entry.id,
                name: entry.name,
                svgPath: path,
                alternateNames: entry.alternateNames
            )
        }
    }
}
