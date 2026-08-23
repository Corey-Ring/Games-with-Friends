import SwiftUI

struct BorderHopLoadingView: View {
    var viewModel: BorderHopViewModel
    @State private var showContent = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Route briefing: the start/destination column runs inset 24pt,
                // motifs keep to the gutters and the nav strip (§7).
                MotifGroundView(seed: 0xB0B5_0E02,
                                exclusions: [CGRect(x: 24, y: 56,
                                                    width: geo.size.width - 48,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                // Start country
                VStack(spacing: AppTheme.Spacing.sm) {
                    BorderHopGlyphPlate(systemImage: "mappin.and.ellipse",
                                        fill: BorderHopStyle.accent,
                                        diameter: 64,
                                        glyphSize: 28)

                    Text("START")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .tracking(2)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .retroLozenge()

                    Text(viewModel.startCountry?.name ?? "")
                        .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                        .foregroundColor(AppTheme.Retro.panelText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroPanel()
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Arrow — ink linework, no accent wash (§9)
                Image(systemName: "arrow.down")
                    .font(.system(size: 32, weight: .black))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .opacity(showContent ? 1 : 0)

                // Destination country
                VStack(spacing: AppTheme.Spacing.sm) {
                    BorderHopGlyphPlate(systemImage: "flag.checkered",
                                        fill: BorderHopStyle.goalColor,
                                        diameter: 64,
                                        glyphSize: 28)

                    Text("DESTINATION")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .tracking(2)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .retroLozenge()

                    Text(viewModel.destinationCountry?.name ?? "")
                        .font(AppTheme.Retro.Typography.heading(24, relativeTo: .title))
                        .foregroundColor(AppTheme.Retro.panelText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroPanel()
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // Target framing: the number to beat
                Text("Shortest route: \(viewModel.optimalHopCount) border crossings")
                    .font(AppTheme.Typography.detail)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .retroLozenge()
                    .opacity(showContent ? 1 : 0)

                // The verb of the game, right before the map appears
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(AppTheme.Retro.panelText)
                    Text("Tap a highlighted neighbor to hop. Answer one quick question to cross each border.")
                        .font(AppTheme.Typography.secondary)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .retroCard()
                .padding(.horizontal, AppTheme.Spacing.md)
                .opacity(showContent ? 1 : 0)

                Spacer()

                // Go button
                RetroPrimaryButton(title: "Go!", icon: "arrow.right",
                                   accent: BorderHopStyle.accent) {
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
