import Foundation

struct GameSettings {
    var playerCount: Int = 2
    var vibeLevel: Int = 3
    var selectedCategories: Set<Category> = Set(Category.allCases)
    var selectedThemes: Set<Theme> = []
    var timerEnabled: Bool = false
    var timerDuration: TimeInterval = 60

    init() {
        selectedThemes = Set(Theme.currentSeasonalThemes())
    }
}

enum TimerPreset: String, CaseIterable {
    case thirtySeconds = "30 seconds"
    case oneMinute = "1 minute"
    case twoMinutes = "2 minutes"
    case custom = "Custom"

    var duration: TimeInterval {
        switch self {
        case .thirtySeconds: return 30
        case .oneMinute: return 60
        case .twoMinutes: return 120
        case .custom: return 60
        }
    }
}
