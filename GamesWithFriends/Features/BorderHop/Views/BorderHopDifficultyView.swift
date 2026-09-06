import SwiftUI

struct BorderHopDifficultyView: View {
    var viewModel: BorderHopViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The setup column (how-it-works card, difficulty rows, CTA)
                // runs inset 24pt; motifs keep to the nav strip and the outer
                // gutters, ≥12pt clear of every control (§7 — the generator
                // adds the clearance).
                MotifGroundView(seed: 0xB0B5_0E01,
                                exclusions: [CGRect(x: 24, y: 56,
                                                    width: geo.size.width - 48,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header: hop-map spot plate + framed Lilita title. The
                    // naked hero type on the linen field is a retirement (§9).
                    VStack(spacing: AppTheme.Spacing.sm) {
                        BorderHopSpotPlate()

                        BorderHopTitlePanel(text: "Border Hop")

                        Text("Cross the world one land border at a time")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .multilineTextAlignment(.center)
                            .retroLozenge()
                            .rotationEffect(.degrees(0.8))
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    // How it works — a first-time player should get the whole game
                    // from this one card
                    howItWorksCard
                        .padding(.horizontal, AppTheme.Spacing.md)

                    // Difficulty selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Select Difficulty")
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .retroLozenge()

                        ForEach(Array(BorderHopDifficulty.allCases.enumerated()), id: \.element.id) { index, difficulty in
                            BorderHopDifficultyButton(
                                difficulty: difficulty,
                                isSelected: viewModel.selectedDifficulty == difficulty,
                                accentColor: BorderHopStyle.accent
                            ) {
                                viewModel.selectDifficulty(difficulty)
                            }
                            .staggeredAppear(index: index)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Spacing.md)

                    // Start button
                    RetroPrimaryButton(title: "Start Game", icon: "play.fill",
                                       accent: BorderHopStyle.accent) {
                        viewModel.startGame()
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, viewModel.routeGenerationFailed ? AppTheme.Spacing.xs : AppTheme.Spacing.lg)

                    if viewModel.routeGenerationFailed {
                        // §8: the failure line lives in a cream lozenge rather
                        // than floating tomato-on-mustard.
                        Text("Couldn't build a route for this difficulty — tap Start Game to try again.")
                            .font(AppTheme.Typography.caption)
                            .foregroundStyle(BorderHopStyle.wrongColor)
                            .multilineTextAlignment(.center)
                            .retroLozenge()
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
                iconColor: BorderHopStyle.accent,
                text: "You're dropped in a country with a faraway destination"
            )
            howItWorksRow(
                step: 2,
                icon: "hand.tap.fill",
                iconColor: BorderHopStyle.accent,
                text: "Tap a neighbor to hop — answer one quick geography question to cross"
            )
            howItWorksRow(
                step: 3,
                icon: "flag.checkered",
                iconColor: BorderHopStyle.goalColor,
                text: "Reach the destination in as few hops as you can"
            )
        }
        .retroCard()
    }

    private func howItWorksRow(step: Int, icon: String, iconColor: Color, text: String) -> some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.md) {
            // Flat candy plate with an ink rule and an ink glyph — the old
            // 12%-opacity tint circle is a retirement (§9).
            BorderHopGlyphPlate(systemImage: icon, fill: iconColor)

            Text(text)
                .font(AppTheme.Typography.secondary)
                .foregroundColor(AppTheme.Retro.panelText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .staggeredAppear(index: step - 1)
    }
}

struct BorderHopDifficultyButton: View {
    let difficulty: BorderHopDifficulty
    let isSelected: Bool
    var accentColor: Color = BorderHopStyle.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Text(difficulty.subtitle)
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(rowTextColor)

                        // Semantic ramp chip: allowed inside the row because the
                        // row itself is the game accent or plain cream (§3 recipe).
                        Text(difficulty.displayName)
                            .font(AppTheme.Retro.Typography.pillLabel)
                            .foregroundColor(BorderHopStyle.chipTextColor(on: badgeColor))
                            .padding(.horizontal, AppTheme.Spacing.sm)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(badgeColor))
                            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 2))
                    }

                    Text(difficulty.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(rowTextColor)

                    Text("Route: \(difficulty.minHops)+ borders")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(rowTextColor.opacity(0.75))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(rowTextColor)
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .retroPanel(isSelected ? accentColor : AppTheme.Retro.panel)
        }
        .buttonStyle(RetroRaisedButtonStyle())
    }

    /// §8: ink on cornflower passes; the unselected row is plain ink-on-cream,
    /// so the copy is safe either way.
    private var rowTextColor: Color {
        isSelected ? BorderHopStyle.chipTextColor(on: accentColor) : AppTheme.Retro.panelText
    }

    private var badgeColor: Color {
        BorderHopStyle.difficultyColor(difficulty)
    }
}
