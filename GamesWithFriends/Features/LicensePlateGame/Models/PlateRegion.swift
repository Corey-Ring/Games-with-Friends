//
//  PlateRegion.swift
//  GamesWithFriends
//
//  Created by Claude Code
//

import Foundation

enum PlateRegion: String, Codable, CaseIterable {
    case usState = "US State"
    case usTerritory = "US Territory"
    case canadianProvince = "Canadian Province"
    case canadianTerritory = "Canadian Territory"
    case mexicanState = "Mexican State"

    var displayName: String {
        rawValue
    }

    var icon: String {
        switch self {
        case .usState, .usTerritory:
            return "flag.fill"
        case .canadianProvince, .canadianTerritory:
            return "leaf.fill"
        case .mexicanState:
            return "sun.max.fill"
        }
    }
}

enum RarityTier: String, Codable, CaseIterable, Comparable {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case ultraRare = "Ultra-Rare"

    var points: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 5
        case .ultraRare: return 10
        }
    }

    var color: String {
        switch self {
        case .common: return "gray"
        case .uncommon: return "blue"
        case .rare: return "purple"
        case .ultraRare: return "orange"
        }
    }

    var icon: String {
        switch self {
        case .common: return "circle.fill"
        case .uncommon: return "star.fill"
        case .rare: return "star.circle.fill"
        case .ultraRare: return "crown.fill"
        }
    }

    static func < (lhs: RarityTier, rhs: RarityTier) -> Bool {
        lhs.points < rhs.points
    }
}
