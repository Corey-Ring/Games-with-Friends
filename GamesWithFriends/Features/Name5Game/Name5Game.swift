import SwiftUI

struct Name5Game: GameDefinition {
    let id: String = "name-5-game"
    let name: String = "Name 5"
    let description: String = "Race against the clock to name 5 things!"
    let iconName: String = "hand.raised.fingers.spread.fill"
    let accentColor: Color = .blue

    func makeRootView() -> AnyView {
        AnyView(Name5GameView())
    }
}
