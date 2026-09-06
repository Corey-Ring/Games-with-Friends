import Foundation
import SwiftUI

@MainActor
@Observable
class CountryGameViewModel {
    var selectedLetter: String?
    var targetCountries: [Country] = []
    var guessedCountries: [Country] = []
    var giveUpCountries: [Country] = []
    var currentGuess: String = ""
    var feedbackMessage: String = ""
    var feedbackType: FeedbackType = .info
    var hintCount: Int = 0
    var currentHintedCountry: Country?
    var hintLevels: [UUID: Int] = [:]
    var gameState: GameState = .selectingLetter

    var speechManager = CountryLetterSpeechRecognitionManager()
    /// Set when the player taps the mic off. Scene resumes and new letters
    /// must not silently re-arm a mic the player chose to silence.
    var voiceMuted: Bool = false

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

    /// What the mic control should show. Derived, never stored, so it can't
    /// drift from the speech manager's real permission / listening state.
    enum VoiceState {
        case listening
        case off
        case needsPermission
        case denied
    }

    var voiceState: VoiceState {
        switch speechManager.permissionStatus {
        case .notDetermined: return .needsPermission
        case .denied: return .denied
        case .authorized: return speechManager.isListening ? .listening : .off
        }
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

    init() {
        speechManager.matchHandler = { [weak self] transcription in
            self?.handleSpeechTranscript(transcription)
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
        let trimmedGuess = currentGuess.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedGuess.isEmpty else {
            feedbackMessage = "Enter a country name to submit a guess."
            feedbackType = .error
            return
        }

        guard let selectedLetter = selectedLetter else {
            return
        }

        // Resolve against the whole list, not just this letter's, so a guess
        // for the wrong letter gets told which letter it belongs to instead
        // of a misleading "Not recognized".
        guard let matchedCountry = CountriesData.all.first(where: { $0.matches(trimmedGuess) }) else {
            feedbackMessage = "Not recognized. Try another name."
            feedbackType = .error
            HapticManager.error()
            return
        }

        guard matchedCountry.firstLetter == selectedLetter else {
            feedbackMessage = "\(matchedCountry.name) starts with \(matchedCountry.firstLetter), not \(selectedLetter)."
            feedbackType = .error
            HapticManager.error()
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

        currentGuess = ""
        accept(matchedCountry, spoken: false)
    }

    // MARK: - Voice

    /// Feeds one (possibly partial) speech transcript through the matcher.
    /// Transcripts are cumulative within an utterance, so a country already
    /// on the board is skipped silently rather than nagging "already guessed"
    /// on every partial result.
    func handleSpeechTranscript(_ transcription: String) {
        guard gameState == .playing else { return }

        for country in Self.spokenCountries(in: transcription, among: targetCountries)
        where !guessedCountries.contains(country) && !giveUpCountries.contains(country) {
            accept(country, spoken: true)
        }
    }

    /// Finds every candidate named in a transcript. Windows of up to
    /// `maxSpokenWords` consecutive words are tried longest-first and the words
    /// of a hit are consumed, so "Democratic Republic of the Congo" credits
    /// the DRC once instead of also crediting plain "Congo" on its last word.
    /// Results come back in the order they were spoken.
    static func spokenCountries(in transcription: String, among candidates: [Country]) -> [Country] {
        let words = transcription.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [] }

        var consumed = [Bool](repeating: false, count: words.count)
        var hits: [(start: Int, country: Country)] = []

        for size in stride(from: min(maxSpokenWords, words.count), through: 1, by: -1) {
            for start in 0...(words.count - size) {
                let range = start..<(start + size)
                guard !range.contains(where: { consumed[$0] }) else { continue }

                let phrase = words[range].joined(separator: " ")
                guard let country = candidates.first(where: { $0.matches(phrase) }) else { continue }

                for index in range { consumed[index] = true }
                if !hits.contains(where: { $0.country == country }) {
                    hits.append((start, country))
                }
            }
        }

        return hits.sorted { $0.start < $1.start }.map(\.country)
    }

    /// Longest spoken form we accept ("Saint Vincent and the Grenadines").
    private static let maxSpokenWords = 6

    /// Call when the play screen appears or the app returns to the foreground.
    func activateVoiceIfAllowed() {
        speechManager.checkPermissionStatus()
        guard gameState == .playing, !voiceMuted, speechManager.permissionStatus == .authorized else { return }
        speechManager.startListening()
    }

    /// Call when the play screen disappears or the app leaves the foreground.
    func suspendVoice() {
        speechManager.stopListening()
    }

    /// The mic button. Requests access the first time, then toggles.
    func toggleVoice() async {
        switch speechManager.permissionStatus {
        case .notDetermined:
            await speechManager.requestPermissions()
            guard speechManager.permissionStatus == .authorized else {
                showVoiceDenied()
                return
            }
            voiceMuted = false
            speechManager.startListening()
            feedbackMessage = "Voice is on. Just say a country."
            feedbackType = .info

        case .denied:
            showVoiceDenied()

        case .authorized:
            if speechManager.isListening {
                voiceMuted = true
                speechManager.stopListening()
                feedbackMessage = "Voice is off. Typing still works."
                feedbackType = .info
            } else {
                voiceMuted = false
                speechManager.startListening()
                feedbackMessage = speechManager.isListening
                    ? "Voice is on. Just say a country."
                    : "Voice isn't available right now. Typing still works."
                feedbackType = .info
            }
        }
    }

    private func showVoiceDenied() {
        feedbackMessage = "Microphone access is off. Turn it on in Settings to say your guesses."
        feedbackType = .error
    }

    // MARK: - Scoring

    private func accept(_ country: Country, spoken: Bool) {
        guessedCountries.append(country)

        // Clear hint tracking if this was the hinted country
        if currentHintedCountry == country {
            currentHintedCountry = nil
        }
        hintLevels.removeValue(forKey: country.id)

        feedbackMessage = spoken ? "Heard you! \(country.name) added." : "Nice! \(country.name) added."
        feedbackType = .success
        HapticManager.success()

        // Check if game is complete
        if remainingCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.finishGame()
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

        // A hint that gave the last country up ends the round like a guess would.
        if remainingCount == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.finishGame()
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
        guard gameState != .finished else { return }
        speechManager.stopListening()
        gameState = .finished
    }

    func resetGame() {
        speechManager.stopListening()
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
