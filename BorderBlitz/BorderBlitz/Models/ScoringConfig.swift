//
//  ScoringConfig.swift
//  Border Blitz
//

import Foundation

struct ScoringConfig {
    let basePointsPerLetter: Int = 100
    let timeBonus: Bool = true
    let timeBonusMultiplier: Double = 0.5
    let streakBonus: Int = 50
    let perfectBonus: Int = 500

    /// Calculate score based on game state
    func calculateScore(
        hiddenLettersCount: Int,
        timeRemaining: TimeInterval,
        totalTime: TimeInterval,
        currentStreak: Int,
        isPerfect: Bool
    ) -> Int {
        var score = 0

        // Base points for hidden letters
        score += hiddenLettersCount * basePointsPerLetter

        // Time bonus
        if timeBonus {
            let timeRatio = timeRemaining / totalTime
            let bonus = Int(Double(score) * timeBonusMultiplier * timeRatio)
            score += bonus
        }

        // Streak bonus
        if currentStreak > 1 {
            score += (currentStreak - 1) * streakBonus
        }

        // Perfect bonus (guessed with 0 letters revealed)
        if isPerfect {
            score += perfectBonus
        }

        return score
    }
}

struct RoundResult {
    let countryName: String
    let guessedCorrectly: Bool
    let hiddenLettersCount: Int
    let timeRemaining: TimeInterval
    let totalTime: TimeInterval
    let score: Int
    let isPerfect: Bool
    let streak: Int
}
