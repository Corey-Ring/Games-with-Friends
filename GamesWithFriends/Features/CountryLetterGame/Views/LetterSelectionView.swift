import SwiftUI

struct LetterSelectionView: View {
    var viewModel: CountryGameViewModel

    let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 6)

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Header + the 26-tile grid fill the column; motifs keep to
                // the nav strip and the outer edges, ≥12pt clear of every
                // letter button (§7 — the generator adds the clearance).
                MotifGroundView(seed: 0xC1A5_0F02,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Header: spot plate + framed Lilita title (Rule 4 — the game
                // name is far past the ~8-char Shrikhand cap, §4).
                VStack(spacing: AppTheme.Spacing.sm) {
                    ZStack {
                        Circle().fill(AppTheme.Retro.panel)
                        Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                        RetroSpotIllustration(kind: .globe)
                            .frame(width: 64, height: 64)
                    }
                    .frame(width: 84, height: 84)

                    Text("Country Letter Challenge")
                        .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                        .foregroundColor(AppTheme.Retro.ink)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroPanel(CountryLetterStyle.accent)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                .fill(AppTheme.Retro.ink)
                                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
                        )
                        .rotationEffect(.degrees(-1))

                    Text("Select a letter to see how many countries you can name before tapping \"Done\".")
                        .font(AppTheme.Typography.secondary)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .multilineTextAlignment(.center)
                        .retroLozenge()
                        .rotationEffect(.degrees(0.8))
                }
                .padding(.top, AppTheme.Spacing.lg)

                LazyVGrid(columns: columns, spacing: AppTheme.Spacing.md) {
                    ForEach(Array(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ").enumerated()), id: \.element) { index, letter in
                        LetterButton(
                            letter: String(letter),
                            isEnabled: CountriesData.availableLetters.contains(String(letter))
                        ) {
                            HapticManager.selection()
                            viewModel.selectLetter(String(letter))
                        }
                        .staggeredAppear(index: index)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(AppTheme.Spacing.md)
        }
    }
}

struct LetterButton: View {
    let letter: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title3))
                .foregroundColor(isEnabled ? AppTheme.Retro.ink : AppTheme.Retro.panelText)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                // Disabled letters drop to a plain cream panel (§3 recipe).
                .retroPanel(isEnabled ? CountryLetterStyle.accent : AppTheme.Retro.panel,
                            cornerRadius: AppTheme.Retro.Radius.inner)
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
    }
}
