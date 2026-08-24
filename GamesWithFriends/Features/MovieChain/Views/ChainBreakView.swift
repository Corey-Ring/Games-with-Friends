import SwiftUI

/// View shown when the chain is broken
struct ChainBreakView: View {
    @ObservedObject var viewModel: MovieChainViewModel
    let reason: ChainBreakReason
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bounceTrigger = false

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Interstitial screen: the message column owns the middle;
                // motifs live in the gutters (§7).
                MotifGroundView(seed: 0xF11_A0502,
                                exclusions: [CGRect(x: 16, y: 80,
                                                    width: geo.size.width - 32,
                                                    height: geo.size.height - 100)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                Spacer()

                // Chain break icon — spot plate, never a naked SF hero (§9).
                ZStack {
                    Circle().fill(AppTheme.Retro.panel)
                    Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(MovieChainStyle.accent)
                        .symbolEffect(.bounce, value: bounceTrigger)
                }
                .frame(width: 110, height: 110)

                // Message
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Chain Broken!")
                        .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                        .foregroundColor(AppTheme.Retro.ink)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroPanel(MovieChainStyle.accent)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                .fill(AppTheme.Retro.ink)
                                .offset(x: AppTheme.Retro.shadowOffset,
                                        y: AppTheme.Retro.shadowOffset)
                        )
                        .rotationEffect(.degrees(-1))

                    Text(reason.message)
                        .font(AppTheme.Typography.secondary)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .multilineTextAlignment(.center)
                        .retroLozenge()
                        .rotationEffect(.degrees(0.8))
                }
                .padding(.horizontal)

                // Player who broke the chain
                HStack(spacing: AppTheme.Spacing.md) {
                    Circle()
                        .fill(viewModel.currentPlayer.color)
                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                        .frame(width: 20, height: 20)

                    Text(viewModel.currentPlayer.name)
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)

                    if viewModel.gameMode.hasLives {
                        Text("lost a life")
                            .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))

                        HStack(spacing: 2) {
                            ForEach(0..<viewModel.gameMode.defaultLives, id: \.self) { index in
                                Image(systemName: index < viewModel.currentPlayer.lives ? "heart.fill" : "heart")
                                    .foregroundStyle(MovieChainStyle.lives)
                                    .font(AppTheme.Typography.caption)
                            }
                        }
                    }
                }
                .retroCard()
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
                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

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
        .retroCard()
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Check if game should end (only 1 player left in classic mode)
            if viewModel.gameMode == .classic && viewModel.activePlayers.count <= 1 {
                RetroPrimaryButton(title: "See Results", icon: "flag.checkered",
                                   accent: MovieChainStyle.accent) {
                    viewModel.endGame()
                }
            } else {
                // Continue with new chain
                RetroPrimaryButton(title: "Start New Chain", icon: "arrow.clockwise",
                                   accent: MovieChainStyle.accent) {
                    viewModel.startNewChain()
                }

                // Timed and Endless have no elimination end-state, so they need
                // an explicit exit — without it the standings screen is unreachable.
                if viewModel.gameMode != .classic {
                    RetroPrimaryButton(title: "End Game", icon: "flag.checkered",
                                       accent: AppTheme.Retro.panel) {
                        viewModel.endGame()
                    }
                }
            }

            RetroPrimaryButton(title: "Quit to Menu", icon: "house",
                               accent: AppTheme.Retro.panel) {
                viewModel.returnToSetup()
            }
        }
    }
}

// MARK: - Mini Chain Link View

struct MiniChainLinkView: View {
    let link: ChainLink

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            ChainNodeDisc(
                systemImage: link.isMovie ? "film" : "person.fill",
                color: link.isMovie ? MovieChainStyle.movieNode : MovieChainStyle.actorNode,
                diameter: 36
            )

            Text(shortName)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                .lineLimit(1)
                .frame(width: 60)
        }
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
                .foregroundStyle(MovieChainStyle.accent)

            Text(value)
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
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
