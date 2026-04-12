import SwiftUI

enum BorderHopPhase: Equatable {
    case menu
    case loading
    case playing
    case results
}

@MainActor
@Observable
class BorderHopViewModel {
    // MARK: - Public State
    var phase: BorderHopPhase = .menu
    var selectedDifficulty: BorderHopDifficulty = .easy

    // Game state
    var currentCountryId: String = ""
    var destinationCountryId: String = ""
    var startCountryId: String = ""
    var countryStates: [String: CountryState] = [:]
    var actualPath: [String] = []
    var elapsedTime: TimeInterval = 0
    var hopCount: Int = 0
    var currentStreak: Int = 0
    var roundResult: BorderHopRoundResult?
    var showBacktrackConfirm: Bool = false
    var backtrackTargetId: String?
    var hasArrived: Bool = false

    // Quiz state
    var isQuizActive: Bool = false
    var currentQuizQuestion: QuizQuestion? = nil
    var eliminatedChoices: Set<String> = []
    var strikeCount: Int = 0
    var showTimeReward: Bool = false

    // MARK: - Private State
    private(set) var graph: CountryGraph
    private var quizEngine = QuizEngine()
    private var optimalPath: [String] = []
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var timerStartDate: Date?
    @ObservationIgnored private var pauseOffset: TimeInterval = 0
    private var benchmarkCrossed: Bool = false
    @ObservationIgnored private var lastBenchmarkPulse: TimeInterval = 0

    // MARK: - Computed
    var gameStarted: Bool {
        phase != .menu
    }

    var currentCountry: BorderHopCountry? {
        graph.country(for: currentCountryId)
    }

    var destinationCountry: BorderHopCountry? {
        graph.country(for: destinationCountryId)
    }

    var startCountry: BorderHopCountry? {
        graph.country(for: startCountryId)
    }

    var optimalHopCount: Int {
        max(optimalPath.count - 1, 0)
    }

    var frontierCountryIds: [String] {
        countryStates.compactMap { $0.value == .frontier ? $0.key : nil }
    }

    var streakMultiplier: Double {
        min(1.0 + Double(max(currentStreak - 1, 0)) * 0.1, 2.0)
    }

    var stopwatchColor: Color {
        if elapsedTime < 120 { return .white }
        else if elapsedTime < 300 { return AppTheme.warning }
        else { return AppTheme.error }
    }

    // MARK: - Initialization

    init() {
        let countries = BorderHopCountryData.loadCountries()
        self.graph = CountryGraph(countries: countries)
    }

    // MARK: - Game Flow

    func selectDifficulty(_ difficulty: BorderHopDifficulty) {
        selectedDifficulty = difficulty
        HapticManager.selection()
    }

    func startGame() {
        guard let route = graph.generateRoute(difficulty: selectedDifficulty) else { return }

        startCountryId = route.startId
        destinationCountryId = route.destinationId
        optimalPath = route.optimalPath
        currentCountryId = route.startId
        actualPath = [route.startId]
        elapsedTime = 0
        hopCount = 0
        hasArrived = false
        roundResult = nil
        benchmarkCrossed = false
        lastBenchmarkPulse = 0
        showBacktrackConfirm = false
        backtrackTargetId = nil
        isQuizActive = false
        currentQuizQuestion = nil
        eliminatedChoices = []
        strikeCount = 0
        showTimeReward = false
        quizEngine.resetUsedFacts()
        quizEngine.resetTypeSelector()

        // Initialize country states
        initializeCountryStates()

        HapticManager.medium()
        phase = .loading
    }

    func beginPlaying() {
        phase = .playing
        startTimer()
    }

    func moveToCountry(_ id: String) {
        guard countryStates[id] == .frontier || countryStates[id] == .destination else { return }
        guard !hasArrived else { return }

        HapticManager.medium()

        // Update previous current to visited
        countryStates[currentCountryId] = .visited

        // Move
        currentCountryId = id
        actualPath.append(id)
        hopCount += 1
        countryStates[id] = .current

        // Check arrival
        if id == destinationCountryId {
            arriveAtDestination()
            return
        }

        // Reveal new neighbors
        revealNeighbors(of: id)

        // Re-fog orphaned frontiers (frontiers that are no longer adjacent to current)
        cleanupOrphanedFrontiers()
    }

