import Foundation
import SwiftUI

// MARK: - Game Mode

enum VibeCheckGameMode: String, CaseIterable, Identifiable {
    case classic
    case competition

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classic: return "Classic"
        case .competition: return "Competition"
        }
    }

    var description: String {
        switch self {
        case .classic:
            return "Teams work together to match the Vibe Setter's target"
        case .competition:
            return "Every player for themselves! Pass the device and guess individually"
        }
    }

    var iconName: String {
        switch self {
        case .classic: return "person.3.fill"
        case .competition: return "trophy.fill"
        }
    }
}

// MARK: - Game Configuration

struct VibeCheckSettings: Codable, Equatable {
    var teamCount: Int = 1
    var playersPerTeam: Int = 2
    var targetScore: Int = 500
    var roundsLimit: Int? = nil

    static let defaultSettings = VibeCheckSettings()

    var totalPlayers: Int {
        teamCount * playersPerTeam
    }
}

// MARK: - Team

struct VibeCheckTeam: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var playerNames: [String]
    var score: Int = 0

    init(id: UUID = UUID(), name: String, playerNames: [String] = [], score: Int = 0) {
        self.id = id
        self.name = name
        self.playerNames = playerNames
        self.score = score
    }
}

// MARK: - Spectrum (Polar Opposites)

struct VibeCheckSpectrum: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let topLabel: String      // e.g., "Trashy"
    let bottomLabel: String   // e.g., "Classy"

    init(id: UUID = UUID(), topLabel: String, bottomLabel: String) {
        self.id = id
        self.topLabel = topLabel
        self.bottomLabel = bottomLabel
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Round

struct VibeCheckRound: Identifiable, Codable, Equatable {
    let id: UUID
    let roundNumber: Int
    let spectrum: VibeCheckSpectrum
    let targetPosition: Double  // 0.0 = top, 1.0 = bottom
    let promptSetterTeamId: UUID
    var prompt: String = ""
    var guesses: [VibeCheckGuess] = []  // One per guessing team
    var isComplete: Bool = false

    init(id: UUID = UUID(), roundNumber: Int, spectrum: VibeCheckSpectrum, targetPosition: Double, promptSetterTeamId: UUID) {
        self.id = id
        self.roundNumber = roundNumber
        self.spectrum = spectrum
        self.targetPosition = targetPosition
        self.promptSetterTeamId = promptSetterTeamId
    }
}

struct VibeCheckGuess: Identifiable, Codable, Equatable {
    let id: UUID
    let teamId: UUID
    let guessedPosition: Double  // 0.0 = top, 1.0 = bottom
    var pointsEarned: Int = 0

    init(id: UUID = UUID(), teamId: UUID, guessedPosition: Double, pointsEarned: Int = 0) {
        self.id = id
        self.teamId = teamId
        self.guessedPosition = guessedPosition
        self.pointsEarned = pointsEarned
    }
}

// MARK: - Scoring Zones

enum ScoringZone: CaseIterable {
    case perfect    // Green - closest
    case great      // Yellow-green
    case good       // Yellow
    case okay       // Orange
    case miss       // Red - furthest

    var color: Color {
        switch self {
        case .perfect: return AppTheme.success
        case .great: return AppTheme.tealGreen
        case .good: return AppTheme.medalGold
        case .okay: return AppTheme.warning
        case .miss: return AppTheme.error
        }
    }

    var points: Int {
        switch self {
        case .perfect: return 100
        case .great: return 75
        case .good: return 50
        case .okay: return 25
        case .miss: return 0
        }
    }

    /// The threshold (max distance from target) for this zone
    /// Distance is 0.0 to 1.0 (full slider range)
    var threshold: Double {
        switch self {
        case .perfect: return 0.05   // Within 5%
        case .great: return 0.10     // Within 10%
        case .good: return 0.20      // Within 20%
        case .okay: return 0.35      // Within 35%
        case .miss: return 1.0       // Everything else
        }
    }

    static func zone(forDistance distance: Double) -> ScoringZone {
        for zone in ScoringZone.allCases {
            if distance <= zone.threshold {
                return zone
            }
        }
        return .miss
    }
}

// MARK: - Game State

enum VibeCheckGameState: Equatable {
    case setup
    case teamSetup
    case passingToPromptSetter
    case promptEntry
    case passingToGuessingTeam(teamIndex: Int)
    case guessing(teamIndex: Int)
    case reveal
    case scoreboard
    case gameOver
}

// MARK: - Scoring Engine

struct VibeCheckScoringEngine {

    /// Calculate points for a team's guess based on distance from target
    static func calculateScore(guessedPosition: Double, targetPosition: Double) -> (points: Int, zone: ScoringZone) {
        let distance = abs(guessedPosition - targetPosition)
        let zone = ScoringZone.zone(forDistance: distance)
        return (zone.points, zone)
    }
}

// MARK: - Round Result (for display)

struct VibeCheckRoundResult: Identifiable, Equatable {
    let id: UUID
    let teamId: UUID
    let teamName: String
    let guessedPosition: Double
    let targetPosition: Double
    let pointsEarned: Int
    let zone: ScoringZone

    var distance: Double {
        abs(guessedPosition - targetPosition)
    }
}
