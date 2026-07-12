//
//  BorderBlitzViewModel.swift
//  BorderBlitz
//

import SwiftUI
import AudioToolbox

enum BorderBlitzGameState {
    case menu
    case playing
    case roundComplete
    case gameOver
}

@MainActor
@Observable
class BorderBlitzViewModel {
    // MARK: - Properties
    var gameState: BorderBlitzGameState = .menu
    var currentCountry: BorderBlitzCountry?
    var timeRemaining: TimeInterval = 0
    var totalScore: Int = 0
    var currentStreak: Int = 0
    var roundResults: [BorderBlitzRoundResult] = []
    var selectedDifficulty: BorderBlitzDifficulty = .medium
    /// A session is a fixed number of rounds — "blitz" means short.
    let maxRounds = 10
    var showFeedback: Bool = false
    var feedbackMessage: String = ""
    var feedbackIsCorrect: Bool = false

    // MARK: - Private Properties
    private var countryPool: [BorderBlitzCountry] = []
    private var usedCountries: Set<String> = []
    @ObservationIgnored private var roundTimer: Timer?
    private let scoringConfig = BorderBlitzScoringConfig()

    var letterRevealManager: BorderBlitzLetterRevealManager
    var speechManager = BorderBlitzSpeechRecognitionManager()

    // MARK: - Computed Properties
    var gameStarted: Bool {
        gameState != .menu
    }

    var currentRoundNumber: Int {
        min(roundResults.count + 1, maxRounds)
    }

    var totalTime: TimeInterval {
        selectedDifficulty.totalTime
    }

    // MARK: - Initialization
    init() {
        self.letterRevealManager = BorderBlitzLetterRevealManager(
            revealInterval: BorderBlitzDifficulty.medium.letterRevealInterval,
            shouldRevealLetters: BorderBlitzDifficulty.medium.shouldRevealLetters
        )
        loadCountries()
        speechManager.matchHandler = { [weak self] transcription in
            self?.handleSpeechResult(transcription)
        }
    }

    // MARK: - Public Methods
    func startGame() {
        totalScore = 0
        currentStreak = 0
        roundResults = []
        usedCountries = []
        gameState = .playing

        // Update letter reveal manager with selected difficulty
        letterRevealManager = BorderBlitzLetterRevealManager(
            revealInterval: selectedDifficulty.letterRevealInterval,
            shouldRevealLetters: selectedDifficulty.shouldRevealLetters
        )

        startNewRound()
    }

    func startNewRound() {
        guard let country = getRandomCountry() else {
            endGame()
            return
        }

        currentCountry = country
        showFeedback = false
        timeRemaining = selectedDifficulty.totalTime
        gameState = .playing

        // Setup letter tiles
        letterRevealManager.setup(countryName: country.name)
        letterRevealManager.startRevealing()

        // Start countdown timer
        startTimer()

        // Restart speech recognition to clear previous buffer
        speechManager.stopListening()
        speechManager.startListening()
    }

    func handleManualConfirm() {
        guard gameState == .playing, currentCountry != nil else { return }
        // Honor-system confirm: counts as correct, but never earns the perfect bonus
        // (otherwise an instant tap beats every genuine spoken answer).
        handleCorrectGuess(manual: true)
    }

    func skipRound() {
        endRound(correct: false)
    }

    func pauseGame() {
        guard gameState == .playing else { return }
        stopTimer()
        letterRevealManager.stopRevealing()
        speechManager.stopListening()
    }

    func resumeGame() {
        guard gameState == .playing else { return }
        startTimer()
        letterRevealManager.startRevealing()
        speechManager.startListening()
    }

    func returnToMenu() {
        stopTimer()
        letterRevealManager.stopRevealing()
        speechManager.stopListening()
        gameState = .menu
    }

    func continueToNextRound() {
        if roundResults.count >= maxRounds {
            endGame()
        } else {
            startNewRound()
        }
    }

