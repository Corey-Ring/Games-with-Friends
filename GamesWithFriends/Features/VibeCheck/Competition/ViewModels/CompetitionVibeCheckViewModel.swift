import Foundation
import SwiftUI

@MainActor
class CompetitionVibeCheckViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var settings: CompetitionVibeCheckSettings = .defaultSettings
    @Published var players: [CompetitionPlayer] = []
    @Published var currentRound: CompetitionRound?
    @Published var rounds: [CompetitionRound] = []
    @Published var gameState: CompetitionGameState = .setup

    // Temporary state during round
    @Published var currentPrompt: String = ""
    @Published var currentGuessPosition: Double = 0.5

    // Current guessing player index (among guessing players, not vibe setter)
    @Published var currentGuessingPlayerIndex: Int = 0

    // MARK: - Computed Properties

    /// The vibe setter for the current round is randomly selected each round
    var vibeSetterIndex: Int {
        guard let round = currentRound else { return 0 }
        return players.firstIndex(where: { $0.id == round.vibeSetterId }) ?? 0
    }

    var vibeSetter: CompetitionPlayer? {
        guard let round = currentRound else { return nil }
        return players.first(where: { $0.id == round.vibeSetterId })
    }

    /// Players who will guess (all players except the vibe setter)
    var guessingPlayers: [CompetitionPlayer] {
        guard let round = currentRound else { return [] }
        return players.filter { $0.id != round.vibeSetterId }
    }

    var currentGuessingPlayer: CompetitionPlayer? {
        guard currentGuessingPlayerIndex < guessingPlayers.count else { return nil }
        return guessingPlayers[currentGuessingPlayerIndex]
    }

    var allPlayersHaveGuessed: Bool {
        guard let round = currentRound else { return false }
        let guessingPlayerIds = Set(guessingPlayers.map { $0.id })
        let guessedIds = Set(round.guesses.map { $0.playerId })
        return guessingPlayerIds.isSubset(of: guessedIds)
    }

    var sortedPlayersByScore: [CompetitionPlayer] {
        players.sorted { $0.score > $1.score }
    }

    var leadingPlayer: CompetitionPlayer? {
        sortedPlayersByScore.first
    }

    var isGameOver: Bool {
        players.contains(where: { $0.score >= settings.targetScore })
    }

    var winner: CompetitionPlayer? {
        guard isGameOver else { return nil }
        return leadingPlayer
    }

    // MARK: - Player Setup

    func setupPlayers() {
        players = (1...settings.playerCount).map { index in
            CompetitionPlayer(name: "Player \(index)")
        }
    }

    func updatePlayerName(at index: Int, name: String) {
        guard index < players.count else { return }
        players[index].name = name
    }

    // MARK: - Game Flow

    func proceedToPlayerSetup() {
        setupPlayers()
        gameState = .playerSetup
    }

    func startGame() {
        rounds = []
        // Reset scores
        for index in players.indices {
            players[index].score = 0
        }
        startNewRound()
    }

    func startNewRound() {
        guard !isGameOver else {
            gameState = .gameOver
            return
        }

        let roundNumber = rounds.count + 1
        let spectrum = VibeCheckSpectrumData.randomSpectrum()
        let targetPosition = VibeCheckSpectrumData.randomTargetPosition()

        // Randomly select vibe setter for this round
        guard let randomVibeSetter = players.randomElement() else { return }
        let randomVibeSetterId = randomVibeSetter.id

        let round = CompetitionRound(
            roundNumber: roundNumber,
            spectrum: spectrum,
            targetPosition: targetPosition,
            vibeSetterId: randomVibeSetterId
        )

        currentRound = round
        currentPrompt = ""
        currentGuessingPlayerIndex = 0
        currentGuessPosition = 0.5

        gameState = .passingToVibeSetter
    }

    func confirmVibeSetterReady() {
        gameState = .promptEntry
    }

    func submitPrompt() {
        guard var round = currentRound, !currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        round.prompt = currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        currentRound = round
        currentGuessingPlayerIndex = 0
        currentGuessPosition = 0.5

        if guessingPlayers.isEmpty {
            gameState = .reveal
        } else {
            gameState = .passingToGuesser(playerIndex: 0)
        }
    }

    func confirmGuessingPlayerReady() {
        gameState = .guessing(playerIndex: currentGuessingPlayerIndex)
    }

    func submitGuess() {
        guard var round = currentRound, let guessingPlayer = currentGuessingPlayer else { return }

        let (points, _) = VibeCheckScoringEngine.calculateScore(
            guessedPosition: currentGuessPosition,
            targetPosition: round.targetPosition
        )

        let guess = CompetitionGuess(
            playerId: guessingPlayer.id,
            guessedPosition: currentGuessPosition,
            pointsEarned: points
        )

        round.guesses.append(guess)
        currentRound = round

        // Update player score
        if let playerIndex = players.firstIndex(where: { $0.id == guessingPlayer.id }) {
            players[playerIndex].score += points
        }

        // Move to next guessing player or reveal
        currentGuessingPlayerIndex += 1
        currentGuessPosition = 0.5

        if currentGuessingPlayerIndex >= guessingPlayers.count {
            // All players have guessed
            finalizeRound()
            gameState = .reveal
        } else {
            gameState = .passingToGuesser(playerIndex: currentGuessingPlayerIndex)
        }
    }

    // MARK: - Round Finalization

    private func finalizeRound() {
        guard var round = currentRound else { return }
        round.isComplete = true
        currentRound = round
        rounds.append(round)
    }

    func getRoundResults() -> [CompetitionRoundResult] {
        guard let round = currentRound else { return [] }

        // Sort by distance (closest first)
        let sortedGuesses = round.guesses.sorted { guess1, guess2 in
            let distance1 = abs(guess1.guessedPosition - round.targetPosition)
            let distance2 = abs(guess2.guessedPosition - round.targetPosition)
            return distance1 < distance2
        }

        return sortedGuesses.enumerated().compactMap { index, guess in
            guard let player = players.first(where: { $0.id == guess.playerId }) else { return nil }
            let (_, zone) = VibeCheckScoringEngine.calculateScore(
                guessedPosition: guess.guessedPosition,
                targetPosition: round.targetPosition
            )
            return CompetitionRoundResult(
                id: UUID(),
                playerId: player.id,
                playerName: player.name,
                guessedPosition: guess.guessedPosition,
                targetPosition: round.targetPosition,
                pointsEarned: guess.pointsEarned,
                zone: zone,
                rank: index + 1
            )
        }
    }

    var worstGuesser: CompetitionRoundResult? {
        getRoundResults().last
    }

    func proceedFromReveal() {
        if isGameOver {
            gameState = .gameOver
        } else {
            gameState = .scoreboard
        }
    }

    func continueToNextRound() {
        startNewRound()
    }

    // MARK: - Game Reset

    func resetGame() {
        players = []
        rounds = []
        currentRound = nil
        gameState = .setup
        currentPrompt = ""
        currentGuessPosition = 0.5
        currentGuessingPlayerIndex = 0
    }

    func returnToSetup() {
        resetGame()
    }
}
