import Foundation

/// One bite-sized fact the player saw during a round — the unit of learning.
/// Logged when a quiz resolves and recapped on the results screen.
struct LearnedFact: Identifiable, Hashable {
    let id = UUID()
    let countryId: String
    let flag: String          // emoji, may be empty
    let text: String          // one-line takeaway, e.g. "Hanoi is the capital of Vietnam"
    let gotItFirstTry: Bool
}

struct BorderHopRoundResult {
    let difficulty: BorderHopDifficulty
    let startCountryId: String
    let destinationCountryId: String
    let actualPath: [String]
    let optimalPath: [String]
    let elapsedTime: TimeInterval
    let learnedFacts: [LearnedFact]

    /// Per-question credit (1.0 first try, 0.5 second, 0.25 third, 0 revealed)
    let questionCredits: [Double]

    var actualHops: Int { max(actualPath.count - 1, 0) }
    var optimalHops: Int { max(optimalPath.count - 1, 0) }

    /// Route score = (optimalHops / actualHops) * 100, capped at 100
    var efficiency: Double {
        guard actualHops > 0 else { return 0 }
        return min(Double(optimalHops) / Double(actualHops) * 100, 100)
    }

    /// Knowledge score = earned quiz credit as a percentage (0–100).
    /// Replaces the old time bonus: a solo trainer should reward knowing things,
    /// not skimming the questions to beat a clock.
    var knowledgeScore: Double {
        guard !questionCredits.isEmpty else { return 0 }
        return questionCredits.reduce(0, +) / Double(questionCredits.count) * 100
    }

    var firstTryCount: Int {
        questionCredits.filter { $0 >= 1.0 }.count
    }

    /// Streak multiplier passed in from ViewModel
    var streakMultiplier: Double = 1.0

    /// RoundScore = average of Route and Knowledge, boosted by the streak
    var totalScore: Double {
        (efficiency + knowledgeScore) / 2 * streakMultiplier
    }

    var totalScoreInt: Int { Int(totalScore.rounded()) }
}
