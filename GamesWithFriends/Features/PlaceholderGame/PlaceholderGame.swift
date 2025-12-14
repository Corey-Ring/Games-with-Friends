import SwiftUI

// A simple placeholder game for testing
struct PlaceholderGame: GameDefinition {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let accentColor: Color

    func makeRootView() -> AnyView {
        AnyView(PlaceholderGameView(gameName: name))
    }
}

// The actual view for the placeholder game
struct PlaceholderGameView: View {
    let gameName: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary)

                Text(gameName)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("This game is coming soon!")
                    .foregroundStyle(.secondary)

                Button("Back to Games") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 40)
            }
            .navigationTitle(gameName)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Preview for Xcode canvas
#Preview {
    PlaceholderGameView(gameName: "Test Game")
}
