import Foundation
import SwiftUI

// MARK: - Clue Type

enum ClueType {
    case movieCount
    case decade
    case genre
    case movieYearGenre
    case rating
    case director
    case coStar
    case combined
    case movieTitle
    
    var icon: String {
        switch self {
        case .movieCount, .movieYearGenre, .movieTitle:
            return "film.stack"
        case .decade:
            return "calendar"
        case .genre:
            return "film"
        case .rating:
            return "star.fill"
        case .director:
            return "megaphone"
        case .coStar:
            return "person.2"
        case .combined:
            return "sparkles"
        }
    }
}

// MARK: - Clue Tier

enum ClueTier: Int {
    case vague = 1
    case narrowing = 2
    case strongSignal = 3
    case giveaway = 4
    
    var color: Color {
        switch self {
        case .vague:
            return Color.blue.opacity(0.15)
        case .narrowing:
            return Color.green.opacity(0.15)
        case .strongSignal:
            return Color.orange.opacity(0.15)
        case .giveaway:
            return Color.red.opacity(0.15)
        }
    }
}

// MARK: - Clue

struct Clue: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let type: ClueType
    let tier: ClueTier
    let orderNumber: Int
    
    static func == (lhs: Clue, rhs: Clue) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Difficulty

enum Difficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var clueInterval: TimeInterval {
        switch self {
        case .easy: return 8.0
        case .medium: return 5.0
        case .hard: return 3.0
        }
    }
    
    var wrongGuessPenalty: Int {
        switch self {
        case .easy: return 50
        case .medium: return 100
        case .hard: return 150
        }
    }
    
    var maxClues: Int {
        switch self {
        case .easy: return 16
        case .medium: return 12
        case .hard: return 8
        }
    }
    
    var showCoStarsEarly: Bool {
        switch self {
        case .easy, .medium: return true
        case .hard: return false
        }
    }
    
    var movieTitleCluesCount: Int {
        switch self {
        case .easy: return 3
        case .medium: return 2
        case .hard: return 1
        }
    }
}

// MARK: - Game Mode

enum GameMode: String, CaseIterable {
    case solo = "Solo"
    case passAndPlay = "Pass & Play"
    
    var description: String {
        switch self {
        case .solo:
            return "Single player, track high scores"
        case .passAndPlay:
            return "2-8 players take turns guessing"
        }
    }
}

// MARK: - Game Phase

enum GamePhase {
    case setup
    case playing
    case roundResult
    case gameOver
}

// MARK: - Player

struct CastingDirectorPlayer: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var score: Int = 0
    var correctGuesses: Int = 0
    var wrongGuesses: Int = 0
    
    var color: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .yellow, .cyan]
        return colors[abs(id.hashValue) % colors.count]
    }
}

// MARK: - Round State

struct RoundState {
    var targetActor: Actor?
    var revealedClues: [Clue] = []
    var wrongGuesses: [String] = []
    var isComplete: Bool = false
    var foundByPlayer: CastingDirectorPlayer?
    var currentScore: Int = 1000
    var cluesRevealed: Int = 0
    var wrongGuessCount: Int = 0
    
    mutating func reset() {
        targetActor = nil
        revealedClues = []
        wrongGuesses = []
        isComplete = false
        foundByPlayer = nil
        currentScore = 1000
        cluesRevealed = 0
        wrongGuessCount = 0
    }
}

// MARK: - Actor Extension for Display

extension Actor {
    var displayName: String {
        name
    }
}
