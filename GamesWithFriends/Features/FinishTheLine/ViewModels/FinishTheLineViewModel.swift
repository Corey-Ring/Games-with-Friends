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

    /// How the current card was resolved. While non-nil the card holds on
    /// screen for a short "reveal beat" — the blank fills in, the source
    /// appears — before the next quote slides in.
    enum CardResolution: Equatable {
        case correct
        case skipped
    }

    // MARK: - Configuration (tuneable during playtesting)

    static let roundDuration: TimeInterval = 60
    static let maxRoundDuration: TimeInterval = 90
    static let countdownDuration: TimeInterval = 3
    static let streakBonusPerStep: Int = 25
    static let onFireThreshold: Int = 5
    static let onFireTimeBonus: TimeInterval = 2
    static let encoreWindow: TimeInterval = 10
    static let hintDelay: TimeInterval = 6
    static let correctBeatDuration: TimeInterval = 0.85
    static let skipBeatDuration: TimeInterval = 0.95
    /// How long the "GO" frame holds on screen before play begins, so it
    /// actually renders instead of being skipped as the phase flips.
    static let goFrameHold: TimeInterval = 0.4

    /// Points are difficulty-weighted per answer so the score on screen is
    /// always the real score — no invisible end-of-round multiplier jump.
    static func pointsPerCorrect(for difficulty: QuoteDifficulty) -> Int {
        switch difficulty {
        case .easy: return 100
        case .medium: return 150
        case .hard: return 200
        }
    }

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

    // Reveal beat / feedback state
    private(set) var cardResolution: CardResolution?
    private(set) var hintRevealed: Bool = false
    private(set) var nearMissCount: Int = 0
    private(set) var timeBonusCount: Int = 0
    private(set) var heardSnippet: String = ""

    // Pass-the-phone gauntlet (session-only, not persisted)
    private(set) var scoreToBeat: Int?
    private(set) var hasBeatenTarget: Bool = false

    // Countdown
    private(set) var countdownValue: Int = 3

    // Best score (loaded from SwiftData)
    private(set) var personalBest: Int = 0

    // MARK: - Derived

    var isOnFire: Bool {
        currentStreak >= Self.onFireThreshold
    }

    var isEncore: Bool {
        phase == .playing && timeRemaining > 0 && timeRemaining <= Self.encoreWindow
    }

    /// Number of quotes that match the current filter selections.
    var availableQuoteCount: Int {
        filteredQuotes().count
    }

    var canStart: Bool {
        !selectedCategories.isEmpty && !selectedDecades.isEmpty && availableQuoteCount > 0
    }

    // MARK: - Infrastructure

    let speechManager = FinishTheLineSpeechRecognitionManager()
    let soundPlayer = FinishTheLineSoundPlayer()
    private let modelContext: ModelContext?

    @ObservationIgnored private var timer: Timer?
    @ObservationIgnored private var countdownTimer: Timer?
    @ObservationIgnored private var goHoldTask: Task<Void, Never>?
    @ObservationIgnored private var hintTask: Task<Void, Never>?
    @ObservationIgnored private var lastHandledTranscription: String = ""
    /// Full transcription at the moment the current card appeared. Only speech
    /// spoken AFTER this point can answer the card — earlier chatter (or the
    /// previous card's answer) must not score.
    @ObservationIgnored private var cardTranscriptBaseline: String = ""
    @ObservationIgnored private var latestTranscription: String = ""
    @ObservationIgnored private var lastNearMissAt: Date = .distantPast

    // MARK: - Init

    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        speechManager.matchHandler = { [weak self] transcription in
            self?.handleSpeechResult(transcription)
        }
        loadPersonalBest()
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
        cardTranscriptBaseline = ""
        latestTranscription = ""
        cardResolution = nil
        hintRevealed = false
        heardSnippet = ""
        hasBeatenTarget = false

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
        // Solo replay from the results screen — a fresh run, not the
        // pass-the-phone gauntlet, so clear any lingering score to beat.
        scoreToBeat = nil
        startGame()
    }

    /// Hands the phone to the next player: the finished score becomes the
    /// session's score to beat.
    func passPhone() {
        if score > 0 {
            scoreToBeat = max(scoreToBeat ?? 0, score)
        }
        tearDownRound()
        phase = .menu
        loadPersonalBest()
    }

    func quitRound() {
        // Returning to the menu abandons any in-progress gauntlet.
        scoreToBeat = nil
        tearDownRound()
        phase = .menu
    }

    func skipCurrentQuote() {
        guard phase == .playing, cardResolution == nil, let skipped = currentQuote else { return }

        // Skipping is free — the streak reset is the price. The answer is
        // revealed for a beat so the room gets its groan.
        cardResolution = .skipped
        skippedQuotes.append(skipped)
        currentStreak = 0
        HapticManager.selection()
        soundPlayer.playSkip()
        scheduleAdvance(after: Self.skipBeatDuration)
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
        switch phase {
        case .playing:
            stopTimer()
            speechManager.stopListening()
        case .countdown:
            // Kill the countdown AND the GO-hold task — otherwise the hold
            // fires while backgrounded, starting the round timer and the mic
            // unseen (and resume() would then double-start listening).
            countdownTimer?.invalidate()
            countdownTimer = nil
            goHoldTask?.cancel()
        default:
            break
        }
    }

    private func resume() {
        switch phase {
        case .playing:
            startTimer()
            speechManager.startListening()
        case .countdown:
            // Restart the 3-2-1 from the top — fairer than resuming mid-beat.
            startCountdown()
        default:
            break
        }
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
                    // countdownValue is now 0 — the view shows the "GO" frame.
                    // Hold it briefly so it renders before play begins.
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    HapticManager.heavy()
                    self.holdGoFrameThenPlay()
                }
            }
        }
    }

    /// Keeps the "GO" frame on screen for a beat, then begins play. Guarded so
    /// a pause/quit during the hold can't strand the state machine in .countdown.
    private func holdGoFrameThenPlay() {
        goHoldTask?.cancel()
        goHoldTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.goFrameHold * 1_000_000_000))
            guard let self, !Task.isCancelled, self.phase == .countdown else { return }
            self.enterPlayingPhase()
        }
    }

    private func enterPlayingPhase() {
        phase = .playing
        timeRemaining = Self.roundDuration
        startTimer()
        speechManager.startListening()
        scheduleHint()
    }

    // MARK: - Round timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.phase == .playing else { return }

                let previousTime = self.timeRemaining
                self.timeRemaining = max(0, self.timeRemaining - 0.1)

                // Crossing into the Encore window
                if previousTime > Self.encoreWindow && self.timeRemaining <= Self.encoreWindow {
                    HapticManager.medium()
                }

                // Heartbeat tick on each whole-second crossing inside Encore
                if self.timeRemaining <= Self.encoreWindow && self.timeRemaining > 0 {
                    let previousSecond = Int(ceil(previousTime))
                    let currentSecond = Int(ceil(self.timeRemaining))
                    if previousSecond != currentSecond {
                        HapticManager.light()
                        self.soundPlayer.playTick()
                    }
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

    private func scheduleAdvance(after delay: TimeInterval) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            self?.advanceToNextQuote()
        }
    }

    private func advanceToNextQuote() {
        guard phase == .playing else { return }

        hintTask?.cancel()
        cardResolution = nil
        hintRevealed = false
        heardSnippet = ""
        lastHandledTranscription = ""
        cardTranscriptBaseline = latestTranscription

        if let next = quoteQueue.popLast() {
            currentQuote = next
            scheduleHint()
        } else {
            // Ran out of quotes — end the round gracefully
            endRound()
        }
    }

    /// After a stretch of silence on a card, the source fades in as a lifeline
    /// (some quotes need it: "Talk to me, ___"). No score penalty — the lost
    /// seconds are the price.
    private func scheduleHint() {
        hintTask?.cancel()
        guard let cardID = currentQuote?.id else { return }
        hintTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.hintDelay * 1_000_000_000))
            guard let self, !Task.isCancelled else { return }
            guard self.phase == .playing,
                  self.cardResolution == nil,
                  self.currentQuote?.id == cardID else { return }
            self.hintRevealed = true
        }
    }

    // MARK: - Speech handling

    private func handleSpeechResult(_ transcription: String) {
        latestTranscription = transcription

        guard phase == .playing, cardResolution == nil, let quote = currentQuote else { return }

        // Avoid reprocessing the same transcription repeatedly.
        guard transcription != lastHandledTranscription else { return }
        lastHandledTranscription = transcription

        // Only speech spoken after this card appeared may answer it. If the
        // recognizer restarted mid-card the transcript starts over, so the
        // baseline no longer prefixes it — treat the whole thing as new.
        var newPortion = transcription
        if !cardTranscriptBaseline.isEmpty {
            if transcription.hasPrefix(cardTranscriptBaseline) {
                newPortion = String(transcription.dropFirst(cardTranscriptBaseline.count))
            } else {
                cardTranscriptBaseline = ""
            }
        }

        let normalized = normalize(newPortion)
        guard !normalized.isEmpty else { return }

        let words = normalized.split(separator: " ").map(String.init)
        guard !words.isEmpty else { return }
        heardSnippet = words.suffix(4).joined(separator: " ")

        let candidates = quote.acceptableAnswers.map(normalize).filter { !$0.isEmpty }

        for target in candidates {
            if isShortCommonAnswer(target) {
                // Short everyday words ("it", "go", "back") show up constantly
                // in ambient chatter — only accept them as the freshest speech.
                let recent = words.suffix(3).joined(separator: " ")
                if containsPhrase(target, in: recent) {
                    registerCorrect(for: quote)
                    return
                }
            } else if containsPhrase(target, in: normalized) {
                registerCorrect(for: quote)
                return
            }
        }

        detectNearMiss(lastWords: words, candidates: candidates)
    }

    /// Single words of four letters or fewer are too common to match anywhere
    /// in the transcript — they must be among the last few words spoken.
    private func isShortCommonAnswer(_ candidate: String) -> Bool {
        !candidate.contains(" ") && candidate.count <= 4
    }

    private func detectNearMiss(lastWords: [String], candidates: [String]) {
        guard let lastWord = lastWords.last, lastWord.count >= 3 else { return }
        guard Date().timeIntervalSince(lastNearMissAt) > 1.5 else { return }

        for candidate in candidates where !candidate.contains(" ") && candidate.count >= 4 {
            let tolerance = candidate.count >= 7 ? 2 : 1
            if editDistance(lastWord, candidate) <= tolerance {
                lastNearMissAt = Date()
                nearMissCount += 1
                HapticManager.light()
                return
            }
        }
    }

    private func registerCorrect(for quote: Quote) {
        cardResolution = .correct
        correctQuotes.append(quote)
        currentStreak += 1
        bestStreak = max(bestStreak, currentStreak)

        var award = Self.pointsPerCorrect(for: quote.difficulty)
            + max(0, currentStreak - 1) * Self.streakBonusPerStep
        if isEncore {
            award *= 2
        }
        score += award

        if currentStreak == Self.onFireThreshold {
            soundPlayer.playIgnite()
        }
        if isOnFire {
            // Hot streaks buy time back — skill extends the performance.
            timeRemaining = min(timeRemaining + Self.onFireTimeBonus, Self.maxRoundDuration)
            timeBonusCount += 1
        }

        if let target = scoreToBeat, !hasBeatenTarget, score > target {
            hasBeatenTarget = true
            HapticManager.heavy()
            soundPlayer.playFanfare()
        }

        HapticManager.success()
        soundPlayer.playCorrect(streak: currentStreak)
        scheduleAdvance(after: Self.correctBeatDuration)
    }

    // MARK: - End of round

    private func endRound() {
        stopTimer()
        hintTask?.cancel()
        speechManager.stopListening()

        saveResult()
        loadPersonalBest()
        phase = .results
        HapticManager.heavy()
        soundPlayer.playBuzzer()
    }

    private func tearDownRound() {
        stopTimer()
        countdownTimer?.invalidate()
        countdownTimer = nil
        goHoldTask?.cancel()
        hintTask?.cancel()
        speechManager.stopListening()
        currentQuote = nil
        quoteQueue = []
        cardResolution = nil
        hintRevealed = false
        heardSnippet = ""
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

    /// Levenshtein distance over characters; inputs are short spoken words.
    private func editDistance(_ a: String, _ b: String) -> Int {
        let aChars = Array(a), bChars = Array(b)
        if aChars.isEmpty { return bChars.count }
        if bChars.isEmpty { return aChars.count }

        var previous = Array(0...bChars.count)
        var current = [Int](repeating: 0, count: bChars.count + 1)

        for i in 1...aChars.count {
            current[0] = i
            for j in 1...bChars.count {
                let substitution = previous[j - 1] + (aChars[i - 1] == bChars[j - 1] ? 0 : 1)
                current[j] = min(previous[j] + 1, current[j - 1] + 1, substitution)
            }
            swap(&previous, &current)
        }
        return previous[bChars.count]
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
        goHoldTask?.cancel()
        hintTask?.cancel()
    }
}
