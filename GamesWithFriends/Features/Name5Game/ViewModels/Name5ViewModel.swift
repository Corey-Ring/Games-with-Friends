import Foundation
import SwiftUI

@MainActor
@Observable
class Name5ViewModel {
    // MARK: - Configuration
    var socialContext: SocialContext = .friends
    var ageGroup: AgeGroup = .adults
    var timerDuration: Int = 30 // seconds
    var playerCount: Int = 1
    var currentPlayerIndex: Int = 0
    var timerEnabled: Bool = true
    var selectedCategories: Set<PromptCategory> = Set(PromptCategory.allCases)
    var selectedDifficulties: Set<Difficulty> = Set([.easy, .medium, .hard])

    // MARK: - Game State
    var gamePhase: GamePhase = .setup
    var currentPrompt: Name5Prompt?
    var timeRemaining: Int = 30
    var isTimerRunning: Bool = false

    // MARK: - Stats
    var stats: GameStats = GameStats()
    var roundResults: [RoundResult] = []
    var lastResult: RoundResult?
    var showFollowUpQuestion: Bool = false

    // MARK: - Prompt Management
    var usedPromptIDs: Set<UUID> = []
    var availablePrompts: [Name5Prompt] = []

    // MARK: - Players
    var players: [PlayerTurn] = []

    // MARK: - Timer
    @ObservationIgnored private var timer: Timer?

    // MARK: - Initialization
    init() {
        setupPlayers()
        updateAvailablePrompts()
    }

    // MARK: - Configuration Methods
    func setupPlayers() {
        players = (1...playerCount).map { index in
            PlayerTurn(playerNumber: index, isActive: index == 1)
        }
        currentPlayerIndex = 0
    }

    func updateAvailablePrompts() {
        availablePrompts = Name5PromptData.allPrompts.filter { prompt in
            prompt.isAvailableFor(context: socialContext, ageGroup: ageGroup) &&
            selectedCategories.contains(prompt.category) &&
            selectedDifficulties.contains(prompt.difficulty) &&
            !usedPromptIDs.contains(prompt.id)
        }

        // If we've used all prompts, reset
        if availablePrompts.isEmpty && usedPromptIDs.count > 0 {
            usedPromptIDs.removeAll()
            availablePrompts = Name5PromptData.allPrompts.filter { prompt in
                prompt.isAvailableFor(context: socialContext, ageGroup: ageGroup) &&
                selectedCategories.contains(prompt.category) &&
                selectedDifficulties.contains(prompt.difficulty)
            }
        }
    }

    func updateConfiguration(context: SocialContext? = nil, age: AgeGroup? = nil, duration: Int? = nil, players: Int? = nil) {
        if let context = context {
            socialContext = context
        }
        if let age = age {
            ageGroup = age
        }
        if let duration = duration {
            timerDuration = duration
            timeRemaining = duration
        }
        if let players = players {
            playerCount = players
            setupPlayers()
        }
        updateAvailablePrompts()
    }
    
    func toggleCategory(_ category: PromptCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }

        // Always keep at least one category selected
        if selectedCategories.isEmpty {
            selectedCategories.insert(category)
        }

