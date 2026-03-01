import SwiftUI

struct GameHubView: View {
    let games = GameRegistry.allGames()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    // Header
                    VStack(spacing: 4) {
                        Text("Games with Friends")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        Text("Building connections through games")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    // Games Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 10),
                        GridItem(.flexible(), spacing: 10)
                    ], spacing: 10) {
                        ForEach(games) { game in
                            GameCard(game: game)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .scrollIndicators(.hidden)
            .background {
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct GameCard: View {
    let game: AnyGameDefinition

    var body: some View {
        NavigationLink {
            game.makeRootView()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: game.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(game.accentColor)

                Text(game.name)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(GameCardButtonStyle())
    }
}

struct GameCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    GameHubView()
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self], inMemory: true)
}

