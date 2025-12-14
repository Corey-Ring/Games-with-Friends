import Foundation

// MARK: - Enums

enum SocialContext: String, Codable, CaseIterable {
    case friends = "Friends"
    case family = "Family"
    case newPeople = "New People"
    case professional = "Professional"

    var description: String {
        switch self {
        case .friends:
            return "Close friends - playful & fun"
        case .family:
            return "Family gatherings - all ages"
        case .newPeople:
            return "Getting to know people"
        case .professional:
            return "Work & professional settings"
        }
    }

    var icon: String {
        switch self {
        case .friends: return "person.3.fill"
        case .family: return "house.fill"
        case .newPeople: return "hand.wave.fill"
        case .professional: return "briefcase.fill"
        }
    }
}

enum AgeGroup: String, Codable, CaseIterable {
    case kids = "Kids (8-12)"
    case teens = "Teens (13-17)"
    case adults = "Adults (18+)"
    case allAges = "All Ages"

    var icon: String {
        switch self {
        case .kids: return "figure.and.child.holdinghands"
        case .teens: return "figure.run"
        case .adults: return "person.fill"
        case .allAges: return "person.3.fill"
        }
    }
}

enum PromptCategory: String, Codable, CaseIterable {
    case entertainment = "Entertainment"
    case food = "Food & Drink"
    case geography = "Geography & Travel"
    case sports = "Sports & Activities"
    case science = "Science & Nature"
    case history = "History & Culture"
    case everyday = "Everyday Life"
    case abstract = "Abstract & Creative"
    case social = "Social & Relationships"
    case nostalgia = "Nostalgia & Generations"

    var icon: String {
        switch self {
        case .entertainment: return "tv.fill"
        case .food: return "fork.knife"
        case .geography: return "globe.americas.fill"
        case .sports: return "sportscourt.fill"
        case .science: return "atom"
        case .history: return "book.fill"
        case .everyday: return "house.fill"
        case .abstract: return "lightbulb.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .nostalgia: return "clock.arrow.circlepath"
        }
    }
}

enum Difficulty: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

// MARK: - Main Model

struct Name5Prompt: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let category: PromptCategory
    let difficulty: Difficulty
    let contexts: Set<SocialContext>
    let ageGroups: Set<AgeGroup>
    let followUpQuestion: String?

    init(
        id: UUID = UUID(),
        text: String,
        category: PromptCategory,
        difficulty: Difficulty,
        contexts: Set<SocialContext>,
        ageGroups: Set<AgeGroup>,
        followUpQuestion: String? = nil
    ) {
        self.id = id
        self.text = text
        self.category = category
        self.difficulty = difficulty
        self.contexts = contexts
        self.ageGroups = ageGroups
        self.followUpQuestion = followUpQuestion
    }

    func isAvailableFor(context: SocialContext, ageGroup: AgeGroup) -> Bool {
        return contexts.contains(context) && ageGroups.contains(ageGroup)
    }

    static func == (lhs: Name5Prompt, rhs: Name5Prompt) -> Bool {
        lhs.id == rhs.id
    }
}
