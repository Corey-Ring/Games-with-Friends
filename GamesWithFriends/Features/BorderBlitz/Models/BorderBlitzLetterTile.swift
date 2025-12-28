//
//  LetterTile.swift
//  BorderBlitz
//

import Foundation

struct BorderBlitzLetterTile: Identifiable {
    let id = UUID()
    let character: Character
    let index: Int
    var isRevealed: Bool

    /// Spaces and special characters are always visible
    var isAlwaysVisible: Bool {
        character == " " || character == "-" || character == "'" || character == "."
    }

    /// Should this tile be displayed as visible?
    var shouldDisplay: Bool {
        isAlwaysVisible || isRevealed
    }
}

class BorderBlitzLetterRevealManager: ObservableObject {
    @Published var tiles: [BorderBlitzLetterTile] = []

    private var revealTimer: Timer?
    private var currentRevealIndex = 0
    private let revealInterval: TimeInterval
    private let shouldRevealLetters: Bool

    var allRevealed: Bool {
        tiles.allSatisfy { $0.shouldDisplay }
    }

    var hiddenCount: Int {
        tiles.filter { !$0.shouldDisplay && !$0.isAlwaysVisible }.count
    }

    init(revealInterval: TimeInterval, shouldRevealLetters: Bool = true) {
        self.revealInterval = revealInterval
        self.shouldRevealLetters = shouldRevealLetters
    }

    func setup(countryName: String) {
        currentRevealIndex = 0
        tiles = countryName.enumerated().map { index, char in
            BorderBlitzLetterTile(
                character: char,
                index: index,
                isRevealed: false
            )
        }
        revealTimer?.invalidate()
    }

    func startRevealing() {
        guard shouldRevealLetters else { return }

        revealTimer?.invalidate()
        currentRevealIndex = 0

        revealTimer = Timer.scheduledTimer(withTimeInterval: revealInterval, repeats: true) { [weak self] _ in
            self?.revealNextLetter()
        }
    }

    func stopRevealing() {
        revealTimer?.invalidate()
        revealTimer = nil
    }

    func revealAll() {
        stopRevealing()
        for index in tiles.indices {
            tiles[index].isRevealed = true
        }
    }

    private func revealNextLetter() {
        guard currentRevealIndex < tiles.count else {
            stopRevealing()
            return
        }

        // Find the next letter that needs revealing (skip spaces and special chars)
        while currentRevealIndex < tiles.count {
            if !tiles[currentRevealIndex].isAlwaysVisible && !tiles[currentRevealIndex].isRevealed {
                tiles[currentRevealIndex].isRevealed = true
                currentRevealIndex += 1
                return
            }
            currentRevealIndex += 1
        }

        // All letters revealed
        stopRevealing()
    }

    deinit {
        revealTimer?.invalidate()
    }
}
