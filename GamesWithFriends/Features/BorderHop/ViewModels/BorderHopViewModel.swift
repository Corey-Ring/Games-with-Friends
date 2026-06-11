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
    var bordersRemaining: Int = 0
    /// Change in bordersRemaining from the last hop: negative = got closer
    var bordersRemainingDelta: Int = 0
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
    /// True once the current question is answered (correctly or revealed) — input locked,
    /// takeaway showing, dismissal scheduled.
    var quizResolved: Bool = false
    /// True when the question was resolved by revealing the answer after 3 strikes
    var quizRevealedAnswer: Bool = false
    /// The takeaway for the question that just resolved, shown briefly in the quiz sheet
    var currentTakeaway: LearnedFact? = nil
    /// Everything the player saw this round, recapped on the results screen
    private(set) var learnedFacts: [LearnedFact] = []

    // MARK: - Private State
    private(set) var graph: CountryGraph
    private var quizEngine = QuizEngine()
    private var optimalPath: [String] = []
    private var questionCredits: [Double] = []
    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var timerStartDate: Date?
    @ObservationIgnored private var pauseOffset: TimeInterval = 0

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

    /// Quiz credit earned so far this round, as a 0–1 ratio
    var roundAccuracy: Double {
        guard !questionCredits.isEmpty else { return 1.0 }
        return questionCredits.reduce(0, +) / Double(questionCredits.count)
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
        pauseOffset = 0
        hopCount = 0
        hasArrived = false
        roundResult = nil
        showBacktrackConfirm = false
        backtrackTargetId = nil
        resetQuizState()
        learnedFacts = []
        questionCredits = []
        quizEngine.resetUsedFacts()
        quizEngine.resetTypeSelector()

        // Initialize country states
        initializeCountryStates()
        bordersRemaining = max(optimalPath.count - 1, 0)
        bordersRemainingDelta = 0

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

        updateBordersRemaining()

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

        HapticManager.medium()

        // Backtracking costs a hop (route efficiency) — no time penalty; the score
        // model rewards routing and knowledge, not speed.
        countryStates[currentCountryId] = .visited

        // Move back
        currentCountryId = targetId
        actualPath.append(targetId)
        hopCount += 1
        countryStates[targetId] = .current

        updateBordersRemaining()

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
            // No quiz material available — free passage
            moveToCountry(targetCountryId)
            return
        }

        currentQuizQuestion = question
        eliminatedChoices = []
        strikeCount = 0
        quizResolved = false
        quizRevealedAnswer = false
        currentTakeaway = nil
        isQuizActive = true
        HapticManager.light()
    }

    func submitQuizAnswer(_ answer: String) {
        guard let question = currentQuizQuestion, !quizResolved else { return }

        let isCorrect: Bool
        switch question.type {
        case .funFact, .export:
            isCorrect = (answer == question.correctFact)
        case .flagIdentification, .capital:
            isCorrect = (answer == question.countryId)
        }

        if isCorrect {
            let credit: Double
            switch strikeCount {
            case 0: credit = 1.0
            case 1: credit = 0.5
            default: credit = 0.25
            }
            resolveQuiz(question: question, credit: credit, revealed: false)
        } else {
            eliminatedChoices.insert(answer)
            strikeCount += 1
            HapticManager.error()

            // Third strike: reveal the answer (the teaching moment) and cross anyway.
            // Progress is never blocked — the cost is knowledge credit, not a random
            // teleport that disorients the player.
            if strikeCount >= 3 {
                resolveQuiz(question: question, credit: 0, revealed: true)
            }
        }
    }

    private func resolveQuiz(question: QuizQuestion, credit: Double, revealed: Bool) {
        quizResolved = true
        quizRevealedAnswer = revealed
        questionCredits.append(credit)

        let takeaway = makeTakeaway(for: question, credit: credit)
        currentTakeaway = takeaway
        learnedFacts.append(takeaway)

        if revealed {
            HapticManager.heavy()
        } else {
            HapticManager.success()
        }

        // Hold the takeaway on screen long enough to read, then cross the border
        let holdDuration: Double = revealed ? 2.2 : 1.4
        Task {
            try? await Task.sleep(for: .seconds(holdDuration))
            guard phase == .playing, isQuizActive,
                  currentQuizQuestion?.countryId == question.countryId else { return }
            isQuizActive = false
            currentQuizQuestion = nil
            currentTakeaway = nil
            quizResolved = false
            quizRevealedAnswer = false
            moveToCountry(question.countryId)
        }
    }

    /// The one-line fact this question taught, phrased for retention
    private func makeTakeaway(for question: QuizQuestion, credit: Double) -> LearnedFact {
        let name = graph.country(for: question.countryId)?.name ?? question.countryId
        let flag = CountryFlagProvider.flag(for: question.countryId) ?? ""

        let text: String
        switch question.type {
        case .flagIdentification:
            text = "\(flag) is the flag of \(name)"
        case .capital:
            let capital = graph.country(for: question.countryId)?.capital ?? ""
            text = "\(capital) is the capital of \(name)"
        case .export:
            let export = (question.correctFact ?? "").localizedCapitalized
            text = "\(name)'s #1 export is \(export.isEmpty ? "—" : export)"
        case .funFact:
            text = "\(name): \(question.correctFact ?? "")"
        }

        return LearnedFact(
            countryId: question.countryId,
            flag: flag,
            text: text,
            gotItFirstTry: credit >= 1.0
        )
    }

    private func resetQuizState() {
        isQuizActive = false
        currentQuizQuestion = nil
        eliminatedChoices = []
        strikeCount = 0
        quizResolved = false
        quizRevealedAnswer = false
        currentTakeaway = nil
    }

    func playAgain() {
        startGame()
    }

    func changeDifficulty() {
        stopTimer()
        resetQuizState()
        phase = .menu
    }

    func quitGame() {
        stopTimer()
        resetQuizState()
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

    private func updateBordersRemaining() {
        let previous = bordersRemaining
        let path = graph.shortestPath(from: currentCountryId, to: destinationCountryId)
        bordersRemaining = max((path?.count ?? 1) - 1, 0)
        bordersRemainingDelta = bordersRemaining - previous
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

        var result = BorderHopRoundResult(
            difficulty: selectedDifficulty,
            startCountryId: startCountryId,
            destinationCountryId: destinationCountryId,
            actualPath: actualPath,
            optimalPath: optimalPath,
            elapsedTime: elapsedTime,
            learnedFacts: learnedFacts,
            questionCredits: questionCredits
        )
        result.streakMultiplier = streakMultiplier
        roundResult = result

        // Streak rewards knowledge, not speed: it continues when the round's quiz
        // accuracy stays at 75%+ credit
        if roundAccuracy >= 0.75 {
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
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        timerStartDate = nil
    }
}
