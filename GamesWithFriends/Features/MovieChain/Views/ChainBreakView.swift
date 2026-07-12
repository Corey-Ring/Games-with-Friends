import SwiftUI

/// View shown when the chain is broken
struct ChainBreakView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    let reason: ChainBreakReason
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounceTrigger = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            Spacer()

            // Chain break icon
            ZStack {
                Circle()
                    .fill(GameTheme.movieChain.accentColor.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "link.badge.plus")
                    .font(.system(size: 50))
                    .foregroundStyle(GameTheme.movieChain.accentColor)
                    .symbolEffect(.bounce, value: bounceTrigger)
            }

            // Message
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Chain Broken!")
                    .font(AppTheme.Typography.hero)
                    .foregroundColor(.primary)

                Text(reason.message)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

            // Player who broke the chain
            HStack(spacing: AppTheme.Spacing.md) {
                Circle()
                    .fill(viewModel.currentPlayer.color)
                    .frame(width: 20, height: 20)

                Text(viewModel.currentPlayer.name)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(.primary)

                if viewModel.gameMode.hasLives {
                    Text("lost a life")
                        .foregroundColor(.secondary)

                    HStack(spacing: 2) {
                        ForEach(0..<viewModel.gameMode.defaultLives, id: \.self) { index in
                            Image(systemName: index < viewModel.currentPlayer.lives ? "heart.fill" : "heart")
                                .foregroundStyle(AppTheme.error)
                                .font(AppTheme.Typography.caption)
                        }
                    }
                }
            }
            .gameCard()
            .padding(.horizontal)

            // Chain stats
            chainStatsSection
                .padding(.horizontal)

            Spacer()

            // Action buttons
            actionButtons
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.lg)
        }
        .onAppear {
            // Respect Reduce Motion — only bounce the icon when motion is allowed.
            if !reduceMotion {
                bounceTrigger.toggle()
            }
        }
    }

    // MARK: - Chain Stats Section

    private var chainStatsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Chain Length: \(viewModel.chain.count)")
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(.primary)

            if viewModel.chain.count > 1 {
                // Show the chain that was built
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        ForEach(viewModel.chain) { link in
                            MiniChainLinkView(link: link)
                        }
                    }
                    .padding(.horizontal)
                }
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                MovieChainStatBox(
                    title: "Longest Chain",
                    value: "\(viewModel.longestChainThisGame)",
                    icon: "link"
                )

                MovieChainStatBox(
                    title: "Chains Completed",
                    value: "\(viewModel.totalChainsCompleted)",
                    icon: "arrow.triangle.2.circlepath"
                )
            }
        }
        .gameCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Check if game should end (only 1 player left in classic mode)
            if viewModel.gameMode == .classic && viewModel.activePlayers.count <= 1 {
                PrimaryButton(title: "See Results", icon: "flag.checkered") {
                    viewModel.endGame()
                }
            } else {
                // Continue with new chain
                PrimaryButton(title: "Start New Chain", icon: "arrow.clockwise") {
                    viewModel.startNewChain()
                }

                // Timed and Endless have no elimination end-state, so they need
                // an explicit exit — without it the standings screen is unreachable.
                if viewModel.gameMode != .classic {
                    SecondaryButton(title: "End Game", icon: "flag.checkered") {
                        viewModel.endGame()
                    }
                }
            }

            SecondaryButton(title: "Quit to Menu", icon: "house") {
                viewModel.returnToSetup()
            }
        }
    }
}

// MARK: - Mini Chain Link View

struct MiniChainLinkView: View {
    let link: ChainLink
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ZStack {
                Circle()
                    .fill(link.isMovie ? GameTheme.movieChain.accentColor : actorCircleColor)
                    .frame(width: 36, height: 36)

                Image(systemName: link.isMovie ? "film" : "person.fill")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.white)
            }

            Text(shortName)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 60)
        }
    }

    // deepCharcoal reads as an invisible circle on the dark card surface;
    // lift it to darkElevated in dark mode so the actor node stays legible.
    private var actorCircleColor: Color {
        colorScheme == .dark ? AppTheme.darkElevated : AppTheme.deepCharcoal
    }

    private var shortName: String {
        let name = link.displayName
        if name.count > 10 {
            return String(name.prefix(8)) + "..."
        }
        return name
    }
}

// MARK: - Stat Box

struct MovieChainStatBox: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundStyle(GameTheme.movieChain.accentColor)

            Text(value)
                .font(AppTheme.Typography.sectionHeader)
                .foregroundColor(.primary)

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ChainBreakView(
        viewModel: MovieChainViewModel(),
        reason: .invalidAnswer(submitted: "Tom Hanks", expected: "The Matrix")
    )
}
