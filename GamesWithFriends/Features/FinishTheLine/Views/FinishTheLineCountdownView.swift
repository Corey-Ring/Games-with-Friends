//
//  FinishTheLineCountdownView.swift
//  GamesWithFriends
//

import SwiftUI

struct FinishTheLineCountdownView: View {
    @Bindable var viewModel: FinishTheLineViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let theme = GameTheme.finishTheLine

    var body: some View {
        ZStack {
            GameBackground(gameTheme: theme)

            VStack(spacing: AppTheme.Spacing.xl) {
                Text("Get ready")
                    .font(AppTheme.Typography.sectionHeader)
                    .foregroundColor(theme.accentColor)
                    .textCase(.uppercase)
                    .tracking(3)

                countdownNumeral
                    .frame(width: 260, height: 260)

                Text("Shout the missing word")
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.mediumGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)

                if let target = viewModel.scoreToBeat {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(verbatim: "Score to beat: \(target)")
                            .font(AppTheme.Typography.pillLabel)
                    }
                    .foregroundColor(theme.accentColor)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule().fill(theme.accentColor.opacity(0.12))
                    )
                    .accessibilityLabel("Score to beat: \(target) points")
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(viewModel.countdownValue > 0 ? "Starting in \(viewModel.countdownValue)" : "Go")
    }

    // MARK: - Countdown numeral

    private var countdownNumeral: some View {
        ZStack {
            Circle()
                .stroke(theme.accentColor.opacity(0.15), lineWidth: 4)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [theme.accentColor.opacity(0.25), theme.accentColor.opacity(0.02)],
                        center: .center,
                        startRadius: 40,
                        endRadius: 180
                    )
                )

            // Numeral or GO
            Group {
                if viewModel.countdownValue > 0 {
                    Text("\(viewModel.countdownValue)")
                        .font(.system(size: 160, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accentColor, theme.accentColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    Text("GO")
                        .font(.system(size: 110, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.accentColor, AppTheme.brandOrange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .tracking(2)
                }
            }
            .id(viewModel.countdownValue)
            .transition(reduceMotion ? .opacity : .scale(scale: 0.4).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: viewModel.countdownValue)
        }
    }
}
