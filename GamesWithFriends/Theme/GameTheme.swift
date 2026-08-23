import SwiftUI

struct GameTheme {
    let accentColor: Color
    let name: String
    let iconName: String

    // Computed convenience colors
    var lightBackground: Color { accentColor.opacity(0.08) }
    var mediumBackground: Color { accentColor.opacity(0.15) }
    var darkAccent: Color { accentColor.opacity(0.85) }

    // MARK: - Pre-built Themes
    // Retro-migrated (phase 4): candy accent per ART_DIRECTION §3.2.
    // Remaining games keep their muted accents until their migration lands.
    static let conversationStarters = GameTheme(accentColor: AppTheme.Retro.bubblegum, name: "Conversation Starters", iconName: "bubble.left.and.bubble.right.fill")
    static let countryLetter = GameTheme(accentColor: AppTheme.Retro.grass, name: "Country Letter Challenge", iconName: "globe.americas.fill")
    static let name5 = GameTheme(accentColor: AppTheme.Retro.lilac, name: "Name 5", iconName: "hand.raised.fingers.spread.fill")
    static let borderBlitz = GameTheme(accentColor: AppTheme.tealGreen, name: "Border Blitz", iconName: "map.fill")
    static let movieChain = GameTheme(accentColor: AppTheme.Retro.tomato, name: "Movie Chain", iconName: "film.stack")
    static let castingDirector = GameTheme(accentColor: AppTheme.brandOrange, name: "Casting Director", iconName: "person.crop.rectangle.stack")
    static let vibeCheck = GameTheme(accentColor: AppTheme.coralRed, name: "Vibe Check", iconName: "antenna.radiowaves.left.and.right")
    static let borderHop = GameTheme(accentColor: AppTheme.compassRose, name: "Border Hop", iconName: "globe.europe.africa.fill")
    static let finishTheLine = GameTheme(accentColor: AppTheme.spotlightPlum, name: "Finish the Line", iconName: "quote.bubble.fill")
}
