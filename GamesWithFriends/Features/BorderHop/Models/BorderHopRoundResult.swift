import Foundation

struct BorderHopRoundResult {
    let difficulty: BorderHopDifficulty
    let startCountryId: String
    let destinationCountryId: String
    let actualPath: [String]
    let optimalPath: [String]
    let elapsedTime: TimeInterval
    let funFacts: [String]

    var actualHops: Int { max(actualPath.count - 1, 0) }
    var optimalHops: Int { max(optimalPath.count - 1, 0) }

    /// Efficiency = (optimalHops / actualHops) * 100, capped at 100
    var efficiency: Double {
        guard actualHops > 0 else { return 0 }
        return min(Double(optimalHops) / Double(actualHops) * 100, 100)
    }

    /// TimeBonus = max(0, (benchmark - elapsed) / benchmark * 50)
    var timeBonus: Double {
        let benchmark = difficulty.benchmarkTime
        guard elapsedTime < benchmark else { return 0 }
        return (benchmark - elapsedTime) / benchmark * 50
    }

    /// Streak multiplier passed in from ViewModel
    var streakMultiplier: Double = 1.0

    /// RoundScore = (Efficiency + TimeBonus) * StreakMultiplier
    var totalScore: Double {
        (efficiency + timeBonus) * streakMultiplier
    }

    var totalScoreInt: Int { Int(totalScore.rounded()) }
}