    // MARK: - Private Methods
    private func loadCountries() {
        countryPool = BorderBlitzCountryDataProvider.getAllCountries()
    }

    private func getRandomCountry() -> BorderBlitzCountry? {
        let availableCountries = countryPool.filter { !usedCountries.contains($0.id) }

        guard let country = availableCountries.randomElement() else {
            return nil
        }

        usedCountries.insert(country.id)
        return country
    }

    private func startTimer() {
        stopTimer()

        roundTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.timeRemaining -= 0.1

                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.handleTimeOut()
                }
            }
        }
    }

    private func stopTimer() {
        roundTimer?.invalidate()
        roundTimer = nil
    }


    private func handleCorrectGuess(manual: Bool = false) {
        currentStreak += 1
        endRound(correct: true, manual: manual)
        showFeedbackMessage("Correct! 🎉", isCorrect: true)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        AudioServicesPlaySystemSound(1025)
    }

    private func handleSpeechResult(_ transcription: String) {
        guard let country = currentCountry, gameState == .playing else { return }

        let words = transcription.split(separator: " ").map(String.init)

        // Check individual words
        for word in words {
            if country.isMatch(word) || country.isMatch(stripLeadingThe(word)) {
                handleCorrectGuess()
                return
            }
        }

        // Check sliding windows of 2 and 3 consecutive words
        for windowSize in 2...3 {
            guard words.count >= windowSize else { continue }
            for i in 0...(words.count - windowSize) {
                let phrase = words[i..<(i + windowSize)].joined(separator: " ")
                if country.isMatch(phrase) || country.isMatch(stripLeadingThe(phrase)) {
                    handleCorrectGuess()
                    return
                }
            }
        }
    }

    private func stripLeadingThe(_ text: String) -> String {
        let lowered = text.lowercased()
        if lowered.hasPrefix("the ") {
            return String(text.dropFirst(4))
        }
        return text
    }

    private func handleTimeOut() {
        // A queued timer tick can lose the race against a correct guess that
        // already ended the round; bail before showing "Time's up!" over it.
        guard gameState == .playing else { return }
        endRound(correct: false)
        showFeedbackMessage("Time's up!", isCorrect: false)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private func endRound(correct: Bool, manual: Bool = false) {
        // Guard against double entry: a queued timer tick can fire handleTimeOut
        // in the same runloop as a correct guess that already ended the round.
        guard gameState == .playing, let country = currentCountry else { return }

        stopTimer()
        letterRevealManager.stopRevealing()
        speechManager.stopListening()

        if !correct {
            currentStreak = 0
            letterRevealManager.revealAll()
        }

        let hiddenCount = letterRevealManager.hiddenCount
        let isPerfect = !manual
            && hiddenCount == country.name.filter { !$0.isWhitespace && $0 != "-" && $0 != "'" }.count

        let score = correct ? scoringConfig.calculateScore(
            hiddenLettersCount: hiddenCount,
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            currentStreak: currentStreak,
            isPerfect: isPerfect
        ) : 0

        if correct {
            totalScore += score
        }

        let result = BorderBlitzRoundResult(
            countryName: country.name,
            guessedCorrectly: correct,
            hiddenLettersCount: hiddenCount,
            timeRemaining: timeRemaining,
            totalTime: totalTime,
            score: score,
            isPerfect: isPerfect,
            streak: currentStreak
        )

        roundResults.append(result)
        gameState = .roundComplete
    }

    private func endGame() {
        stopTimer()
        letterRevealManager.stopRevealing()
        speechManager.stopListening()
        gameState = .gameOver
    }

    private func showFeedbackMessage(_ message: String, isCorrect: Bool) {
        feedbackMessage = message
        feedbackIsCorrect = isCorrect
        showFeedback = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showFeedback = false
        }
    }

    deinit {
        roundTimer?.invalidate()
    }
}
