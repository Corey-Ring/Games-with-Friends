import SwiftUI

struct GameHubView: View {
    let games = GameRegistry.allGames()

    var body: some View {
        NavigationStack {
            ZStack {
                WarmLinenBackground()

                ScrollView {
                    VStack(spacing: 0) {
                        // Header
                        Text("Games")
                            .font(AppTheme.Typography.hero)
                            .foregroundColor(AppTheme.deepCharcoal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, AppTheme.Spacing.xxl)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.bottom, AppTheme.Spacing.lg)

                        // Game cards
                        VStack(spacing: AppTheme.Spacing.md) {
                            ForEach(Array(games.enumerated()), id: \.element.id) { index, game in
                                NavigationLink(destination: game.makeRootView()) {
                                    HubGameCard(game: game)
                                }
                                .pressable()
                                .staggeredAppear(index: index)
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.xl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

struct HubGameCard: View {
    let game: AnyGameDefinition

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Left side: text content
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(game.name)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.deepCharcoal)
                    .lineLimit(1)

                Text(game.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.mediumGray)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right side: icon in accent circle
            ZStack {
                Circle()
                    .fill(game.accentColor.opacity(0.12))
                    .frame(width: 56, height: 56)

                Image(systemName: game.iconName)
                    .font(.title2)
                    .foregroundColor(game.accentColor)
            }
        }
        .gameCard()
    }
}

#Preview {
    GameHubView()
        .modelContainer(for: [RoadTrip.self, SpottedPlate.self], inMemory: true)
}
