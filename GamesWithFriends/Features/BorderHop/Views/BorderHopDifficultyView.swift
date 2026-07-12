import SwiftUI

struct BorderHopDifficultyView: View {
    var viewModel: BorderHopViewModel
    @Environment(\.dismiss) private var dismiss
    private let theme = GameTheme.borderHop

    var body: some View {
        ZStack {
            GameBackground(gameTheme: theme)

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Title
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("Border Hop")
                            .font(AppTheme.Typography.hero)
                            .foregroundColor(AppTheme.deepCharcoal)

                        Text("Cross the world one land border at a time")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.mediumGray)
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    // How it works — a first-time player should get the whole game
                    // from this one card
                    howItWorksCard
                        .padding(.horizontal, AppTheme.Spacing.md)

                    // Difficulty selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Select Difficulty")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.deepCharcoal)

                        ForEach(Array(BorderHopDifficulty.allCases.enumerated()), id: \.element.id) { index, difficulty in
                            BorderHopDifficultyButton(
                                difficulty: difficulty,
                                isSelected: viewModel.selectedDifficulty == difficulty,
                                accentColor: theme.accentColor
                            ) {
                                viewModel.selectDifficulty(difficulty)
                            }
                            .staggeredAppear(index: index)
                        }
                    }
                    .gameCard()
                    .padding(.horizontal, AppTheme.Spacing.md)

                    // Start button
                    PrimaryButton(title: "Start Game", icon: "play.fill") {
                        viewModel.startGame()
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, viewModel.routeGenerationFailed ? AppTheme.Spacing.xs : AppTheme.Spacing.lg)

                    if viewModel.routeGenerationFailed {
                        Text("Couldn't build a route for this difficulty — tap Start Game to try again.")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(AppTheme.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.bottom, AppTheme.Spacing.lg)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
    }

    // MARK: - How It Works

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            howItWorksRow(
                step: 1,
                icon: "mappin.and.ellipse",
                iconColor: theme.accentColor,
                text: "You're dropped in a country with a faraway destination"
            )
            howItWorksRow(
                step: 2,
                icon: "hand.tap.fill",
                iconColor: theme.accentColor,
                text: "Tap a neighbor to hop — answer one quick geography question to cross"
            )
            howItWorksRow(
                step: 3,
                icon: "flag.checkered",
                iconColor: AppTheme.medalGold,
                text: "Reach the destination in as few hops as you can"
            )
        }
        .gameCard()
    }

    private func howItWorksRow(step: Int, icon: String, iconColor: Color, text: String) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            Text(text)
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.deepCharcoal)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .staggeredAppear(index: step - 1)
    }
}

struct BorderHopDifficultyButton: View {
    let difficulty: BorderHopDifficulty
    let isSelected: Bool
    var accentColor: Color = AppTheme.compassRose
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(difficulty.subtitle)
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(isSelected ? .white : AppTheme.deepCharcoal)

                        Text(difficulty.displayName)
                            .font(AppTheme.Typography.pillLabel)
                            .foregroundColor(isSelected ? .white.opacity(0.9) : difficulty.badgeColor)
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color.white.opacity(0.2) : difficulty.badgeColor.opacity(0.15))
                            )
                    }

                    Text(difficulty.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : AppTheme.mediumGray)

                    Text("Route: \(difficulty.minHops)+ borders")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.7) : AppTheme.mediumGray.opacity(0.7))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSelected ? accentColor : accentColor.opacity(0.08))
            )
        }
        .pressable()
    }
}
