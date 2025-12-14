import Foundation
import SwiftUI

class CountryGameViewModel: ObservableObject {
    @Published var selectedLetter: String?
    @Published var targetCountries: [Country] = []
    @Published var guessedCountries: [Country] = []
    @Published var giveUpCountries: [Country] = []
    @Published var currentGuess: String = ""
    @Published var feedbackMessage: String = ""
    @Published var feedbackType: FeedbackType = .info
    @Published var hintCount: Int = 0
    @Published var currentHintedCountry: Country?
    @Published var hintLevels: [UUID: Int] = [:]
    @Published var gameState: GameState = .selectingLetter

    enum GameState {
        case selectingLetter
        case playing
        case finished
    }

    enum FeedbackType {
        case success
        case error
        case info
    }

    var totalCountries: Int {
        targetCountries.count
    }

    var foundCount: Int {
        guessedCountries.count
    }

    var remainingCount: Int {
        totalCountries - foundCount - giveUpCountries.count
    }

    var remainingCountries: [Country] {
        targetCountries.filter { country in
            !guessedCountries.contains(country) && !giveUpCountries.contains(country)
        }
    }

    func selectLetter(_ letter: String) {
        selectedLetter = letter
        targetCountries = CountriesData.letterIndex[letter] ?? []
        guessedCountries = []
        giveUpCountries = []
        currentGuess = ""
        hintCount = 0
        currentHintedCountry = nil
        hintLevels = [:]
        gameState = .playing
        feedbackMessage = "Ready! \(totalCountries) countries start with \(letter)."
        feedbackType = .info
    }

    func submitGuess() {
        let trimmedGuess = currentGuess.trimmingCharacters(in: .whitespaces)

        guard !trimmedGuess.isEmpty else {
            feedbackMessage = "Enter a country name to submit a guess."
            feedbackType = .error
            return
        }

        guard let selectedLetter = selectedLetter else {
            return
        }

        // Try to find matching country
        guard let matchedCountry = targetCountries.first(where: { $0.matches(trimmedGuess) }) else {
            feedbackMessage = "Not recognized. Try another name."
            feedbackType = .error
            return
        }

        // Check if country starts with selected letter
        guard matchedCountry.firstLetter == selectedLetter else {
            feedbackMessage = "\"\(matchedCountry.name)\" does not start with \(selectedLetter)."
            feedbackType = .error
            return
        }

        // Check if already given up
        if giveUpCountries.contains(matchedCountry) {
            feedbackMessage = "\"\(matchedCountry.name)\" was already given up via hints."
            feedbackType = .error
            currentGuess = ""
            return
        }

        // Check if already guessed
        if guessedCountries.contains(matchedCountry) {
            feedbackMessage = "Already on the board. Keep going!"
            feedbackType = .error
            currentGuess = ""
            return
        }

        // Valid guess!
        guessedCountries.append(matchedCountry)

        // Clear hint tracking if this was the hinted country
        if currentHintedCountry == matchedCountry {
            currentHintedCountry = nil
        }
        hintLevels.removeValue(forKey: matchedCountry.id)

        feedbackMessage = "Nice! \(matchedCountry.name) added."
        feedbackType = .success
        currentGuess = ""

        // Check if game is complete
        if remainingCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.finishGame()
            }
        }
    }

    func showHint() {
        guard gameState == .playing else { return }

        hintCount += 1

        let remaining = remainingCountries

        guard !remaining.isEmpty else {
            feedbackMessage = "Nothing left to hint!"
            feedbackType = .info
            return
        }

        // If we have a current hinted country and it's still remaining
        if let hinted = currentHintedCountry, remaining.contains(hinted) {
            let hintLevel = hintLevels[hinted.id] ?? 0
            let (revealed, isFullyRevealed) = getHintLevelReveal(for: hinted, level: hintLevel)

            if isFullyRevealed {
                // Mark as give up
                giveUpCountries.append(hinted)
                currentHintedCountry = nil
                hintLevels.removeValue(forKey: hinted.id)
                feedbackMessage = "⚠️ \(hinted.name) marked as Give Up (fully revealed via hints)"
                feedbackType = .info
            } else {
                let levelDisplay = hintLevel > 0 ? " [Hint level \(hintLevel + 1)]" : ""
                feedbackMessage = "💡 Hint: \(revealed) (\(hinted.name.count) letters)\(levelDisplay)"
                feedbackType = .info
                hintLevels[hinted.id] = hintLevel + 1
            }
        } else {
            // Pick a new random country
            guard let newHinted = remaining.randomElement() else { return }
            currentHintedCountry = newHinted

            let hintLevel = hintLevels[newHinted.id] ?? 0
            let (revealed, isFullyRevealed) = getHintLevelReveal(for: newHinted, level: hintLevel)

            if isFullyRevealed {
                giveUpCountries.append(newHinted)
                currentHintedCountry = nil
                hintLevels.removeValue(forKey: newHinted.id)
                feedbackMessage = "⚠️ \(newHinted.name) marked as Give Up (fully revealed via hints)"
                feedbackType = .info
            } else {
                let levelDisplay = hintLevel > 0 ? " [Hint level \(hintLevel + 1)]" : ""
                feedbackMessage = "💡 Hint: \(revealed) (\(newHinted.name.count) letters)\(levelDisplay)"
                feedbackType = .info
                hintLevels[newHinted.id] = hintLevel + 1
            }
        }
    }

    private func getHintLevelReveal(for country: Country, level: Int) -> (String, Bool) {
        let countryName = country.name
        let countryLen = countryName.count

        // Calculate how many letters to reveal
        let revealLen: Int
        if level == 0 {
            revealLen = 3
        } else if level == 1 {
            revealLen = 5
        } else if level == 2 {
            revealLen = 7
        } else {
            revealLen = 7 + (level - 2) * 2
        }

        // Determine what to show
        if revealLen > countryLen {
            return (countryName, true)
        } else if revealLen >= countryLen - 1 {
            let revealed = String(countryName.prefix(countryLen - 1))
            return (revealed + "_", false)
        }

        let revealed = String(countryName.prefix(revealLen))
        let underscores = String(repeating: "_", count: countryLen - revealLen)
        return (revealed + underscores, false)
    }

    func finishGame() {
        gameState = .finished
    }

    func resetGame() {
        selectedLetter = nil
        targetCountries = []
        guessedCountries = []
        giveUpCountries = []
        currentGuess = ""
        feedbackMessage = ""
        feedbackType = .info
        hintCount = 0
        currentHintedCountry = nil
        hintLevels = [:]
        gameState = .selectingLetter
    }

    func changeLetterFromGame() {
        resetGame()
    }
}
