import SwiftUI
import Combine

/// Main ViewModel for the Movie Chain game
class MovieChainViewModel: ObservableObject {
    // MARK: - Published Properties

    // Game Configuration
    @Published var gameMode: MovieChainGameMode = .classic
    @Published var players: [MovieChainPlayer] = MovieChainPlayer.createPlayers(count: 2)
    @Published var timerDuration: Int = 30

    // Game State
    @Published var gamePhase: MovieChainPhase = .setup
    @Published var chain: [ChainLink] = []
    @Published var currentPlayerIndex: Int = 0
    @Published var turnType: TurnType = .actor  // First turn after starting movie is to name an actor

    // Timer
    @Published var timeRemaining: Int = 30
    @Published var isTimerRunning: Bool = false

    // Search
    @Published var searchQuery: String = ""
    @Published var searchResults: [SearchResult] = []
    @Published var isSearching: Bool = false

    // Statistics
    @Published var longestChainThisGame: Int = 0
    @Published var totalChainsCompleted: Int = 0

    // MARK: - Private Properties

    private var usedMovieIds: Set<String> = []
    private var usedActorIds: Set<String> = []
    private var timer: Timer?
    private var searchCancellable: AnyCancellable?
    private var databaseCancellables = Set<AnyCancellable>()
    private let database = MovieChainDatabase.shared

    // MARK: - Computed Properties

    var currentPlayer: MovieChainPlayer {
        players[currentPlayerIndex]
    }

    var currentMovieId: String? {
        guard let lastLink = chain.last else { return nil }
        if case .movie(let movie) = lastLink {
            return movie.tconst
        }
        // Find the last movie in the chain
        for link in chain.reversed() {
            if case .movie(let movie) = link {
                return movie.tconst
            }
        }
        return nil
    }

    var currentActorId: String? {
        guard let lastLink = chain.last else { return nil }
        if case .actor(let actor) = lastLink {
            return actor.nconst
        }
        return nil
    }

    /// Whether we're in the initial pick phase (chain is empty, player 1 picks first)
    var isInitialPick: Bool {
        chain.isEmpty
    }

    var currentPrompt: String {
        // Initial pick - player can choose either
        if chain.isEmpty {
            return "Pick an Actor or Movie to begin!"
        }

        guard let lastLink = chain.last else {
            return "Starting..."
        }

        switch lastLink {
        case .movie(let movie):
            return "Name an actor from \"\(movie.title)\""
        case .actor(let actor):
            return "Name a movie with \(actor.name)"
        }
    }

