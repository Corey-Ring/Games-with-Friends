import Foundation

struct ConversationStarter: Identifiable, Codable, Equatable {
    let id: UUID
    let text: String
    let vibeLevel: Int // 1-5
    let category: Category
    let themes: [Theme]
    let minPlayers: Int?

    init(id: UUID = UUID(), text: String, vibeLevel: Int, category: Category, themes: [Theme] = [.evergreen], minPlayers: Int? = nil) {
        self.id = id
        self.text = text
        self.vibeLevel = vibeLevel
        self.category = category
        self.themes = themes
        self.minPlayers = minPlayers
    }
}

enum Category: String, Codable, CaseIterable {
    case wouldYouRather = "Would You Rather"
    case hotTakes = "Hot Takes"
    case hypotheticals = "Hypotheticals"
    case storyTime = "Story Time"
    case thisOrThat = "This or That"
    case deepDive = "Deep Dive"

    var icon: String {
        switch self {
        case .wouldYouRather: return "arrow.left.arrow.right"
        case .hotTakes: return "flame.fill"
        case .hypotheticals: return "lightbulb.fill"
        case .storyTime: return "book.fill"
        case .thisOrThat: return "circle.lefthalf.filled"
        case .deepDive: return "arrow.down.circle.fill"
        }
    }
}

enum Theme: String, Codable, CaseIterable {
    case evergreen = "Evergreen"
    case thanksgiving = "Thanksgiving"
    case halloween = "Halloween"
    case winterHolidays = "Winter Holidays"
    case newYear = "New Year"
    case valentines = "Valentine's Day"
    case summer = "Summer"
    case backToSchool = "Back to School"

    var icon: String {
        switch self {
        case .evergreen: return "star.fill"
        case .thanksgiving: return "leaf.fill"
        case .halloween: return "moon.fill"
        case .winterHolidays: return "snowflake"
        case .newYear: return "party.popper.fill"
        case .valentines: return "heart.fill"
        case .summer: return "sun.max.fill"
        case .backToSchool: return "backpack.fill"
        }
    }

    static func currentSeasonalThemes() -> [Theme] {
        let calendar = Calendar.current
        let month = calendar.component(.month, from: Date())

        var themes: [Theme] = [.evergreen]

        switch month {
        case 1:
            themes.append(.newYear)
        case 2:
            themes.append(.valentines)
        case 6...8:
            themes.append(.summer)
        case 9:
            themes.append(.backToSchool)
        case 10:
            themes.append(.halloween)
        case 11:
            themes.append(.thanksgiving)
        case 12:
            themes.append(.winterHolidays)
        default:
            break
        }

        return themes
    }
}
