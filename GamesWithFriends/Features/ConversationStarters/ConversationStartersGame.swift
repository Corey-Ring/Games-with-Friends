import SwiftUI

struct ConversationStartersGame: GameDefinition {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let accentColor: Color

    func makeRootView() -> AnyView {
        AnyView(HomeView())
    }
}