    var activePlayers: [MovieChainPlayer] {
        if gameMode == .classic {
            return players.filter { !$0.isEliminated }
        }
        return players
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

    // MARK: - Initialization

    init() {
        setupSearchDebounce()
        setupDatabaseObservation()
    }

    private func setupDatabaseObservation() {
        // Forward database state changes to trigger view updates
        database.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &databaseCancellables)
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Setup Methods

    func setPlayerCount(_ count: Int) {
        let lives = gameMode == .classic ? gameMode.defaultLives : 0
        players = MovieChainPlayer.createPlayers(count: count, lives: lives)
    }

    func updatePlayerName(at index: Int, to name: String) {
        guard index < players.count else { return }
        players[index].name = name
    }

    // MARK: - Game Flow

    func startGame() {
        guard isDatabaseReady else { return }

        // Reset game state
        chain = []
        usedMovieIds = []
        usedActorIds = []
        currentPlayerIndex = 0
        longestChainThisGame = 0
        totalChainsCompleted = 0
        searchQuery = ""
        searchResults = []

        // Reset player stats
        for i in 0..<players.count {
            players[i].lives = gameMode == .classic ? gameMode.defaultLives : 0
            players[i].score = 0
            players[i].linksContributed = 0
        }

        // Player 1 picks the first actor or movie - chain starts empty
        // turnType doesn't matter for initial pick since both are allowed
        gamePhase = .playing

        // Timer starts after first pick, not immediately
        // (handled in submitInitialPick)
    }

    func startNewChain() {
        chain = []
        usedMovieIds = []
        usedActorIds = []
        searchQuery = ""
        searchResults = []

        // Next player picks the starting actor or movie
        gamePhase = .playing
        advanceToNextPlayer()

        // Timer starts after first pick, not immediately
    }

    func submitAnswer(_ result: SearchResult) {
        stopTimer()

        // Handle initial pick (first item in chain)
        if chain.isEmpty {
            handleInitialPick(result)
            return
        }

        switch result {
        case .movie(let movie):
            handleMovieSubmission(movie)
        case .actor(let actor):
            handleActorSubmission(actor)
        }
    }

    /// Handle the first pick of a new chain (either actor or movie)
    private func handleInitialPick(_ result: SearchResult) {
        switch result {
        case .movie(let movie):
            chain.append(.movie(movie))
            usedMovieIds.insert(movie.tconst)
            turnType = .actor  // Next player names an actor from this movie

        case .actor(let actor):
            chain.append(.actor(actor))
            usedActorIds.insert(actor.nconst)
            turnType = .movie  // Next player names a movie with this actor
        }

        // Award points and update stats
        players[currentPlayerIndex].linksContributed += 1
        longestChainThisGame = max(longestChainThisGame, chain.count)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Clear search and advance to next player
        searchQuery = ""
        searchResults = []
        advanceToNextPlayer()

        // Now start the timer for subsequent turns
        if gameMode.hasTimer {
            startTimer()
        }
    }

    func giveUp() {
        stopTimer()
        handleChainBreak(reason: .playerGaveUp)
    }

    func endGame() {
        stopTimer()
        let winner = determineWinner()
        gamePhase = .gameOver(winner: winner)
    }

    func returnToSetup() {
        stopTimer()
        gamePhase = .setup
        chain = []
        usedMovieIds = []
        usedActorIds = []
        searchQuery = ""
        searchResults = []
    }

    // MARK: - Submission Handling

    private func handleMovieSubmission(_ movie: Movie) {
        // Check if movie was already used
        if usedMovieIds.contains(movie.tconst) {
            handleChainBreak(reason: .alreadyUsed(name: movie.title))
            return
        }

        // Validate that the current actor is in this movie
        guard let actorId = currentActorId,
              database.isActorInMovie(actorId: actorId, movieId: movie.tconst) else {
            let actorName: String
            if let lastLink = chain.last, case .actor(let actor) = lastLink {
                actorName = actor.name
            } else {
                actorName = "the actor"
            }
            handleChainBreak(reason: .invalidAnswer(submitted: movie.title, expected: actorName))
            return
        }

        // Valid submission!
        acceptSubmission(.movie(movie))
        usedMovieIds.insert(movie.tconst)
        turnType = .actor
    }

    private func handleActorSubmission(_ actor: Actor) {
        // Check if actor was already used
        if usedActorIds.contains(actor.nconst) {
            handleChainBreak(reason: .alreadyUsed(name: actor.name))
            return
        }

        // Validate that the actor is in the current movie
        guard let movieId = currentMovieId,
              database.isActorInMovie(actorId: actor.nconst, movieId: movieId) else {
            let movieName = chain.last.flatMap { link -> String? in
                if case .movie(let movie) = link { return movie.title }
                return nil
            } ?? "the movie"
            handleChainBreak(reason: .invalidAnswer(submitted: actor.name, expected: movieName))
            return
        }

        // Valid submission!
        acceptSubmission(.actor(actor))
        usedActorIds.insert(actor.nconst)
        turnType = .movie
    }

    private func acceptSubmission(_ link: ChainLink) {
        chain.append(link)
        players[currentPlayerIndex].linksContributed += 1

        // Award points in timed mode (bonus for speed)
        if gameMode.hasScoring {
            let basePoints = 100
            let speedBonus = timeRemaining * 3
            players[currentPlayerIndex].score += basePoints + speedBonus
        }

        // Update longest chain
        longestChainThisGame = max(longestChainThisGame, chain.count)

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Clear search and advance
        searchQuery = ""
        searchResults = []
        advanceToNextPlayer()

        if gameMode.hasTimer {
            startTimer()
        }
    }

    private func handleChainBreak(reason: ChainBreakReason) {
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)

        // Track chain completion
        totalChainsCompleted += 1

        // Handle consequences based on game mode
        if gameMode == .classic {
            players[currentPlayerIndex].lives -= 1

            // Check if player is eliminated
            if players[currentPlayerIndex].isEliminated {
                // Check if game is over (only 1 player left)
                if activePlayers.count <= 1 {
                    gamePhase = .gameOver(winner: activePlayers.first)
                    return
                }
            }
        }

        gamePhase = .chainBroken(reason: reason)
    }

