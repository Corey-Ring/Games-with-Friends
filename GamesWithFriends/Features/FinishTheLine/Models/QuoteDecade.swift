//
//  QuoteDecade.swift
//  GamesWithFriends
//

import Foundation

enum QuoteDecade: String, CaseIterable, Identifiable, Codable {
    case seventies
    case eighties
    case nineties
    case twoThousands
    case twentyTens
    case twentyTwenties
    case timeless

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .seventies: return "70s"
        case .eighties: return "80s"
        case .nineties: return "90s"
        case .twoThousands: return "2000s"
        case .twentyTens: return "2010s"
        case .twentyTwenties: return "2020s"
        case .timeless: return "Timeless"
        }
    }
}
