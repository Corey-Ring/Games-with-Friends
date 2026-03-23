import SwiftUI

struct VibeCheckGame: GameDefinition {
    let id = "vibecheck"
    let name = "Vibe Check"
    let description = "Get on the same wavelength"
    let iconName = "antenna.radiowaves.left.and.right"
    let accentColor: Color = GameTheme.vibeCheck.accentColor

    func makeRootView() -> AnyView {
        AnyView(VibeCheckRootView())
    }
}
