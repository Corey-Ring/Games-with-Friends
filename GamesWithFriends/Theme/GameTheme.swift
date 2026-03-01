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
    static let licensePlate = GameTheme(accentColor: AppTheme.skyBlue, name: "License Plate Game", iconName: "car.fill")
    static let conversationStarters = GameTheme(accentColor: AppTheme.softMauve, name: "Conversation Starters", iconName: "bubble.left.and.bubble.right.fill")
    static let countryLetter = GameTheme(accentColor: AppTheme.forestGreen, name: "Country Letter Challenge", iconName: "globe.americas.fill")
    static let name5 = GameTheme(accentColor: AppTheme.electricIndigo, name: "Name 5", iconName: "hand.raised.fingers.spread.fill")
    static let borderBlitz = GameTheme(accentColor: AppTheme.tealGreen, name: "Border Blitz", iconName: "map.fill")
    static let movieChain = GameTheme(accentColor: AppTheme.warmGold, name: "Movie Chain", iconName: "film.stack")
    static let castingDirector = GameTheme(accentColor: AppTheme.brandOrange, name: "Casting Director", iconName: "person.crop.rectangle.stack")
    static let vibeCheck = GameTheme(accentColor: AppTheme.coralRed, name: "Vibe Check", iconName: "antenna.radiowaves.left.and.right")
}
