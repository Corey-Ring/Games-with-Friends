import SwiftUI
import Combine

/// Main ViewModel for the Casting Director game
class CastingDirectorViewModel: ObservableObject {
    // MARK: - Published Properties

    // Game Configuration
    @Published var gameMode: CastingDirectorMode = .solo
    @Published var difficulty: CastingDirectorDifficulty = .medium
    @Published var era: CastingDirectorEra = .allEras
    @Published var players: [CastingDirectorPlayer] = [CastingDirectorPlayer(name: "Player 1")]
    @Published var numberOfRounds: Int = 5

    // Game State
    @Published var gamePhase: CastingDirectorPhase = .setup
    @Published var roundState = RoundState()
    @Published var currentPlayerIndex: Int = 0
    @Published var currentRound: Int = 1
    @Published var allClues: [Clue] = []
    @Published var isLoadingRound: Bool = false

    // Search
    @Published var searchQuery: String = ""
    @Published var searchResults: [Actor] = []
    @Published var isSearching: Bool = false
    @Published var showingGuessOverlay: Bool = false

    // Guess feedback
    @Published var wrongGuessShake: Bool = false
    @Published var correctGuess: Bool = false

    // High Scores (Solo)
    @Published var highScoreEasy: Int = 0
    @Published var highScoreMedium: Int = 0
    @Published var highScoreHard: Int = 0
    @Published var bestStreak: Int = 0

    // MARK: - Private Properties

    private let database = MovieChainDatabase.shared
    private let clueGenerator = ClueGenerator()
    private var clueTimer: Timer?
    private var searchCancellable: AnyCancellable?
    private var databaseCancellables = Set<AnyCancellable>()
    private var nextClueIndex: Int = 0
    private var currentStreak: Int = 0
    private var totalScore: Int = 0

    // Clue board layout
    @Published var cluePositions: [UUID: CluePosition] = [:]

    // MARK: - Computed Properties

    var currentPlayer: CastingDirectorPlayer {
        players[currentPlayerIndex]
    }

    var isDatabaseReady: Bool {
        database.isLoaded
    }

    var isDatabaseDecompressing: Bool {
        database.isDecompressing
    }

    var decompressionProgress: Double {
        database.decompressionProgress
    }

    var databaseError: String? {
        database.loadError
    }

    var potentialScore: Int {
        roundState.currentScore
    }

    var cluesRemaining: Int {
        allClues.count - roundState.cluesRevealed
    }

    var isAllCluesRevealed: Bool {
        roundState.cluesRevealed >= allClues.count
    }

    var isPreparingActorPool: Bool {
        isLoadingRound
    }

    // MARK: - Initialization

    init() {
        setupSearchDebounce()
        setupDatabaseObservation()
        loadHighScores()
    }

    deinit {
        clueTimer?.invalidate()
    }

