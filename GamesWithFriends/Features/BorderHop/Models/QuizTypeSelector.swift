import Foundation

// MARK: - QuizType

enum QuizType: CaseIterable {
    case funFact
    case flagIdentification
    case export
}

// MARK: - QuizTypeSelector

/// Selects quiz types with a weighted distribution and streak caps to ensure variety.
///
/// Configuration:
/// - `exportProbability`: base probability of an export quiz (default 25%)
/// - `flagProbability`: base probability of a flag quiz (default 35%)
/// - Fun fact gets the remainder (default 40%)
/// - `maxConsecutiveExports`: force switch after this many export quizzes in a row (default 2)
/// - `maxConsecutiveFlags`: force switch after this many flag quizzes in a row (default 2)
/// - `maxConsecutiveFacts`: force switch after this many fact quizzes in a row (default 3)
struct QuizTypeSelector {
    private var consecutiveExportCount = 0
    private var consecutiveFlagCount = 0
    private var consecutiveFactCount = 0

    // MARK: - Configuration
    private let exportProbability: Double = 0.25
    private let flagProbability: Double = 0.35
    // fun fact = 1.0 - exportProbability - flagProbability = 0.40
    private let maxConsecutiveExports: Int = 2
    private let maxConsecutiveFlags: Int = 2
    private let maxConsecutiveFacts: Int = 3

    mutating func nextType() -> QuizType {
        // Build eligible types (exclude any that hit their streak cap)
        var eligible: [(QuizType, Double)] = []

        if consecutiveExportCount < maxConsecutiveExports {
            eligible.append((.export, exportProbability))
        }
        if consecutiveFlagCount < maxConsecutiveFlags {
            eligible.append((.flagIdentification, flagProbability))
        }
        if consecutiveFactCount < maxConsecutiveFacts {
            let factProbability = 1.0 - exportProbability - flagProbability
            eligible.append((.funFact, factProbability))
        }

        // Re-normalize weights to sum to 1.0
        let totalWeight = eligible.reduce(0.0) { $0 + $1.1 }
        let roll = Double.random(in: 0..<totalWeight)

        var cumulative = 0.0
        var selected: QuizType = eligible.first?.0 ?? .funFact
        for (type, weight) in eligible {
            cumulative += weight
            if roll < cumulative {
                selected = type
                break
            }
        }

        record(selected)
        return selected
    }

    mutating func reset() {
        consecutiveExportCount = 0
        consecutiveFlagCount = 0
        consecutiveFactCount = 0
    }

    private mutating func record(_ type: QuizType) {
        switch type {
        case .export:
            consecutiveExportCount += 1
            consecutiveFlagCount = 0
            consecutiveFactCount = 0
        case .flagIdentification:
            consecutiveFlagCount += 1
            consecutiveExportCount = 0
            consecutiveFactCount = 0
        case .funFact:
            consecutiveFactCount += 1
            consecutiveExportCount = 0
            consecutiveFlagCount = 0
        }
    }
}
