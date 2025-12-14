import Foundation

enum GamePhase: Equatable {
    case setup
    case ready
    case playing
    case paused
    case roundComplete
    case gameOver
}

struct PlayerTurn: Identifiable, Equatable {
    let id: UUID
    let playerNumber: Int
    var isActive: Bool

    init(id: UUID = UUID(), playerNumber: Int, isActive: Bool = false) {
        self.id = id
        self.playerNumber = playerNumber
        self.isActive = isActive
    }
}

struct RoundResult: Identifiable, Codable {
    let id: UUID
    let promptText: String
    let playerNumber: Int?
    let success: Bool
    let timeUsed: Int?
    let timestamp: Date

    init(
        id: UUID = UUID(),
        promptText: String,
        playerNumber: Int? = nil,
        success: Bool,
        timeUsed: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.promptText = promptText
        self.playerNumber = playerNumber
        self.success = success
        self.timeUsed = timeUsed
        self.timestamp = timestamp
    }
}

struct GameStats {
    var roundsPlayed: Int = 0
    var roundsWon: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0

    var successRate: Double {
        guard roundsPlayed > 0 else { return 0 }
        return Double(roundsWon) / Double(roundsPlayed)
    }

    mutating func recordSuccess() {
        roundsPlayed += 1
        roundsWon += 1
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)
    }

    mutating func recordFailure() {
        roundsPlayed += 1
        currentStreak = 0
    }

    mutating func reset() {
        roundsPlayed = 0
        roundsWon = 0
        currentStreak = 0
        bestStreak = 0
    }
}
