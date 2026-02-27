import SwiftUI

struct GameHubView: View {
    let games = GameRegistry.allGames()

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {

                            Text("Games with Friends")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Building connections through games")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)

                        // Games Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(games) { game in
                                GameCard(game: game)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 30)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct GameCard: View {
    let game: AnyGameDefinition
    @State private var isPressed = false

    var body: some View {
        NavigationLink {
            game.makeRootView()
        } label: {
            VStack(spacing: 8) {
                Spacer()

                // Icon
                Image(systemName: game.iconName)
                    .font(.system(size: 36))
                    .foregroundColor(game.accentColor)
                    .frame(height: 44)

                // Title
                Text(game.name)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Description
                Text(game.description)
                    .font(.caption)
                    .foregroundColor(.primary.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)

                Spacer()
            }
            .frame(maxWidth: .infinity, minHeight: 160)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(game.accentColor.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    GameHubView()
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self], inMemory: true)
}

