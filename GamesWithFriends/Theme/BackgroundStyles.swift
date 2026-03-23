import SwiftUI

// Standard warm linen page background
struct WarmLinenBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        (colorScheme == .dark ? AppTheme.darkBackground : AppTheme.warmLinen)
            .ignoresSafeArea()
    }
}

// Per-game subtle tinted background (accent at 8% opacity)
struct GameBackground: View {
    let gameTheme: GameTheme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        (colorScheme == .dark
            ? gameTheme.accentColor.opacity(0.06)
            : gameTheme.lightBackground)
            .ignoresSafeArea()
    }
}
