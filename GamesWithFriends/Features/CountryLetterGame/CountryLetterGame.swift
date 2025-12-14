import SwiftUI

struct CountryLetterGame: GameDefinition {
    let id: String = "country-letter-game"
    let name: String = "Country Letter Challenge"
    let description: String = "Pick a letter and guess all countries that start with it!"
    let iconName: String = "globe.americas.fill"
    let accentColor: Color = .blue

    func makeRootView() -> AnyView {
        AnyView(CountryLetterGameView())
    }
}
