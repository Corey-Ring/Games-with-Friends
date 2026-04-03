//
//  BorderBlitzMenuView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzMenuView: View {
    var viewModel: BorderBlitzViewModel
    @Environment(\.dismiss) private var dismiss
    private let theme = GameTheme.borderBlitz

    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Spacing.lg) {
                // Title
                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Border Blitz")
                        .font(AppTheme.Typography.hero)
                        .foregroundColor(AppTheme.deepCharcoal)

                    Text("Identify countries by their borders!")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.mediumGray)
                }
                .padding(.top, AppTheme.Spacing.lg)

                // Game preview icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)

                    Image(systemName: theme.iconName)
                        .font(.system(size: 70))
                        .foregroundColor(.white)
                }
                .padding(.vertical, AppTheme.Spacing.lg)

                // Difficulty selection
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    Text("Select Difficulty")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(AppTheme.deepCharcoal)

                    ForEach(BorderBlitzDifficulty.allCases) { difficulty in
                        BorderBlitzDifficultyButton(
                            difficulty: difficulty,
                            isSelected: viewModel.selectedDifficulty == difficulty,
                            accentColor: theme.accentColor
                        ) {
                            viewModel.selectedDifficulty = difficulty
                        }
                    }
                }
                .gameCard()
                .padding(.horizontal, AppTheme.Spacing.md)

                // Permission status
                switch viewModel.speechManager.permissionStatus {
                case .notDetermined:
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(theme.accentColor)
                        Text("Microphone Required")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.deepCharcoal)
                        Text("Border Blitz uses your voice to detect country guesses. Tap below to enable microphone and speech recognition.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.mediumGray)
                            .multilineTextAlignment(.center)
                        PrimaryButton(title: "Enable Microphone", icon: "mic.fill") {
                            Task { await viewModel.speechManager.requestPermissions() }
                        }
                    }
                    .gameCard()
                    .padding(.horizontal, AppTheme.Spacing.md)

                case .authorized:
                    EmptyView()

                case .denied:
                    VStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "mic.slash.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.error)
                        Text("Microphone Access Denied")
                            .font(AppTheme.Typography.cardTitle)
                            .foregroundColor(AppTheme.deepCharcoal)
                        Text("Border Blitz needs microphone and speech recognition access to work. Please enable them in Settings.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.mediumGray)
                            .multilineTextAlignment(.center)
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            Link("Open Settings", destination: settingsURL)
                                .font(AppTheme.Typography.buttonLabel)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                    .gameCard()
                    .padding(.horizontal, AppTheme.Spacing.md)
                }

                // Start button
                PrimaryButton(title: "Start Game", icon: "play.fill") {
                    viewModel.startGame()
                }
                .disabled(viewModel.speechManager.permissionStatus == .denied)
                .opacity(viewModel.speechManager.permissionStatus == .denied ? 0.5 : 1.0)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.lg)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .navigationBarBackButtonHidden(viewModel.gameStarted)
        .onAppear {
            viewModel.speechManager.checkPermissionStatus()
        }
    }
}

struct BorderBlitzDifficultyButton: View {
    let difficulty: BorderBlitzDifficulty
    let isSelected: Bool
    var accentColor: Color = AppTheme.tealGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(difficulty.rawValue)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(isSelected ? .white : AppTheme.deepCharcoal)

                    Text(difficulty.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : AppTheme.mediumGray)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill(isSelected ? accentColor : accentColor.opacity(0.08))
            )
        }
        .pressable()
    }
}
