//
//  Quote.swift
//  GamesWithFriends
//

import Foundation

/// One playable quote in Finish the Line.
struct Quote: Identifiable, Hashable {
    let id: String
    let setup: String             // "May the force be ___ you"
    let fullLine: String          // "May the force be with you"
    let missingWord: String       // "with"
    let alternates: [String]      // ["with ya", "with u"]
    let source: String            // "Star Wars: A New Hope"
    let category: QuoteCategory
    let decade: QuoteDecade
    let difficulty: QuoteDifficulty
    let blankPosition: BlankPosition

    init(
        id: String,
        setup: String,
        fullLine: String,
        missingWord: String,
        alternates: [String] = [],
        source: String,
        category: QuoteCategory,
        decade: QuoteDecade,
        difficulty: QuoteDifficulty,
        blankPosition: BlankPosition = .end
    ) {
        self.id = id
        self.setup = setup
        self.fullLine = fullLine
        self.missingWord = missingWord
        self.alternates = alternates
        self.source = source
        self.category = category
        self.decade = decade
        self.difficulty = difficulty
        self.blankPosition = blankPosition
    }

    /// The full list of strings the speech recognizer should count as a correct answer.
    /// Always includes the canonical missingWord plus any alternates.
    var acceptableAnswers: [String] {
        [missingWord] + alternates
    }
}
