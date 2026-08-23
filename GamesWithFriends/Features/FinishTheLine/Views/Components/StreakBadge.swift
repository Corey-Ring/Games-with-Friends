//
//  StreakBadge.swift
//  GamesWithFriends
//

import SwiftUI

/// Streak indicator that pops into view once the player has a streak of 2+.
/// Scales briefly when the streak increments. At 5+ the streak is On Fire:
/// the badge steps from mustard to tangerine and every correct answer buys
/// time back.
///
/// Retro treatment: an ink-outlined candy chip with a hard offset shadow.
/// Both fills take ink labels (§8 — ink passes on mustard and tangerine), so
/// the number never needs its own lozenge. Show/hide and bump logic unchanged.
struct StreakBadge: View {
    let streak: Int
    var isOnFire: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bumpScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .bold))

            Text("\(streak)")
                .font(AppTheme.Retro.Typography.heading(16, relativeTo: .headline))
                .monospacedDigit()
                .contentTransition(.numericText())

            if isOnFire {
                Text("ON FIRE")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .tracking(1.2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .foregroundColor(FinishTheLineStyle.chipTextColor(on: chipFill))
        .retroLozenge(chipFill)
        .background(
            Capsule()
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
        .scaleEffect(bumpScale)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isOnFire)
        .onChange(of: streak) { _, _ in
            guard !reduceMotion else { return }
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                bumpScale = 1.25
            }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55).delay(0.15)) {
                bumpScale = 1.0
            }
        }
        .accessibilityLabel(isOnFire ? "On fire! Streak of \(streak). Correct answers add time." : "Streak of \(streak)")
    }

    /// Mustard while warming up, tangerine once On Fire — the same "hot
    /// streak" family, stepped rather than glowed (soft glows retired, §9).
    private var chipFill: Color {
        isOnFire ? FinishTheLineStyle.streakOnFireColor : FinishTheLineStyle.streakColor
    }
}