        updateAvailablePrompts()
    }

    func toggleDifficulty(_ difficulty: Difficulty) {
        if selectedDifficulties.contains(difficulty) {
            selectedDifficulties.remove(difficulty)
        } else {
            selectedDifficulties.insert(difficulty)
        }

        // Always keep at least one difficulty selected
        if selectedDifficulties.isEmpty {
            selectedDifficulties.insert(difficulty)
        }

        updateAvailablePrompts()
    }

    // MARK: - Game Flow
    func startGame() {
        guard !availablePrompts.isEmpty else { return }
        gamePhase = .ready
        stats.reset()
        roundResults.removeAll()
        usedPromptIDs.removeAll()
        updateAvailablePrompts()
        getNextPrompt()
    }

    func getNextPrompt() {
        guard let prompt = availablePrompts.randomElement() else {
            endGame()
            return
        }

        currentPrompt = prompt
        usedPromptIDs.insert(prompt.id)
        updateAvailablePrompts()
        timeRemaining = timerDuration
        showFollowUpQuestion = false
        gamePhase = .ready
    }

    func startRound() {
        guard gamePhase == .ready else { return }
        gamePhase = .playing

        if timerEnabled {
            startTimer()
        }
    }

    func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        gamePhase = .paused
    }

    func resumeTimer() {
        guard gamePhase == .paused else { return }
        gamePhase = .playing
        if timerEnabled {
            startTimer()
        }
    }

    private func startTimer() {
        isTimerRunning = true
        timer?.invalidate()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1

                    // Haptic feedback at key moments
                    if self.timeRemaining == 10 || self.timeRemaining == 5 {
                        self.triggerHaptic()
                    }
                } else {
                    self.timeUp()
                }
            }
        }
    }

    private func timeUp() {
        stopTimer()
        // Auto-fail when time runs out
        markFailure()
    }

    private func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }

    private func triggerHaptic() {
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }

    // MARK: - Round Completion
    func markSuccess() {
        stopTimer()

        guard let prompt = currentPrompt else { return }

        let result = RoundResult(
            promptText: prompt.text,
            playerNumber: playerCount > 1 ? currentPlayerIndex + 1 : nil,
            success: true,
            timeUsed: timerEnabled ? (timerDuration - timeRemaining) : nil
        )

        roundResults.append(result)
        lastResult = result
        stats.recordSuccess()

        gamePhase = .roundComplete
        showFollowUpQuestion = prompt.followUpQuestion != nil

        if playerCount > 1 {
            advanceToNextPlayer()
        }
    }

    func markFailure() {
        stopTimer()

        guard let prompt = currentPrompt else { return }

        let result = RoundResult(
            promptText: prompt.text,
            playerNumber: playerCount > 1 ? currentPlayerIndex + 1 : nil,
            success: false,
            timeUsed: timerEnabled ? (timerDuration - timeRemaining) : nil
        )

        roundResults.append(result)
        lastResult = result
        stats.recordFailure()

        gamePhase = .roundComplete
        showFollowUpQuestion = prompt.followUpQuestion != nil

        if playerCount > 1 {
            advanceToNextPlayer()
        }
    }

    func skipPrompt() {
        // Treat skip as a failure
        markFailure()
    }

    private func advanceToNextPlayer() {
        currentPlayerIndex = (currentPlayerIndex + 1) % playerCount

        // Update player turn states
        for index in players.indices {
            players[index].isActive = (index == currentPlayerIndex)
        }
    }

    func continueToNextRound() {
        getNextPrompt()
    }

    func playAgainSameCategory() {
        guard let currentCategory = currentPrompt?.category else {
            getNextPrompt()
            return
        }

        // Find a new prompt in the same category
        let categoryPrompts = availablePrompts.filter { $0.category == currentCategory }

        if let prompt = categoryPrompts.randomElement() {
            currentPrompt = prompt
            usedPromptIDs.insert(prompt.id)
            updateAvailablePrompts()
            timeRemaining = timerDuration
            showFollowUpQuestion = false
            gamePhase = .ready
        } else {
            // No more prompts in this category, get any prompt
            getNextPrompt()
        }
    }

    func endGame() {
        stopTimer()
        gamePhase = .gameOver
    }

    func resetGame() {
        stopTimer()
        gamePhase = .setup
        currentPrompt = nil
        timeRemaining = timerDuration
        stats.reset()
        roundResults.removeAll()
        lastResult = nil
        usedPromptIDs.removeAll()
        currentPlayerIndex = 0
        selectedCategories = Set(PromptCategory.allCases)
        selectedDifficulties = Set([.easy, .medium, .hard])
        setupPlayers()
        updateAvailablePrompts()
    }

    // MARK: - Computed Properties
    var currentPlayer: PlayerTurn? {
        guard currentPlayerIndex < players.count else { return nil }
        return players[currentPlayerIndex]
    }

    var timerProgress: Double {
        guard timerDuration > 0 else { return 0 }
        return Double(timeRemaining) / Double(timerDuration)
    }

    var timerColor: Color {
        let progress = timerProgress
        if progress > 0.5 {
            return .green
        } else if progress > 0.2 {
            return .yellow
        } else {
            return .red
        }
    }

    var canStart: Bool {
        !availablePrompts.isEmpty
    }

    deinit {
        timer?.invalidate()
    }
}
