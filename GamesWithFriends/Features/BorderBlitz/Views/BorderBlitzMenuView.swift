//
//  BorderBlitzMenuView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzMenuView: View {
    @ObservedObject var viewModel: BorderBlitzViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 30) {
            // Title
            VStack(spacing: 10) {
                Text("Border Blitz")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.blue)

                Text("Identify countries by their borders!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)

            Spacer()

            // Game preview icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)

                Image(systemName: "map.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.white)
            }

            Spacer()

            // Difficulty selection
            VStack(alignment: .leading, spacing: 15) {
                Text("Select Difficulty")
                    .font(.headline)

                ForEach(BorderBlitzDifficulty.allCases) { difficulty in
                    BorderBlitzDifficultyButton(
                        difficulty: difficulty,
                        isSelected: viewModel.selectedDifficulty == difficulty
                    ) {
                        viewModel.selectedDifficulty = difficulty
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .padding(.horizontal)

            // Start button
            Button("Start Game") {
                viewModel.startGame()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .font(.title2)
            .padding(.bottom, 50)
        }
        .padding()
        .navigationBarBackButtonHidden(viewModel.gameStarted)
    }
}

struct BorderBlitzDifficultyButton: View {
    let difficulty: BorderBlitzDifficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(difficulty.rawValue)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(difficulty.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(UIColor.tertiarySystemBackground))
            )
        }
    }
}
