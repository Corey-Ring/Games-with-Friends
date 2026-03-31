import Foundation

// MARK: - QuizType

enum QuizType: CaseIterable {
    case funFact
    case flagIdentification
}

// MARK: - QuizTypeSelector

/// Selects quiz types with a weighted distribution and streak caps to ensure variety.
///
/// Configuration:
/// - `flagProbability`: base probability of a flag quiz (default 40%)
/// - `maxConsecutiveFlags`: force switch to fun fact after this many flag quizzes in a row (default 2)
/// - `maxConsecutiveFacts`: force switch to flag quiz after this many fact quizzes in a row (default 3)
struct QuizTypeSelector {
    private var consecutiveFlagCount = 0
    private var consecutiveFactCount = 0

    // MARK: - Configuration
    private let flagProbability: Double = 0.40
    private let maxConsecutiveFlags: Int = 2
    private let maxConsecutiveFacts: Int = 3

    mutating func nextType() -> QuizType {
        // Force switch if at streak cap
        if consecutiveFlagCount >= maxConsecutiveFlags {
            record(.funFact)
            return .funFact
        }
        if consecutiveFactCount >= maxConsecutiveFacts {
            record(.flagIdentification)
            return .flagIdentification
        }

        // Weighted random selection
        let type: QuizType = Double.random(in: 0..<1) < flagProbability
            ? .flagIdentification
            : .funFact
        record(type)
        return type
    }

    mutating func reset() {
        consecutiveFlagCount = 0
        consecutiveFactCount = 0
    }

    private mutating func record(_ type: QuizType) {
        switch type {
        case .flagIdentification:
            consecutiveFlagCount += 1
            consecutiveFactCount = 0
        case .funFact:
            consecutiveFactCount += 1
            consecutiveFlagCount = 0
        }
    }
}
