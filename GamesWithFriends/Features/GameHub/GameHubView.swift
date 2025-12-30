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
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 5) {
                            
                            Text("Games with Friends")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Building connections through games")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 40)
                        
                        // Games Grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 20),
                            GridItem(.flexible(), spacing: 20)
                        ], spacing: 20) {
                            ForEach(games) { game in
                                GameCard(game: game)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 30)
                    }
                }
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
            VStack(spacing: 12) {
                // Icon
                Image(systemName: game.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(game.accentColor)
                    .frame(height: 50)

                // Title
                Text(game.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Description
                Text(game.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .padding()
            .background(Color.white)
            .cornerRadius(15)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
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

