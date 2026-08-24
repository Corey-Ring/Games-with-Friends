import SwiftUI

/// A player in the Movie Chain game
struct MovieChainPlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    let color: Color
    var lives: Int
    var score: Int
    var linksContributed: Int

    init(id: UUID = UUID(), name: String, color: Color, lives: Int = 3) {
        self.id = id
        self.name = name
        self.color = color
        self.lives = lives
        self.score = 0
        self.linksContributed = 0
    }

    var isEliminated: Bool {
        lives <= 0
    }
}

/// Default player colors
extension MovieChainPlayer {
    // Candy identity ramp (retro §3.2), excluding the game's tomato accent and
    // the cornflower reserved for actor nodes in the chain.
    static let defaultColors: [Color] = [
        AppTheme.Retro.bubblegum,
        AppTheme.Retro.poolBlue,
        AppTheme.Retro.grass,
        AppTheme.Retro.mustard,
        AppTheme.Retro.lilac,
        AppTheme.Retro.berry,
        AppTheme.Retro.plum,
        AppTheme.Retro.tangerine
    ]

    static func defaultName(for index: Int) -> String {
        "Player \(index + 1)"
    }

    static func createPlayers(count: Int, lives: Int = 3) -> [MovieChainPlayer] {
        (0..<count).map { index in
            MovieChainPlayer(
                name: defaultName(for: index),
                color: defaultColors[index % defaultColors.count],
                lives: lives
            )
        }
    }
}
