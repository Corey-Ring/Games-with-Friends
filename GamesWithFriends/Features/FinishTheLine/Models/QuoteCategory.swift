//
//  QuoteCategory.swift
//  GamesWithFriends
//

import Foundation

enum QuoteCategory: String, CaseIterable, Identifiable, Codable {
    case silverScreen
    case smallScreen
    case animated
    case songsAndJingles
    case pitchPerfect
    case storytime
    case playTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .silverScreen: return "Silver Screen"
        case .smallScreen: return "Small Screen"
        case .animated: return "Animated"
        case .songsAndJingles: return "Songs & Jingles"
        case .pitchPerfect: return "Pitch Perfect"
        case .storytime: return "Storytime"
        case .playTime: return "Play Time"
        }
    }

    var iconName: String {
        switch self {
        case .silverScreen: return "film.fill"
        case .smallScreen: return "tv.fill"
        case .animated: return "sparkles.tv.fill"
        case .songsAndJingles: return "music.note"
        case .pitchPerfect: return "megaphone.fill"
        case .storytime: return "book.fill"
        case .playTime: return "gamecontroller.fill"
        }
    }
}