    func requestBacktrack(to id: String) {
        guard countryStates[id] == .visited else { return }
        backtrackTargetId = id
        showBacktrackConfirm = true
    }

    func confirmBacktrack() {
        guard let targetId = backtrackTargetId else { return }
        showBacktrackConfirm = false

        HapticManager.error()

        // Apply time penalty
        elapsedTime += 5.0

        // Update previous current to visited
        countryStates[currentCountryId] = .visited

        // Move back
        currentCountryId = targetId
        actualPath.append(targetId)
        hopCount += 1
        countryStates[targetId] = .current

        // Re-reveal neighbors
        revealNeighbors(of: targetId)
        cleanupOrphanedFrontiers()

        backtrackTargetId = nil
    }

    func cancelBacktrack() {
        showBacktrackConfirm = false
        backtrackTargetId = nil
    }

    func handleTap(countryId: String) {
        guard !hasArrived, !isQuizActive else { return }

        switch countryStates[countryId] {
        case .frontier:
            initiateQuiz(for: countryId)
        case .destination:
            // Destination is tappable when adjacent to current country
            let neighbors = graph.neighborIds(of: currentCountryId)
            if neighbors.contains(countryId) {
                initiateQuiz(for: countryId)
            } else {
                HapticManager.light()
            }
        case .visited:
            requestBacktrack(to: countryId)
        case .fogged:
            HapticManager.light()
        default:
            break
        }
    }

    // MARK: - Quiz

    func initiateQuiz(for targetCountryId: String) {
        let question = quizEngine.generateQuestion(
            correctCountryId: targetCountryId,
            frontierCountryIds: frontierCountryIds,
            graph: graph
        )

        guard let question else {
            // No fun facts available — free passage
            moveToCountry(targetCountryId)
            return
        }

        currentQuizQuestion = question
        eliminatedChoices = []
        strikeCount = 0
        isQuizActive = true
        HapticManager.light()
    }

    func submitQuizAnswer(_ answer: String) {
        guard let question = currentQuizQuestion else { return }

        let isCorrect: Bool
        switch question.type {
        case .funFact:
            isCorrect = (answer == question.correctFact)
        case .flagIdentification, .export:
            isCorrect = (answer == question.countryId)
        }

        if isCorrect {
            handleCorrectAnswer()
        } else {
            handleWrongAnswer(answer)
        }
    }

    private func handleCorrectAnswer() {
        guard let question = currentQuizQuestion else { return }

        // Subtract 3 seconds reward (adjust pauseOffset so timer computes correctly)
        pauseOffset -= 3.0
        elapsedTime = max(0, elapsedTime - 3.0)
        showTimeReward = true

        // Dismiss quiz and advance
        isQuizActive = false
        currentQuizQuestion = nil
        HapticManager.success()
        moveToCountry(question.countryId)

        // Reset time reward flash after delay
        Task {
            try? await Task.sleep(for: .seconds(1.0))
            showTimeReward = false
        }
    }

    private func handleWrongAnswer(_ selectedFact: String) {
        eliminatedChoices.insert(selectedFact)
        strikeCount += 1
        HapticManager.error()

        if strikeCount >= 3 {
            handleTeleport()
        }
    }

    private func handleTeleport() {
        isQuizActive = false
        currentQuizQuestion = nil
        strikeCount = 0
        HapticManager.heavy()

        if let teleportTarget = findTeleportDestination() {
            moveToCountry(teleportTarget)
        } else {
            // Fallback: prevents deadlock in extremely rare edge case
        }
    }

    private func findTeleportDestination() -> String? {
        let reachable = graph.reachableWithDistances(from: currentCountryId)
        let validTargets = reachable.keys.filter { countryId in
            countryId != currentCountryId &&
            countryId != destinationCountryId &&
            graph.shortestPath(from: countryId, to: destinationCountryId) != nil
        }
        return validTargets.randomElement()
    }

