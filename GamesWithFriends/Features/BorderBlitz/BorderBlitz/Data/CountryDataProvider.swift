//
//  CountryDataProvider.swift
//  Border Blitz
//
//  Provides country data with simplified border coordinates
//

import Foundation
import CoreGraphics

struct CountryDataProvider {
    /// Returns all available countries with their border coordinates
    static func getAllCountries() -> [Country] {
        return [
            // Italy (boot shape)
            Country(
                id: "ITA",
                name: "ITALY",
                borderPoints: italyBorder,
                alternateNames: ["Repubblica Italiana"]
            ),

            // France (hexagon)
            Country(
                id: "FRA",
                name: "FRANCE",
                borderPoints: franceBorder,
                alternateNames: ["République française"]
            ),

            // Spain
            Country(
                id: "ESP",
                name: "SPAIN",
                borderPoints: spainBorder,
                alternateNames: ["España", "Kingdom of Spain"]
            ),

            // Germany
            Country(
                id: "DEU",
                name: "GERMANY",
                borderPoints: germanyBorder,
                alternateNames: ["Deutschland"]
            ),

            // United Kingdom
            Country(
                id: "GBR",
                name: "UNITED KINGDOM",
                borderPoints: ukBorder,
                alternateNames: ["UK", "Britain", "Great Britain", "England"]
            ),

            // Japan (island chain)
            Country(
                id: "JPN",
                name: "JAPAN",
                borderPoints: japanBorder,
                alternateNames: ["Nippon", "Nihon"]
            ),

            // Australia
            Country(
                id: "AUS",
                name: "AUSTRALIA",
                borderPoints: australiaBorder,
                alternateNames: []
            ),

            // Brazil
            Country(
                id: "BRA",
                name: "BRAZIL",
                borderPoints: brazilBorder,
                alternateNames: ["Brasil"]
            ),

            // Canada
            Country(
                id: "CAN",
                name: "CANADA",
                borderPoints: canadaBorder,
                alternateNames: []
            ),

            // India
            Country(
                id: "IND",
                name: "INDIA",
                borderPoints: indiaBorder,
                alternateNames: ["Bharat"]
            ),

            // China
            Country(
                id: "CHN",
                name: "CHINA",
                borderPoints: chinaBorder,
                alternateNames: ["PRC", "People's Republic of China"]
            ),

            // United States
            Country(
                id: "USA",
                name: "UNITED STATES",
                borderPoints: usaBorder,
                alternateNames: ["USA", "America", "United States of America", "US"]
            ),

            // Mexico
            Country(
                id: "MEX",
                name: "MEXICO",
                borderPoints: mexicoBorder,
                alternateNames: ["México"]
            ),

            // South Korea
            Country(
                id: "KOR",
                name: "SOUTH KOREA",
                borderPoints: southKoreaBorder,
                alternateNames: ["Korea", "Republic of Korea", "ROK"]
            ),

            // Norway
            Country(
                id: "NOR",
                name: "NORWAY",
                borderPoints: norwayBorder,
                alternateNames: ["Norge"]
            )
        ]
    }

    // MARK: - Border Coordinates (Simplified)

    private static let italyBorder: [CGPoint] = [
        CGPoint(x: 50, y: 20),   // North
        CGPoint(x: 80, y: 30),
        CGPoint(x: 85, y: 50),
        CGPoint(x: 90, y: 80),   // Heel
        CGPoint(x: 75, y: 90),
        CGPoint(x: 60, y: 100),  // Toe
        CGPoint(x: 50, y: 95),
        CGPoint(x: 40, y: 85),
        CGPoint(x: 35, y: 70),
        CGPoint(x: 30, y: 50),   // West coast
        CGPoint(x: 35, y: 30),
        CGPoint(x: 45, y: 20)
    ]

