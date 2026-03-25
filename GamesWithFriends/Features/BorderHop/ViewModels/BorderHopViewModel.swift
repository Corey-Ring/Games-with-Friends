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

    // MARK: - Private State
    private(set) var graph: CountryGraph
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
        guard !hasArrived else { return }

        switch countryStates[countryId] {
        case .frontier:
            moveToCountry(countryId)
        case .destination:
            // Destination is tappable when adjacent to current country
            let neighbors = graph.neighborIds(of: currentCountryId)
            if neighbors.contains(countryId) {
                moveToCountry(countryId)
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