    func playAgain() {
        startGame()
    }

    func changeDifficulty() {
        stopTimer()
        phase = .menu
    }

    func quitGame() {
        stopTimer()
        phase = .menu
    }

    func pauseGame() {
        guard timer != nil else { return }
        pauseOffset = elapsedTime
        stopTimer()
    }

    func resumeGame() {
        guard phase == .playing, timer == nil, !hasArrived else { return }
        startTimer()
    }

    // MARK: - Private Methods

    private func initializeCountryStates() {
        var states: [String: CountryState] = [:]

        // All countries start fogged
        for country in graph.allCountries {
            states[country.id] = .fogged
        }

        // Mark start as current
        states[startCountryId] = .current

        // Mark destination (visible through fog)
        states[destinationCountryId] = .destination

        // Reveal start's neighbors as frontier
        for neighborId in graph.neighborIds(of: startCountryId) {
            if neighborId != destinationCountryId {
                states[neighborId] = .frontier
            } else {
                // Destination is also a frontier if adjacent to start
                states[neighborId] = .destination
            }
        }

        countryStates = states
    }

    private func revealNeighbors(of countryId: String) {
        let neighborIds = graph.neighborIds(of: countryId)
        for neighborId in neighborIds {
            let currentState = countryStates[neighborId]
            // Only reveal fogged countries as frontier
            if currentState == .fogged {
                countryStates[neighborId] = .frontier
            }
            // If destination is a neighbor, keep it as destination (tappable when frontier)
        }

        // After a short delay, fire the reveal haptic
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            HapticManager.light()
        }
    }

    private func cleanupOrphanedFrontiers() {
        // Get all neighbors of all visited + current countries
        var validFrontierIds: Set<String> = []
        for (id, state) in countryStates where state == .current || state == .visited {
            validFrontierIds.formUnion(graph.neighborIds(of: id))
        }

        // Re-fog any frontier that isn't adjacent to a visited/current country
        for (id, state) in countryStates where state == .frontier {
            if !validFrontierIds.contains(id) {
                countryStates[id] = .fogged
            }
        }
    }

    private func arriveAtDestination() {
        hasArrived = true
        stopTimer()
        HapticManager.success()

        // Keep destination marked as current upon arrival
        countryStates[destinationCountryId] = .current

        // Calculate result
        let funFacts = optimalPath.compactMap { graph.country(for: $0)?.funFacts.first }
        let shuffledFacts = Array(funFacts.shuffled().prefix(3))

        var result = BorderHopRoundResult(
            difficulty: selectedDifficulty,
            startCountryId: startCountryId,
            destinationCountryId: destinationCountryId,
            actualPath: actualPath,
            optimalPath: optimalPath,
            elapsedTime: elapsedTime,
            funFacts: shuffledFacts
        )
        result.streakMultiplier = streakMultiplier
        roundResult = result

        // Update streak
        if elapsedTime < selectedDifficulty.benchmarkTime * 2 {
            currentStreak += 1
        } else {
            currentStreak = 0
        }

        // Transition to results after celebration delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.phase = .results
        }
    }

    // MARK: - Timer

    private func startTimer() {
        timerStartDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let startDate = self.timerStartDate else { return }
                self.elapsedTime = Date().timeIntervalSince(startDate) + self.pauseOffset
                self.checkBenchmarkCrossing()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerStartDate = nil
    }

    private func checkBenchmarkCrossing() {
        let benchmark = selectedDifficulty.benchmarkTime
        if !benchmarkCrossed && elapsedTime >= benchmark {
            benchmarkCrossed = true
            lastBenchmarkPulse = elapsedTime
            HapticManager.heavy()
        } else if benchmarkCrossed && elapsedTime - lastBenchmarkPulse >= 30 {
            lastBenchmarkPulse = elapsedTime
            HapticManager.heavy()
        }
    }
}
