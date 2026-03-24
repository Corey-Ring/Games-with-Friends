import SwiftUI

struct BorderHopGameView: View {
    var viewModel: BorderHopViewModel
    private let theme = GameTheme.borderHop
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            // Layer 0: Map
            BorderHopMapView(viewModel: viewModel)
                .ignoresSafeArea()

            // Layer 1: Top HUD
            topHUD
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, AppTheme.Spacing.sm)

            // Layer 2: Bottom destination bar
            VStack {
                Spacer()
                destinationBar
            }

            // Backtrack confirmation banner
            if viewModel.showBacktrackConfirm, let targetId = viewModel.backtrackTargetId {
                backtrackBanner(targetId: targetId)
            }

            // Victory overlay
            if viewModel.hasArrived {
                victoryOverlay
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Close button
            Button {
                viewModel.quitGame()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Streak badge (when > 1)
            if viewModel.currentStreak > 1 {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text(verbatim: "\(viewModel.currentStreak)")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(.orange)
                        .monospacedDigit()
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, AppTheme.Spacing.xs)
                .background(Capsule().fill(Color.orange.opacity(0.15)))
            }

            // Stopwatch
            StopwatchView(elapsed: viewModel.elapsedTime, color: viewModel.stopwatchColor)

            Spacer()

            // Hop counter
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "figure.walk")
                    .foregroundColor(.white)
                Text(verbatim: "\(viewModel.hopCount)")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Capsule().fill(.ultraThinMaterial))
        }
    }

    // MARK: - Bottom Bar

    private var destinationBar: some View {
        HStack {
            Image(systemName: "flag.checkered")
                .foregroundColor(AppTheme.medalGold)

            Text("Destination: \(viewModel.destinationCountry?.name ?? "")")
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Text("\(viewModel.hopCount) hops")
                .font(AppTheme.Typography.detail)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(AppTheme.Spacing.md)
        .background(.ultraThinMaterial)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - Backtrack Banner

    private func backtrackBanner(targetId: String) -> some View {
        VStack {
            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Backtrack to \(viewModel.graph.country(for: targetId)?.name ?? "")?")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(.white)
                    Text("+5 second penalty")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.error)
                }

                Spacer()

                Button("Cancel") {
                    viewModel.cancelBacktrack()
                }
                .font(AppTheme.Typography.pillLabel)
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Capsule().fill(.white.opacity(0.15)))

                Button("Confirm") {
                    viewModel.confirmBacktrack()
                }
                .font(AppTheme.Typography.pillLabel)
                .foregroundColor(.white)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background(Capsule().fill(theme.accentColor))
            }
            .padding(AppTheme.Spacing.md)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.top, 60) // Below HUD

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showBacktrackConfirm)
    }

    // MARK: - Victory Overlay

    private var victoryOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "flag.checkered.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.medalGold)
                    .symbolEffect(.bounce, value: viewModel.hasArrived)

                Text("Route Complete!")
                    .font(AppTheme.Typography.hero)
                    .foregroundColor(.white)

                if let result = viewModel.roundResult {
                    Text("Score: \(result.totalScoreInt)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(theme.accentColor)
                }
            }
        }
        .transition(.opacity)
        .animation(.easeIn(duration: 0.3), value: viewModel.hasArrived)
    }
}
