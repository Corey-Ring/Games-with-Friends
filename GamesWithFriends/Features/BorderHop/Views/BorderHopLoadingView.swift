import SwiftUI

struct BorderHopLoadingView: View {
    var viewModel: BorderHopViewModel
    private let theme = GameTheme.borderHop
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            GameBackground(gameTheme: theme)

            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                // Start country
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(theme.accentColor)

                    Text("START")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.mediumGray)

                    Text(viewModel.startCountry?.name ?? "")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundColor(AppTheme.deepCharcoal)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Arrow
                Image(systemName: "arrow.down")
                    .font(.system(size: 32))
                    .foregroundColor(theme.accentColor.opacity(0.5))
                    .opacity(showContent ? 1 : 0)

                // Destination country
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "flag.checkered")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.medalGold)

                    Text("DESTINATION")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.mediumGray)

                    Text(viewModel.destinationCountry?.name ?? "")
                        .font(AppTheme.Typography.sectionHeader)
                        .foregroundColor(AppTheme.deepCharcoal)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Optimal hops hint
                Text("Optimal route: \(viewModel.optimalHopCount) hops")
                    .font(AppTheme.Typography.detail)
                    .foregroundColor(AppTheme.mediumGray)
                    .opacity(showContent ? 1 : 0)

                Spacer()

                // Go button
                PrimaryButton(title: "Go!", icon: "arrow.right") {
                    viewModel.beginPlaying()
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xl)
                .opacity(showContent ? 1 : 0)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .onAppear {
            HapticManager.medium()
            withAnimation(reduceMotion ? .none : .easeOut(duration: 0.6).delay(0.3)) {
                showContent = true
            }
        }
    }
}
