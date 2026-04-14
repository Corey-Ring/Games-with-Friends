//
//  FinishTheLineViewModel.swift
//  GamesWithFriends
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class FinishTheLineViewModel {

    // MARK: - Phase

    enum Phase: Equatable {
        case menu
        case countdown
        case playing
        case results
    }

    // MARK: - Configuration (tuneable during playtesting)

    static let roundDuration: TimeInterval = 60
    static let countdownDuration: TimeInterval = 3
    static let pointsPerCorrect: Int = 100
    static let streakBonusPerStep: Int = 25
    static let skipPenalty: Int = 25

    // MARK: - Observed state

    var phase: Phase = .menu

    // Menu selections
    var selectedCategories: Set<QuoteCategory> = Set(QuoteCategory.allCases)
    var selectedDecades: Set<QuoteDecade> = Set(QuoteDecade.allCases)
    var difficulty: QuoteDifficulty = .medium

    // Round state
    private(set) var currentQuote: Quote?
    private(set) var quoteQueue: [Quote] = []
    private(set) var timeRemaining: TimeInterval = roundDuration
    private(set) var score: Int = 0
    private(set) var currentStreak: Int = 0
    private(set) var bestStreak: Int = 0
    private(set) var correctQuotes: [Quote] = []
    private(set) var skippedQuotes: [Quote] = []

    // Feedback state
    private(set) var lastMatchedAt: Date?
    private(set) var showCorrectFlash: Bool = false

    // Countdown
    private(set) var countdownValue: Int = 3

    // Best score (loaded from SwiftData)
    private(set) var personalBest: Int = 0

    // MARK: - Infrastructure

    let speechManager = FinishTheLineSpeechRecognitionManager()
    private let modelContext: ModelContext?

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var countdownTimer: Timer?
    @ObservationIgnored private var lastHandledTranscription: String = ""

    // MARK: - Init

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        speechManager.matchHandler = { [weak self] transcription in
            self?.handleSpeechResult(transcription)
        }
        loadPersonalBest()
    }

    // MARK: - Derived

    /// Number of quotes that match the current filter selections.
    var availableQuoteCount: Int {
        filteredQuotes().count
    }

    var canStart: Bool {
        !selectedCategories.isEmpty && !selectedDecades.isEmpty && availableQuoteCount > 0
    }

    // MARK: - Menu toggles

    func toggleCategory(_ category: QuoteCategory) {
        if selectedCategories.contains(category) {
            selectedCategories.remove(category)
        } else {
            selectedCategories.insert(category)
        }
        HapticManager.selection()
    }

    func toggleDecade(_ decade: QuoteDecade) {
        if selectedDecades.contains(decade) {
            selectedDecades.remove(decade)
        } else {
            selectedDecades.insert(decade)
        }
        HapticManager.selection()
    }

    func setDifficulty(_ newDifficulty: QuoteDifficulty) {
        guard difficulty != newDifficulty else { return }
        difficulty = newDifficulty
        HapticManager.selection()
    }

    // MARK: - Phase transitions

    func startGame() {
        guard canStart else { return }
        guard speechManager.permissionStatus == .authorized else { return }

        // Reset round state
        score = 0
        currentStreak = 0
        bestStreak = 0
        correctQuotes = []
        skippedQuotes = []
        timeRemaining = Self.roundDuration
        lastHandledTranscription = ""

        // Build the queue
        var pool = filteredQuotes()
        pool.shuffle()
        quoteQueue = pool
        currentQuote = quoteQueue.popLast()

        // Kick off countdown
        phase = .countdown
        countdownValue = Int(Self.countdownDuration)
        HapticManager.medium()
        startCountdown()
    }

    func playAgain() {
        startGame()
    }

    func passPhone() {
        tearDownRound()
        phase = .menu
        loadPersonalBest()
    }

    func quitRound() {
        tearDownRound()
        phase = .menu
    }

    func skipCurrentQuote() {
        guard phase == .playing, let skipped = currentQuote else { return }
        skippedQuotes.append(skipped)
        score = max(0, score - Self.skipPenalty)
        currentStreak = 0
        HapticManager.selection()
        advanceToNextQuote()
    }

    // MARK: - Scene phase

    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background, .inactive:
            pause()
        case .active:
            resume()
        @unknown default:
            break
        }
    }

    private func pause() {
        guard phase == .playing else { return }
        stopTimer()
        speechManager.stopListening()
    }

    private func resume() {
        guard phase == .playing else { return }
        startTimer()
        speechManager.startListening()
    }

    // MARK: - Countdown

    private func startCountdown() {
        countdownTimer?.invalidate()
        countdownValue = Int(Self.countdownDuration)
        HapticManager.light()

        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.countdownValue -= 1
                if self.countdownValue > 0 {
                    HapticManager.light()
                } else {
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    HapticManager.heavy()
                    self.enterPlayingPhase()
                }
            }
        }
    }

    private func enterPlayingPhase() {
        phase = .playing
        timeRemaining = Self.roundDuration
        startTimer()
        speechManager.startListening()
    }

    // MARK: - Round timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.phase == .playing else { return }

                let previousTime = self.timeRemaining
                self.timeRemaining = max(0, self.timeRemaining - 0.1)

                // Trigger warning haptic once when crossing the 10s threshold
                if previousTime > 10 && self.timeRemaining <= 10 {
                    HapticManager.medium()
                }

                if self.timeRemaining <= 0 {
                    self.endRound()
                }
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Quote flow

    private func advanceToNextQuote() {
        guard phase == .playing else { return }

        if let next = quoteQueue.popLast() {
            currentQuote = next
            lastHandledTranscription = ""
        } else {
            // Ran out of quotes — end the round gracefully
            endRound()
        }
    }

    // MARK: - Speech handling

    private func handleSpeechResult(_ transcription: String) {
        guard phase == .playing, let quote = currentQuote else { return }

        // Avoid reprocessing the same transcription repeatedly.
        guard transcription != lastHandledTranscription else { return }
        lastHandledTranscription = transcription

        let normalized = normalize(transcription)
        guard !normalized.isEmpty else { return }

        let candidates = quote.acceptableAnswers.map(normalize)

        // Fast path: whole-string match
        for target in candidates where !target.isEmpty {
            if containsPhrase(target, in: normalized) {
                registerCorrect(for: quote)
                return
            }
        }

        // Sliding window match (1-4 word windows).
        let words = normalized.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return }

        for windowSize in 1...min(4, words.count) {
            for start in 0...(words.count - windowSize) {
                let phrase = words[start..<(start + windowSize)].joined(separator: " ")
                if candidates.contains(phrase) {
                    registerCorrect(for: quote)
                    return
                }
            }
        }
    }

    private func registerCorrect(for quote: Quote) {
        correctQuotes.append(quote)
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)
        let streakBonus = max(0, currentStreak - 1) * Self.streakBonusPerStep
        score += Self.pointsPerCorrect + streakBonus
        lastMatchedAt = Date()

        HapticManager.success()
        flashCorrect()

        // Small transition delay to let the card flash animate before the next quote lands.
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            self?.advanceToNextQuote()
        }
    }

    private func flashCorrect() {
        showCorrectFlash = true
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            self?.showCorrectFlash = false
        }
    }

    // MARK: - End of round

    private func endRound() {
        stopTimer()
        speechManager.stopListening()

        // Apply difficulty multiplier
        let finalScore = Int(Double(score) * difficulty.multiplier)
        score = finalScore

        saveResult()
        loadPersonalBest()
        phase = .results
        HapticManager.heavy()
    }

    private func tearDownRound() {
        stopTimer()
        countdownTimer?.invalidate()
        countdownTimer = nil
        speechManager.stopListening()
        currentQuote = nil
        quoteQueue = []
        showCorrectFlash = false
    }

    // MARK: - Filtering

    private func filteredQuotes() -> [Quote] {
        FinishTheLineQuoteData.allQuotes.filter { quote in
            selectedCategories.contains(quote.category)
                && selectedDecades.contains(quote.decade)
                && quote.difficulty == difficulty
        }
    }

    // MARK: - Normalization

    /// Lowercase, strip punctuation, collapse whitespace so that "With you!" == "with you".
    private func normalize(_ text: String) -> String {
        let lowered = text.lowercased()
        let stripped = lowered.unicodeScalars.map { scalar -> Character in
            if CharacterSet.alphanumerics.contains(scalar) || scalar == " " || scalar == "'" {
                return Character(scalar)
            } else {
                return " "
            }
        }
        let collapsed = String(stripped).split(separator: " ", omittingEmptySubsequences: true).joined(separator: " ")
        return collapsed
    }

    private func containsPhrase(_ needle: String, in haystack: String) -> Bool {
        guard !needle.isEmpty else { return false }
        // Match whole-word boundaries by wrapping in spaces
        let paddedHaystack = " \(haystack) "
        let paddedNeedle = " \(needle) "
        return paddedHaystack.contains(paddedNeedle)
    }

    // MARK: - Personal best persistence

    private func loadPersonalBest() {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<FinishTheLineRoundResult>(
            sortBy: [SortDescriptor(\FinishTheLineRoundResult.score, order: .reverse)]
        )
        if let results = try? modelContext.fetch(descriptor), let top = results.first {
            personalBest = top.score
        } else {
            personalBest = 0
        }
    }

    private func saveResult() {
        guard let modelContext else { return }
        let result = FinishTheLineRoundResult(
            score: score,
            correctCount: correctQuotes.count,
            skipCount: skippedQuotes.count,
            bestStreak: bestStreak,
            difficulty: difficulty,
            categories: selectedCategories,
            decades: selectedDecades
        )
        modelContext.insert(result)
        try? modelContext.save()
    }

    deinit {
        timer?.invalidate()
        countdownTimer?.invalidate()
    }
}
