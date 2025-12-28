//
//  Difficulty.swift
//  BorderBlitz
//

import Foundation

enum BorderBlitzDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"

    var id: String { rawValue }

    /// Time in seconds between each letter reveal
    var letterRevealInterval: TimeInterval {
        switch self {
        case .easy: return 3.0
        case .medium: return 2.0
        case .hard: return 1.5
        case .expert: return 1.0
        }
    }

    /// Whether letters should be revealed over time
    var shouldRevealLetters: Bool {
        switch self {
        case .easy, .medium, .expert: return true
        case .hard: return false
        }
    }

    /// Total time allowed for the round in seconds
    var totalTime: TimeInterval {
        switch self {
        case .easy: return 60.0
        case .medium: return 45.0
        case .hard: return 35.0
        case .expert: return 25.0
        }
    }

    /// Description for UI
    var description: String {
        switch self {
        case .easy: return "1 letter every 3 seconds • 60s timer"
        case .medium: return "1 letter every 2 seconds • 45s timer"
        case .hard: return "No letters given • 35s timer"
        case .expert: return "1 letter every 1 second • 25s timer"
        }
    }
}
