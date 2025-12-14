import SwiftUI

struct LetterSelectionView: View {
    @ObservedObject var viewModel: CountryGameViewModel

    let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Country Letter Challenge")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Select a letter to see how many countries you can name before tapping \"Done\".")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 20)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"), id: \.self) { letter in
                    LetterButton(
                        letter: String(letter),
                        isEnabled: CountriesData.availableLetters.contains(String(letter))
                    ) {
                        viewModel.selectLetter(String(letter))
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

struct LetterButton: View {
    let letter: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(letter)
                .font(.system(size: 20, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isEnabled ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                )
                .foregroundColor(isEnabled ? .primary : .gray)
        }
        .disabled(!isEnabled)
    }
}
