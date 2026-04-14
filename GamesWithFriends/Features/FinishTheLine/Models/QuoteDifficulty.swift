//
//  QuoteDifficulty.swift
//  GamesWithFriends
//

import Foundation

enum QuoteDifficulty: String, CaseIterable, Identifiable, Codable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var multiplier: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        }
    }

    var displayName: String {
        rawValue.capitalized
    }

    var tagline: String {
        switch self {
        case .easy: return "Culturally unmissable — warm-up territory."
        case .medium: return "Well known, but you'll feel the tip-of-tongue tug."
        case .hard: return "Cult classics and deep cuts — enthusiasts only."
        }
    }
}
