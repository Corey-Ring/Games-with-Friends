import SwiftUI

struct LetterSelectionView: View {
    var viewModel: CountryGameViewModel

    let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.sm), count: 6)

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Country Letter Challenge")
                    .font(AppTheme.Typography.hero)
                    .foregroundColor(AppTheme.deepCharcoal)

                Text("Select a letter to see how many countries you can name before tapping \"Done\".")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.mediumGray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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

struct LetterButton: View {
    let letter: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(AppTheme.Typography.sectionHeader)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                        .fill(isEnabled ? GameTheme.countryLetter.lightBackground : AppTheme.mediumGray.opacity(0.1))
                )
                .foregroundColor(isEnabled ? AppTheme.deepCharcoal : AppTheme.mediumGray)
        }
        .disabled(!isEnabled)
        .pressable()
    }
}
