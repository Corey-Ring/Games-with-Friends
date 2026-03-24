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

                        Text("Navigate from country to country!")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.mediumGray)
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    // Hero icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [theme.accentColor, theme.accentColor.opacity(0.6)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 150, height: 150)

                        Image(systemName: theme.iconName)
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, AppTheme.Spacing.lg)

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
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
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

                    Text("Benchmark: \(Int(difficulty.benchmarkTime))s")
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