    private func setupDatabaseObservation() {
        database.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &databaseCancellables)
    }

    // MARK: - Setup

    func setPlayerCount(_ count: Int) {
        players = (0..<count).map { index in
            CastingDirectorPlayer(name: "Player \(index + 1)")
        }
    }

    func updatePlayerName(at index: Int, to name: String) {
        guard index < players.count else { return }
        players[index].name = name
    }

    // MARK: - Game Flow

    func startGame() {
        guard isDatabaseReady else { return }

        currentRound = 1
        currentPlayerIndex = 0
        currentStreak = 0
        totalScore = 0

        // Reset player scores
        for i in 0..<players.count {
            players[i].score = 0
            players[i].correctGuesses = 0
            players[i].wrongGuesses = 0
        }

        clueGenerator.resetSession()
        startNewRound()
    }

    func startNewRound() {
        isLoadingRound = true
        roundState.reset()
        allClues = []
        nextClueIndex = 0
        cluePositions = [:]
        searchQuery = ""
        searchResults = []
        showingGuessOverlay = false
        correctGuess = false

        // Show the playing/loading screen immediately
        gamePhase = .playing

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            guard let actor = self.clueGenerator.pickRandomActor() else {
                DispatchQueue.main.async {
                    self.isLoadingRound = false
                }
                return
            }

            let clues = self.clueGenerator.generateClues(for: actor, difficulty: self.difficulty)

            DispatchQueue.main.async {
                self.roundState.targetActor = actor
                self.allClues = clues
                self.isLoadingRound = false
                self.revealNextClue()
                self.startClueTimer()
            }
        }
    }

    // MARK: - Clue Reveal

    private func startClueTimer() {
        clueTimer?.invalidate()
        clueTimer = Timer.scheduledTimer(withTimeInterval: difficulty.clueInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.revealNextClue()
        }
    }

    private func stopClueTimer() {
        clueTimer?.invalidate()
        clueTimer = nil
    }

    private func revealNextClue() {
        guard nextClueIndex < allClues.count else {
            stopClueTimer()
            // All clues revealed — auto-end round if no guess
            if !roundState.isComplete {
                roundState.currentScore = 0
                endRound(guessed: false)
            }
            return
        }

        let clue = allClues[nextClueIndex]
        roundState.revealedClues.append(clue)
        roundState.cluesRevealed += 1
        roundState.currentScore = max(0, roundState.currentScore - 50)

        // Assign a random position on the clue board
        assignPosition(for: clue)

        nextClueIndex += 1
    }

    private func assignPosition(for clue: Clue) {
        // Generate scatter parameters for the flow layout
        // xFraction controls horizontal offset/indent amount
        // rotation adds a slight tilt for the "desk" feel
        let xFraction = Double.random(in: 0.0...1.0)
        let rotation = Double.random(in: -2.0...2.0)

        let position = CluePosition(
            xFraction: xFraction,
            yFraction: 0, // unused in flow layout
            rotation: rotation
        )
        cluePositions[clue.id] = position
    }

    // MARK: - Guessing

    func submitGuess(_ actor: Actor) {
        showingGuessOverlay = false
        searchQuery = ""
        searchResults = []

        guard let target = roundState.targetActor else { return }

        if actor.nconst == target.nconst {
            // Correct!
            correctGuess = true
            stopClueTimer()

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)

            players[currentPlayerIndex].correctGuesses += 1
            players[currentPlayerIndex].score += roundState.currentScore
            totalScore += roundState.currentScore
            currentStreak += 1

            if currentStreak > bestStreak && gameMode == .solo {
                bestStreak = currentStreak
                saveHighScores()
            }

            roundState.isComplete = true
            roundState.foundByPlayer = players[currentPlayerIndex]

            // Reveal remaining clues for fun
            while nextClueIndex < allClues.count {
                let clue = allClues[nextClueIndex]
                roundState.revealedClues.append(clue)
                assignPosition(for: clue)
                nextClueIndex += 1
            }

            // Short delay then show results
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.gamePhase = .roundResult
            }
        } else {
            // Wrong guess
            wrongGuessShake = true
            roundState.wrongGuessCount += 1
            roundState.wrongGuesses.append(actor.name)
            roundState.currentScore = max(0, roundState.currentScore - difficulty.wrongGuessPenalty)
            players[currentPlayerIndex].wrongGuesses += 1

            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.wrongGuessShake = false
            }
        }
    }

    func giveUp() {
        stopClueTimer()
        roundState.currentScore = 0
        currentStreak = 0
        endRound(guessed: false)
    }

    private func endRound(guessed: Bool) {
        roundState.isComplete = true

        // Reveal remaining clues
        while nextClueIndex < allClues.count {
            let clue = allClues[nextClueIndex]
            roundState.revealedClues.append(clue)
            assignPosition(for: clue)
            nextClueIndex += 1
        }

        if !guessed {
            currentStreak = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.gamePhase = .roundResult
        }
    }

    // MARK: - Round Transitions

    func nextRound() {
        if gameMode == .passAndPlay {
            currentPlayerIndex = (currentPlayerIndex + 1) % players.count
            // Check if all players have played this round
            if currentPlayerIndex == 0 {
                currentRound += 1
            }
        } else {
            currentRound += 1
        }

        if currentRound > numberOfRounds {
            updateHighScores()
            gamePhase = .gameOver
        } else {
            startNewRound()
        }
    }

    func returnToSetup() {
        stopClueTimer()
        gamePhase = .setup
        roundState.reset()
        allClues = []
        searchQuery = ""
        searchResults = []
    }

    func playAgain() {
        startGame()
    }

    // MARK: - Search

    private func setupSearchDebounce() {
        searchCancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.performSearch(query: query)
            }
    }

    private func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            let actors = self.database.searchActors(query: trimmed, limit: 10)

            DispatchQueue.main.async {
                self.searchResults = actors
                self.isSearching = false
            }
        }
    }

    // MARK: - High Scores

    private func loadHighScores() {
        highScoreEasy = UserDefaults.standard.integer(forKey: "casting_director_high_easy")
        highScoreMedium = UserDefaults.standard.integer(forKey: "casting_director_high_medium")
        highScoreHard = UserDefaults.standard.integer(forKey: "casting_director_high_hard")
        bestStreak = UserDefaults.standard.integer(forKey: "casting_director_best_streak")
    }

    private func saveHighScores() {
        UserDefaults.standard.set(highScoreEasy, forKey: "casting_director_high_easy")
        UserDefaults.standard.set(highScoreMedium, forKey: "casting_director_high_medium")
        UserDefaults.standard.set(highScoreHard, forKey: "casting_director_high_hard")
        UserDefaults.standard.set(bestStreak, forKey: "casting_director_best_streak")
    }

    private func updateHighScores() {
        guard gameMode == .solo else { return }

        switch difficulty {
        case .easy:
            if totalScore > highScoreEasy { highScoreEasy = totalScore }
        case .medium:
            if totalScore > highScoreMedium { highScoreMedium = totalScore }
        case .hard:
            if totalScore > highScoreHard { highScoreHard = totalScore }
        }
        saveHighScores()
    }

    var highScore: Int {
        switch difficulty {
        case .easy: return highScoreEasy
        case .medium: return highScoreMedium
        case .hard: return highScoreHard
        }
    }

    // MARK: - Pass & Play

    var standings: [CastingDirectorPlayer] {
        players.sorted { $0.score > $1.score }
    }

    var winner: CastingDirectorPlayer? {
        standings.first
    }
}

// MARK: - Clue Position

struct CluePosition {
    let xFraction: Double
    let yFraction: Double
    let rotation: Double
}
