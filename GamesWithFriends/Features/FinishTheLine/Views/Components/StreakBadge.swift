//
//  StreakBadge.swift
//  GamesWithFriends
//

import SwiftUI

/// Streak indicator that pops into view once the player has a streak of 2+.
/// Scales briefly when the streak increments.
struct StreakBadge: View {
    let streak: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bumpScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppTheme.warning, AppTheme.brandOrange],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            Text("\(streak)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(AppTheme.brandOrange)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(AppTheme.brandOrange.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(AppTheme.brandOrange.opacity(0.35), lineWidth: 1)
        )
        .scaleEffect(bumpScale)
        .shadow(color: AppTheme.brandOrange.opacity(0.25), radius: 6, x: 0, y: 2)
        .onChange(of: streak) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                bumpScale = 1.25
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.15)) {
                bumpScale = 1.0
            }
        }
        .accessibilityLabel("Streak of \(streak)")
    }
}
