import SwiftUI

/// Central registry for all available games
struct GameRegistry {
    /// Returns all available games in the app
    static func allGames() -> [AnyGameDefinition] {
        return [
            AnyGameDefinition(LicensePlateGame()),
            AnyGameDefinition(ConversationStartersGame(
                id: "conversation-starters",
                name: "Conversation Starters",
                description: "Break the ice and spark great conversations",
                iconName: "bubble.left.and.bubble.right.fill",
                accentColor: .purple
            )),
            AnyGameDefinition(CountryLetterGame()),
            AnyGameDefinition(Name5Game())
        ]
    }
}