    private func advanceToNextPlayer() {
        var nextIndex = (currentPlayerIndex + 1) % players.count
        var attempts = 0

        // Skip eliminated players in classic mode
        while gameMode == .classic && players[nextIndex].isEliminated && attempts < players.count {
            nextIndex = (nextIndex + 1) % players.count
            attempts += 1
        }

        currentPlayerIndex = nextIndex
    }

    private func determineWinner() -> MovieChainPlayer? {
        switch gameMode {
        case .classic:
            return activePlayers.first
        case .timed:
            return players.max(by: { $0.score < $1.score })
        case .endless:
            return players.max(by: { $0.linksContributed < $1.linksContributed })
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timeRemaining = timerDuration
        isTimerRunning = true

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.timeRemaining > 0 {
                self.timeRemaining -= 1

                // Warning haptic at 5 seconds
                if self.timeRemaining == 5 {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                }
            } else {
                self.stopTimer()
                self.handleChainBreak(reason: .timerExpired)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    func pauseTimer() {
        guard isTimerRunning else { return }
        timer?.invalidate()
        timer = nil
        isTimerRunning = false
    }

    func resumeTimer() {
        guard !isTimerRunning, case .playing = gamePhase, gameMode.hasTimer, timeRemaining > 0 else { return }
        isTimerRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if self.timeRemaining > 0 {
                self.timeRemaining -= 1

                if self.timeRemaining == 5 {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.warning)
                }
            } else {
                self.stopTimer()
                self.handleChainBreak(reason: .timerExpired)
            }
        }
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

            var results: [SearchResult] = []

            // Initial pick - search for both movies and actors
            if self.chain.isEmpty {
                // Search movies (top results by popularity)
                let movies = self.database.searchMovies(query: trimmed, limit: 5)
                let movieResults = movies.map { SearchResult.movie($0) }

                // Search actors
                let actors = self.database.searchActors(query: trimmed, limit: 5)
                let actorResults = actors.map { SearchResult.actor($0) }

                // Interleave results for variety
                results = zip(movieResults, actorResults).flatMap { [$0, $1] }
                // Add remaining from whichever has more
                if movieResults.count > actorResults.count {
                    results.append(contentsOf: movieResults.dropFirst(actorResults.count))
                } else if actorResults.count > movieResults.count {
                    results.append(contentsOf: actorResults.dropFirst(movieResults.count))
                }
            } else {
                // Normal gameplay - search based on turn type
                switch self.turnType {
                case .actor:
                    // Search for actors in the current movie
                    if let movieId = self.currentMovieId {
                        let actors = self.database.searchActorsInMovie(query: trimmed, movieId: movieId)
                        // Filter out already used actors
                        results = actors
                            .filter { !self.usedActorIds.contains($0.nconst) }
                            .map { .actor($0) }
                    }

                case .movie:
                    // Search for movies with the current actor
                    if let actorId = self.currentActorId {
                        let movies = self.database.searchMoviesWithActor(query: trimmed, actorId: actorId)
                        // Filter out already used movies
                        results = movies
                            .filter { !self.usedMovieIds.contains($0.tconst) }
                            .map { .movie($0) }
                    }
                }
            }

            DispatchQueue.main.async {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}

// MARK: - Search Result Type

enum SearchResult: Identifiable {
    case movie(Movie)
    case actor(Actor)

    var id: String {
        switch self {
        case .movie(let movie): return "m-\(movie.tconst)"
        case .actor(let actor): return "a-\(actor.nconst)"
        }
    }

    var displayName: String {
        switch self {
        case .movie(let movie): return movie.displayTitle
        case .actor(let actor): return actor.name
        }
    }

    var subtitle: String? {
        switch self {
        case .movie(let movie): return movie.genres
        case .actor(let actor): return actor.knownFor
        }
    }
}
