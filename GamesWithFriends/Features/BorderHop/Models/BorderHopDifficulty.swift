import SwiftUI

enum BorderHopDifficulty: String, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var subtitle: String {
        switch self {
        case .easy: return "Same Region"
        case .medium: return "Adjacent Regions"
        case .hard: return "Cross-Continental"
        case .expert: return "Maximum Distance"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Countries within the same continent"
        case .medium: return "Cross nearby continental boundaries"
        case .hard: return "Opposite sides of the world"
        case .expert: return "The longest possible land routes"
        }
    }

    var minHops: Int {
        switch self {
        case .easy: return 3
        case .medium: return 5
        case .hard: return 8
        case .expert: return 12
        }
    }

    var benchmarkTime: TimeInterval {
        switch self {
        case .easy: return 90
        case .medium: return 75
        case .hard: return 120
        case .expert: return 150
        }
    }

    var badgeColor: Color {
        switch self {
        case .easy: return AppTheme.success
        case .medium: return AppTheme.warning
        case .hard: return AppTheme.coralRed
        case .expert: return AppTheme.electricIndigo
        }
    }

    /// Region pairing rules for route generation
    var allowedRegionPairs: [(String, String)]? {
        switch self {
        case .easy: return nil // same region enforced separately
        case .medium:
            return [
                ("Europe", "Africa"),
                ("Europe", "Asia"),
                ("Africa", "Asia"),
                ("Americas", "Americas"), // North to South
            ]
        case .hard, .expert: return nil // any combination allowed
        }
    }

    var requireSameRegion: Bool {
        self == .easy
    }
}
