//
//  BorderBlitzMenuView.swift
//  BorderBlitz
//

import SwiftUI

struct BorderBlitzMenuView: View {
    var viewModel: BorderBlitzViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The setup column (difficulty rows, permission card, CTA)
                // runs inset 24pt; motifs keep to the nav strip and the outer
                // gutters, ≥12pt clear of every control (§7 — the generator
                // adds the clearance).
                MotifGroundView(seed: 0xB0DE_8B01,
                                exclusions: [CGRect(x: 24, y: 56,
                                                    width: geo.size.width - 48,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header: spot plate + framed Lilita title. "Border Blitz"
                    // is past the ~8-char Shrikhand cap, so it stays Lilita
                    // (§4); the gradient disc + naked SF hero it replaces are
                    // both retirements (§9).
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle().fill(AppTheme.Retro.panel)
                            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                            RetroSpotIllustration(kind: .borderMap)
                                .frame(width: 74, height: 74)
                        }
                        .frame(width: 110, height: 110)

                        Text("Border Blitz")
                            .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                            .foregroundColor(AppTheme.Retro.ink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .retroPanel(BorderBlitzStyle.accent)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                    .fill(AppTheme.Retro.ink)
                                    .offset(x: AppTheme.Retro.shadowOffset,
                                            y: AppTheme.Retro.shadowOffset)
                            )
                            .rotationEffect(.degrees(-1))

                        Text("Identify countries by their borders")
                            .font(AppTheme.Typography.secondary)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .multilineTextAlignment(.center)
                            .retroLozenge()
                            .rotationEffect(.degrees(0.8))
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    // Difficulty selection — the section label rides a cream
                    // lozenge rather than floating on the motif field (§9),
                    // and each row is its own framed panel (§3 recipe).
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Select Difficulty")
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .retroLozenge()

                        ForEach(BorderBlitzDifficulty.allCases) { difficulty in
                            BorderBlitzDifficultyButton(
                                difficulty: difficulty,
                                isSelected: viewModel.selectedDifficulty == difficulty,
                                accentColor: BorderBlitzStyle.accent
                            ) {
                                viewModel.selectedDifficulty = difficulty
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AppTheme.Spacing.md)

                    // Permission status
                    switch viewModel.speechManager.permissionStatus {
                    case .notDetermined:
                        VStack(spacing: AppTheme.Spacing.md) {
                            micPlate(systemImage: "mic.fill", color: BorderBlitzStyle.accent)

                            Text("Microphone Required")
                                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                                .foregroundColor(AppTheme.Retro.panelText)
                            Text("Border Blitz uses your voice to detect country guesses. Tap below to enable microphone and speech recognition.")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Retro.panelText)
                                .multilineTextAlignment(.center)
                            RetroPrimaryButton(title: "Enable Microphone", icon: "mic.fill",
                                               accent: BorderBlitzStyle.accent) {
                                Task { await viewModel.speechManager.requestPermissions() }
                            }
                        }
                        .retroCard()
                        .padding(.horizontal, AppTheme.Spacing.md)

                    case .authorized:
                        EmptyView()

                    case .denied:
                        VStack(spacing: AppTheme.Spacing.md) {
                            micPlate(systemImage: "mic.slash.fill", color: BorderBlitzStyle.dangerColor)

                            Text("Microphone Access Denied")
                                .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                                .foregroundColor(AppTheme.Retro.panelText)
                            Text("Border Blitz needs microphone and speech recognition access to work. Please enable them in Settings.")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.Retro.panelText)
                                .multilineTextAlignment(.center)
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                Link("Open Settings", destination: settingsURL)
                                    .font(AppTheme.Retro.Typography.heading(17))
                                    .foregroundColor(AppTheme.Retro.ink)
                                    .padding(.vertical, AppTheme.Spacing.xs)
                                    .retroLozenge(BorderBlitzStyle.accent)
                            }
                        }
                        .retroCard()
                        .padding(.horizontal, AppTheme.Spacing.md)
                    }

                    // Start button — if the mic permission hasn't been decided yet,
                    // request it first so a round never runs with a silently dead mic.
                    RetroPrimaryButton(title: "Start Game", icon: "play.fill",
                                       accent: BorderBlitzStyle.accent) {
                        Task {
                            if viewModel.speechManager.permissionStatus == .notDetermined {
                                await viewModel.speechManager.requestPermissions()
                            }
                            if viewModel.speechManager.permissionStatus != .denied {
                                viewModel.startGame()
                            }
                        }
                    }
                    .disabled(viewModel.speechManager.permissionStatus == .denied)
                    .opacity(viewModel.speechManager.permissionStatus == .denied ? 0.5 : 1.0)
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
        }
        .navigationBarBackButtonHidden(viewModel.gameStarted)
        .onAppear {
            viewModel.speechManager.checkPermissionStatus()
        }
    }

    /// Functional mic glyph on an ink-outlined cream plate — the permission
    /// states are chrome, not celebration, so they take a plate rather than a
    /// spot illustration (§6: SF glyphs survive as functional icons).
    private func micPlate(systemImage: String, color: Color) -> some View {
        ZStack {
            Circle().fill(AppTheme.Retro.panel)
            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
            Image(systemName: systemImage)
                .font(.system(size: 30, weight: .bold))
                .foregroundColor(color)
        }
        .frame(width: 72, height: 72)
    }
}

struct BorderBlitzDifficultyButton: View {
    let difficulty: BorderBlitzDifficulty
    let isSelected: Bool
    var accentColor: Color = BorderBlitzStyle.accent
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(difficulty.rawValue)
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(isSelected ? BorderBlitzStyle.chipTextColor(on: accentColor)
                                                    : AppTheme.Retro.panelText)

                    // §8: ink on poolBlue passes; the unselected row is plain
                    // ink-on-cream, so the copy is safe either way.
                    Text(difficulty.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(isSelected ? BorderBlitzStyle.chipTextColor(on: accentColor)
                                                    : AppTheme.Retro.panelText.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 17, weight: .black))
                        .foregroundColor(BorderBlitzStyle.chipTextColor(on: accentColor))
                }
            }
            .padding(AppTheme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .retroPanel(isSelected ? accentColor : AppTheme.Retro.panel)
        }
        .buttonStyle(RetroRaisedButtonStyle())
    }
}
