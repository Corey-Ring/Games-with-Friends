import SwiftUI

/// Movie Chain game definition for the Games With Friends app
struct MovieChainGame: GameDefinition {
    let id = "movie-chain"
    let name = "Movie Chain"
    let description = "Connect movies through their actors"
    let iconName = "film.stack"
    let accentColor = AppTheme.warmGold

    func makeRootView() -> AnyView {
        AnyView(MovieChainRootView())
    }
}
