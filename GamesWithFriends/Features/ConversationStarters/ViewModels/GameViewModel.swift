import Foundation
import SwiftUI
import Combine
import AVFoundation

@MainActor
class GameViewModel: ObservableObject {
    @Published var settings = GameSettings()
    @Published var currentIndex = 0
    @Published var filteredStarters: [ConversationStarter] = []
    @Published var shownStarterIDs: Set<UUID> = []
    @Published var savedStarterIDs: Set<UUID> = []
    @Published var timeRemaining: TimeInterval = 60
    @Published var isTimerRunning = false

    private var timer: Timer?
    private let savedStartersKey = "SavedStarters"
    private var audioPlayer: AVAudioPlayer?

    init() {
        loadSavedStarters()
        updateFilteredStarters()
        prepareAudio()
    }

    private func prepareAudio() {
        if let soundURL = Bundle.main.url(forResource: "timer_end", withExtension: "wav") {
            try? audioPlayer = AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
        }
    }

    func updateFilteredStarters() {
        var starters = ConversationStarterData.allStarters

        // Filter by vibe level (show starters at or below selected level)
        starters = starters.filter { $0.vibeLevel <= settings.vibeLevel }

        // Filter by player count
        starters = starters.filter { starter in
            guard let minPlayers = starter.minPlayers else { return true }
            return settings.playerCount >= minPlayers
        }

        // Filter by categories
        starters = starters.filter { settings.selectedCategories.contains($0.category) }

        // Filter by themes
        starters = starters.filter { starter in
            starter.themes.contains { settings.selectedThemes.contains($0) }
        }

        // Remove already shown starters
        starters = starters.filter { !shownStarterIDs.contains($0.id) }

        // Shuffle
        filteredStarters = starters.shuffled()
        currentIndex = 0
    }

    var currentStarter: ConversationStarter? {
        guard !filteredStarters.isEmpty, currentIndex < filteredStarters.count else {
            return nil
        }
        return filteredStarters[currentIndex]
    }

    var hasNext: Bool {
        currentIndex < filteredStarters.count - 1
    }

    var hasPrevious: Bool {
        currentIndex > 0
    }

    func nextStarter() {
        if let current = currentStarter {
            shownStarterIDs.insert(current.id)
        }

        if hasNext {
            currentIndex += 1
            resetTimer()
        }
    }

    func previousStarter() {
        if hasPrevious {
            currentIndex -= 1
            resetTimer()
        }
    }

    func shuffle() {
        filteredStarters.shuffle()
        currentIndex = 0
        resetTimer()
    }

    func resetDeck() {
        shownStarterIDs.removeAll()
        updateFilteredStarters()
        resetTimer()
    }

    func isStarred(_ starter: ConversationStarter) -> Bool {
        savedStarterIDs.contains(starter.id)
    }

    func toggleStar(_ starter: ConversationStarter) {
        if savedStarterIDs.contains(starter.id) {
            savedStarterIDs.remove(starter.id)
        } else {
            savedStarterIDs.insert(starter.id)
        }
        saveSavedStarters()
    }

    var savedStarters: [ConversationStarter] {
        ConversationStarterData.allStarters.filter { savedStarterIDs.contains($0.id) }
    }

    // Timer functions
    func startTimer() {
        guard settings.timerEnabled else { return }
        isTimerRunning = true
        timeRemaining = settings.timerDuration

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timerExpired()
                }
            }
        }
    }

    func pauseTimer() {
        isTimerRunning = false
        timer?.invalidate()
    }

    func resetTimer() {
        timer?.invalidate()
        isTimerRunning = false
        timeRemaining = settings.timerDuration
        if settings.timerEnabled {
            startTimer()
        }
    }

    private func timerExpired() {
        pauseTimer()
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    // Persistence
    private func saveSavedStarters() {
        let idsArray = Array(savedStarterIDs).map { $0.uuidString }
        UserDefaults.standard.set(idsArray, forKey: savedStartersKey)
    }

    private func loadSavedStarters() {
        if let idsArray = UserDefaults.standard.array(forKey: savedStartersKey) as? [String] {
            savedStarterIDs = Set(idsArray.compactMap { UUID(uuidString: $0) })
        }
    }

    deinit {
        timer?.invalidate()
    }
}
