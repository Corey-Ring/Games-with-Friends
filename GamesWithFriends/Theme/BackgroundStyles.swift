import SwiftUI

// Standard warm linen page background
struct WarmLinenBackground: View {
    var body: some View {
        AppTheme.warmLinen
            .ignoresSafeArea()
    }
}

// Per-game subtle tinted background (accent at 8% opacity)
struct GameBackground: View {
    let gameTheme: GameTheme

    var body: some View {
        gameTheme.lightBackground
            .ignoresSafeArea()
    }
}
