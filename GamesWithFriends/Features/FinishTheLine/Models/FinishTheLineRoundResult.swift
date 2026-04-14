//
//  FinishTheLineRoundResult.swift
//  GamesWithFriends
//

import Foundation
import SwiftData

/// Persisted record of one completed round. Used to show personal best on the
/// menu and the results screen.
@Model
final class FinishTheLineRoundResult {
    var id: UUID
    var date: Date
    var score: Int
    var correctCount: Int
    var skipCount: Int
    var bestStreak: Int
    var difficultyRaw: String
    var selectedCategoriesRaw: [String]
    var selectedDecadesRaw: [String]

    init(
        score: Int,
        correctCount: Int,
        skipCount: Int,
        bestStreak: Int,
        difficulty: QuoteDifficulty,
        categories: Set<QuoteCategory>,
        decades: Set<QuoteDecade>
    ) {
        self.id = UUID()
        self.date = Date()
        self.score = score
        self.correctCount = correctCount
        self.skipCount = skipCount
        self.bestStreak = bestStreak
        self.difficultyRaw = difficulty.rawValue
        self.selectedCategoriesRaw = categories.map { $0.rawValue }.sorted()
        self.selectedDecadesRaw = decades.map { $0.rawValue }.sorted()
    }

    var difficulty: QuoteDifficulty {
        QuoteDifficulty(rawValue: difficultyRaw) ?? .medium
    }
}
