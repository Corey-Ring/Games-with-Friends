import Foundation
import SwiftUI

@MainActor
class VibeCheckViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var settings: VibeCheckSettings = .defaultSettings
    @Published var competitionSettings: CompetitionVibeCheckSettings = .defaultSettings
    @Published var teams: [VibeCheckTeam] = []
    @Published var currentRound: VibeCheckRound?
    @Published var rounds: [VibeCheckRound] = []
    @Published var gameState: VibeCheckGameState = .setup

    // Temporary state during round
    @Published var currentPrompt: String = ""
    @Published var currentGuessPosition: Double = 0.5

    // Current guessing team index
    @Published var currentGuessingTeamIndex: Int = 0

    // Competition mode state - managed by CompetitionVibeCheckViewModel
    // The VibeCheckViewModel just holds the settings for the home screen

    // MARK: - Computed Properties

    var promptSetterTeamIndex: Int {
        guard !teams.isEmpty else { return 0 }
        return rounds.count % teams.count
    }

    var promptSetterTeam: VibeCheckTeam? {
        guard !teams.isEmpty, promptSetterTeamIndex < teams.count else { return nil }
        return teams[promptSetterTeamIndex]
    }

    /// Teams that will guess (all teams except the prompt setter, or all if only 1 team)
    var guessingTeams: [VibeCheckTeam] {
        if teams.count == 1 {
            // Single team mode: same team guesses
            return teams
        }
        return teams.enumerated()
            .filter { $0.offset != promptSetterTeamIndex }
            .map { $0.element }
    }

    var currentGuessingTeam: VibeCheckTeam? {
        guard currentGuessingTeamIndex < guessingTeams.count else { return nil }
        return guessingTeams[currentGuessingTeamIndex]
    }

    var allTeamsHaveGuessed: Bool {
        guard let round = currentRound else { return false }
        let guessingTeamIds = Set(guessingTeams.map { $0.id })
        let guessedIds = Set(round.guesses.map { $0.teamId })
        return guessingTeamIds.isSubset(of: guessedIds)
    }

    var sortedTeamsByScore: [VibeCheckTeam] {
        teams.sorted { $0.score > $1.score }
    }

    var leadingTeam: VibeCheckTeam? {
        sortedTeamsByScore.first
    }

    var isGameOver: Bool {
        // Check if any team has reached target score
        if teams.contains(where: { $0.score >= settings.targetScore }) {
            return true
        }
        // Check if rounds limit reached
        if let limit = settings.roundsLimit, rounds.count >= limit {
            return true
        }
        return false
    }

    var winner: VibeCheckTeam? {
        guard isGameOver else { return nil }
        return leadingTeam
    }

    // MARK: - Team Setup

    func setupTeams() {
        teams = (1...settings.teamCount).map { index in
            let playerNames = (1...settings.playersPerTeam).map { playerIndex in
                "Player \(playerIndex)"
            }
            return VibeCheckTeam(
                name: "",
                playerNames: playerNames
            )
        }
    }

    func updateTeamName(at index: Int, name: String) {
        guard index < teams.count else { return }
        teams[index].name = name
    }

    func updatePlayerName(teamIndex: Int, playerIndex: Int, name: String) {
        guard teamIndex < teams.count, playerIndex < teams[teamIndex].playerNames.count else { return }
        teams[teamIndex].playerNames[playerIndex] = name
    }

    // MARK: - Game Flow

    func proceedToTeamSetup() {
        setupTeams()
        gameState = .teamSetup
    }

    func proceedToCompetitionPlayerSetup() {
        // This will trigger the root view to switch to competition mode flow
        // The actual player setup is handled by CompetitionVibeCheckViewModel
        gameState = .teamSetup  // Reusing teamSetup state to signal we're ready to set up players
    }

    func startGame() {
        rounds = []
        // Reset scores
        for index in teams.indices {
            teams[index].score = 0
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

        guard let setter = promptSetterTeam else { return }

        let round = VibeCheckRound(
            roundNumber: roundNumber,
            spectrum: spectrum,
            targetPosition: targetPosition,
            promptSetterTeamId: setter.id
        )

        currentRound = round
        currentPrompt = ""
        currentGuessingTeamIndex = 0
        currentGuessPosition = 0.5

        gameState = .passingToPromptSetter
    }

    func confirmPromptSetterReady() {
        gameState = .promptEntry
    }

    func submitPrompt() {
        guard var round = currentRound, !currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        round.prompt = currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        currentRound = round
        currentGuessingTeamIndex = 0
        currentGuessPosition = 0.5

        if guessingTeams.isEmpty {
            // No guessing teams (shouldn't happen)
            gameState = .reveal
        } else {
            gameState = .passingToGuessingTeam(teamIndex: 0)
        }
    }

    func confirmGuessingTeamReady() {
        gameState = .guessing(teamIndex: currentGuessingTeamIndex)
    }

    func submitGuess() {
        guard var round = currentRound, let guessingTeam = currentGuessingTeam else { return }

        let (points, _) = VibeCheckScoringEngine.calculateScore(
            guessedPosition: currentGuessPosition,
            targetPosition: round.targetPosition
        )

        let guess = VibeCheckGuess(
            teamId: guessingTeam.id,
            guessedPosition: currentGuessPosition,
            pointsEarned: points
        )

        round.guesses.append(guess)
        currentRound = round

        // Update team score
        if let teamIndex = teams.firstIndex(where: { $0.id == guessingTeam.id }) {
            teams[teamIndex].score += points
        }

        // Move to next guessing team or reveal
        currentGuessingTeamIndex += 1
        currentGuessPosition = 0.5

        if currentGuessingTeamIndex >= guessingTeams.count {
            // All teams have guessed
            finalizeRound()
            gameState = .reveal
        } else {
            gameState = .passingToGuessingTeam(teamIndex: currentGuessingTeamIndex)
        }
    }

    // MARK: - Round Finalization

    private func finalizeRound() {
        guard var round = currentRound else { return }
        round.isComplete = true
        currentRound = round
        rounds.append(round)
    }

    func getRoundResults() -> [VibeCheckRoundResult] {
        guard let round = currentRound else { return [] }

        return round.guesses.compactMap { guess in
            guard let team = teams.first(where: { $0.id == guess.teamId }) else { return nil }
            let (_, zone) = VibeCheckScoringEngine.calculateScore(
                guessedPosition: guess.guessedPosition,
                targetPosition: round.targetPosition
            )
            return VibeCheckRoundResult(
                id: UUID(),
                teamId: team.id,
                teamName: team.name,
                guessedPosition: guess.guessedPosition,
                targetPosition: round.targetPosition,
                pointsEarned: guess.pointsEarned,
                zone: zone
            )
        }
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
        teams = []
        rounds = []
        currentRound = nil
        gameState = .setup
        currentPrompt = ""
        currentGuessPosition = 0.5
        currentGuessingTeamIndex = 0
    }

    func returnToSetup() {
        resetGame()
    }
}