    private static let franceBorder: [CGPoint] = [
        CGPoint(x: 20, y: 20),   // Northwest
        CGPoint(x: 80, y: 25),   // Northeast
        CGPoint(x: 85, y: 50),   // East
        CGPoint(x: 75, y: 85),   // Southeast
        CGPoint(x: 40, y: 90),   // South
        CGPoint(x: 15, y: 75),   // Southwest
        CGPoint(x: 10, y: 40)    // West
    ]

    private static let spainBorder: [CGPoint] = [
        CGPoint(x: 15, y: 30),   // Northwest
        CGPoint(x: 85, y: 25),   // Northeast
        CGPoint(x: 90, y: 50),   // East
        CGPoint(x: 80, y: 75),   // Southeast
        CGPoint(x: 50, y: 85),   // South
        CGPoint(x: 20, y: 80),   // Southwest
        CGPoint(x: 10, y: 50)    // West
    ]

    private static let germanyBorder: [CGPoint] = [
        CGPoint(x: 30, y: 20),   // Northwest
        CGPoint(x: 70, y: 20),   // North
        CGPoint(x: 85, y: 35),   // Northeast
        CGPoint(x: 80, y: 70),   // East
        CGPoint(x: 60, y: 85),   // Southeast
        CGPoint(x: 35, y: 80),   // South
        CGPoint(x: 20, y: 60),   // Southwest
        CGPoint(x: 25, y: 35)    // West
    ]

    private static let ukBorder: [CGPoint] = [
        CGPoint(x: 50, y: 15),   // North Scotland
        CGPoint(x: 60, y: 25),
        CGPoint(x: 55, y: 45),   // Middle Scotland
        CGPoint(x: 65, y: 60),   // England east
        CGPoint(x: 60, y: 80),   // Southeast
        CGPoint(x: 40, y: 85),   // Southwest
        CGPoint(x: 30, y: 75),
        CGPoint(x: 35, y: 60),   // Wales
        CGPoint(x: 30, y: 45),
        CGPoint(x: 40, y: 25),   // Northwest England
        CGPoint(x: 45, y: 15)
    ]

    private static let japanBorder: [CGPoint] = [
        // Hokkaido (northern island)
        CGPoint(x: 65, y: 15),
        CGPoint(x: 75, y: 20),
        CGPoint(x: 70, y: 30),
        CGPoint(x: 60, y: 28),
        // Honshu (main island)
        CGPoint(x: 55, y: 35),
        CGPoint(x: 60, y: 45),
        CGPoint(x: 65, y: 60),
        CGPoint(x: 55, y: 70),
        CGPoint(x: 45, y: 65),
        CGPoint(x: 40, y: 50),
        CGPoint(x: 45, y: 35),
        // Kyushu (southern island)
        CGPoint(x: 35, y: 75),
        CGPoint(x: 40, y: 80),
        CGPoint(x: 35, y: 85),
        CGPoint(x: 30, y: 80)
    ]

    private static let australiaBorder: [CGPoint] = [
        CGPoint(x: 40, y: 25),   // North
        CGPoint(x: 70, y: 30),
        CGPoint(x: 85, y: 45),   // East
        CGPoint(x: 80, y: 70),
        CGPoint(x: 60, y: 85),   // South
        CGPoint(x: 30, y: 80),
        CGPoint(x: 15, y: 60),   // West
        CGPoint(x: 20, y: 35)
    ]

    private static let brazilBorder: [CGPoint] = [
        CGPoint(x: 30, y: 20),   // North
        CGPoint(x: 60, y: 25),
        CGPoint(x: 75, y: 35),   // Northeast bulge
        CGPoint(x: 80, y: 50),
        CGPoint(x: 70, y: 70),   // East coast
        CGPoint(x: 50, y: 85),   // South
        CGPoint(x: 25, y: 75),
        CGPoint(x: 15, y: 50),   // West
        CGPoint(x: 20, y: 30)
    ]

