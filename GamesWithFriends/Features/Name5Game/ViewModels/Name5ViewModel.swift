import Foundation
import SwiftUI
import Combine

@MainActor
class Name5ViewModel: ObservableObject {
    // MARK: - Configuration
    @Published var socialContext: SocialContext = .friends
    @Published var ageGroup: AgeGroup = .adults
    @Published var timerDuration: Int = 30 // seconds
    @Published var playerCount: Int = 1
    @Published var currentPlayerIndex: Int = 0
    @Published var timerEnabled: Bool = true

    // MARK: - Game State
    @Published var gamePhase: GamePhase = .setup
    @Published var currentPrompt: Name5Prompt?
    @Published var timeRemaining: Int = 30
    @Published var isTimerRunning: Bool = false

    // MARK: - Stats
    @Published var stats: GameStats = GameStats()
    @Published var roundResults: [RoundResult] = []
    @Published var lastResult: RoundResult?
    @Published var showFollowUpQuestion: Bool = false

    // MARK: - Prompt Management
    @Published var usedPromptIDs: Set<UUID> = []
    @Published var availablePrompts: [Name5Prompt] = []

    // MARK: - Players
    @Published var players: [PlayerTurn] = []

    // MARK: - Timer
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

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
            !usedPromptIDs.contains(prompt.id)
        }

        // If we've used all prompts, reset
        if availablePrompts.isEmpty && usedPromptIDs.count > 0 {
            usedPromptIDs.removeAll()
            availablePrompts = Name5PromptData.allPrompts.filter { prompt in
                prompt.isAvailableFor(context: socialContext, ageGroup: ageGroup)
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
