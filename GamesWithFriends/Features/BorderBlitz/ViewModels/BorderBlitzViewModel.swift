//
//  BorderBlitzViewModel.swift
//  BorderBlitz
//

import SwiftUI
import Combine

enum BorderBlitzGameState {
    case menu
    case playing
    case roundComplete
    case gameOver
}

class BorderBlitzViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var gameState: BorderBlitzGameState = .menu
    @Published var currentCountry: BorderBlitzCountry?
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalScore: Int = 0
    @Published var currentStreak: Int = 0
    @Published var roundResults: [BorderBlitzRoundResult] = []
    @Published var selectedDifficulty: BorderBlitzDifficulty = .medium
    @Published var currentGuess: String = ""
    @Published var showFeedback: Bool = false
    @Published var feedbackMessage: String = ""
    @Published var feedbackIsCorrect: Bool = false

    // MARK: - Private Properties
    private var countryPool: [BorderBlitzCountry] = []
    private var usedCountries: Set<String> = []
    private var roundTimer: Timer?
    private let scoringConfig = BorderBlitzScoringConfig()

    @Published var letterRevealManager: BorderBlitzLetterRevealManager

    // MARK: - Computed Properties
    var gameStarted: Bool {
        gameState != .menu
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
        currentGuess = ""
        showFeedback = false
        timeRemaining = selectedDifficulty.totalTime
        gameState = .playing

        // Setup letter tiles
        letterRevealManager.setup(countryName: country.name)
        letterRevealManager.startRevealing()

        // Start countdown timer
        startTimer()
    }

    func submitGuess() {
        guard let country = currentCountry else { return }

        let trimmedGuess = currentGuess.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedGuess.isEmpty else { return }

        if country.isMatch(trimmedGuess) {
            handleCorrectGuess()
        } else {
            handleIncorrectGuess()
        }
    }

    func skipRound() {
        endRound(correct: false)
    }

    func returnToMenu() {
        stopTimer()
        letterRevealManager.stopRevealing()
        gameState = .menu
    }

    func continueToNextRound() {
        startNewRound()
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
            guard let self = self else { return }

            self.timeRemaining -= 0.1

            if self.timeRemaining <= 0 {
                self.timeRemaining = 0
                self.handleTimeOut()
            }
        }
    }

    private func stopTimer() {
        roundTimer?.invalidate()
        roundTimer = nil
    }

    private func handleCorrectGuess() {
        currentStreak += 1
        endRound(correct: true)
        showFeedbackMessage("Correct! 🎉", isCorrect: true)
    }

    private func handleIncorrectGuess() {
        showFeedbackMessage("Try again", isCorrect: false)
        currentGuess = ""
    }

    private func handleTimeOut() {
        endRound(correct: false)
        showFeedbackMessage("Time's up!", isCorrect: false)
    }

    private func endRound(correct: Bool) {
        guard let country = currentCountry else { return }

        stopTimer()
        letterRevealManager.stopRevealing()

        if !correct {
            currentStreak = 0
            letterRevealManager.revealAll()
        }

        let hiddenCount = letterRevealManager.hiddenCount
        let isPerfect = hiddenCount == country.name.filter { !$0.isWhitespace && $0 != "-" && $0 != "'" }.count

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
        stopTimer()
    }
}