    private static let canadaBorder: [CGPoint] = [
        CGPoint(x: 20, y: 15),   // West coast
        CGPoint(x: 30, y: 10),   // North
        CGPoint(x: 50, y: 8),
        CGPoint(x: 70, y: 12),
        CGPoint(x: 85, y: 18),   // Northeast
        CGPoint(x: 90, y: 35),   // East
        CGPoint(x: 80, y: 50),
        CGPoint(x: 65, y: 55),   // Southeast
        CGPoint(x: 25, y: 52),   // South border
        CGPoint(x: 15, y: 45),
        CGPoint(x: 18, y: 25)    // West
    ]

    private static let indiaBorder: [CGPoint] = [
        CGPoint(x: 40, y: 25),   // North (Himalayas)
        CGPoint(x: 60, y: 28),
        CGPoint(x: 75, y: 35),   // Northeast
        CGPoint(x: 80, y: 50),   // East coast
        CGPoint(x: 75, y: 70),
        CGPoint(x: 50, y: 85),   // Southern tip
        CGPoint(x: 30, y: 75),   // West coast
        CGPoint(x: 25, y: 55),
        CGPoint(x: 30, y: 35)
    ]

    private static let chinaBorder: [CGPoint] = [
        CGPoint(x: 20, y: 30),   // West
        CGPoint(x: 30, y: 20),   // Northwest
        CGPoint(x: 50, y: 15),   // North
        CGPoint(x: 75, y: 22),   // Northeast
        CGPoint(x: 85, y: 40),   // East
        CGPoint(x: 75, y: 60),
        CGPoint(x: 60, y: 75),   // Southeast
        CGPoint(x: 40, y: 70),   // South
        CGPoint(x: 25, y: 55),   // Southwest
        CGPoint(x: 18, y: 40)
    ]

    private static let usaBorder: [CGPoint] = [
        CGPoint(x: 25, y: 25),   // Northwest
        CGPoint(x: 65, y: 22),   // North border
        CGPoint(x: 85, y: 30),   // Northeast
        CGPoint(x: 88, y: 50),   // East coast
        CGPoint(x: 82, y: 65),
        CGPoint(x: 70, y: 72),   // Southeast
        CGPoint(x: 45, y: 75),   // South
        CGPoint(x: 25, y: 70),
        CGPoint(x: 15, y: 55),   // West coast
        CGPoint(x: 18, y: 35)
    ]

    private static let mexicoBorder: [CGPoint] = [
        CGPoint(x: 30, y: 25),   // North border
        CGPoint(x: 70, y: 22),
        CGPoint(x: 75, y: 35),   // East coast
        CGPoint(x: 70, y: 55),
        CGPoint(x: 55, y: 75),   // Yucatan
        CGPoint(x: 40, y: 70),   // South
        CGPoint(x: 25, y: 60),
        CGPoint(x: 20, y: 45),   // West coast
        CGPoint(x: 25, y: 30)
    ]

    private static let southKoreaBorder: [CGPoint] = [
        CGPoint(x: 45, y: 20),   // North
        CGPoint(x: 60, y: 25),
        CGPoint(x: 65, y: 40),   // East coast
        CGPoint(x: 60, y: 60),
        CGPoint(x: 50, y: 75),   // South
        CGPoint(x: 40, y: 70),
        CGPoint(x: 35, y: 55),   // West coast
        CGPoint(x: 38, y: 35),
        CGPoint(x: 42, y: 25)
    ]

    private static let norwayBorder: [CGPoint] = [
        CGPoint(x: 50, y: 10),   // North
        CGPoint(x: 65, y: 15),
        CGPoint(x: 70, y: 30),
        CGPoint(x: 65, y: 50),   // Middle
        CGPoint(x: 55, y: 75),
        CGPoint(x: 45, y: 85),   // South
        CGPoint(x: 38, y: 80),
        CGPoint(x: 35, y: 65),
        CGPoint(x: 40, y: 45),   // West coast (fjords)
        CGPoint(x: 35, y: 30),
        CGPoint(x: 42, y: 15)
    ]
}
