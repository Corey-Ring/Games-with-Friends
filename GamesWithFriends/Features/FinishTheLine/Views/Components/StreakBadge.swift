//
//  StreakBadge.swift
//  GamesWithFriends
//

import SwiftUI

/// Streak indicator that pops into view once the player has a streak of 2+.
/// Scales briefly when the streak increments. At 5+ the streak is On Fire:
/// the badge saturates, glows, and every correct answer buys time back.
struct StreakBadge: View {
    let streak: Int
    var isOnFire: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bumpScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(flameStyle)

            Text("\(streak)")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(isOnFire ? .white : AppTheme.brandOrange)
                .monospacedDigit()
                .contentTransition(.numericText())

            if isOnFire {
                Text("ON FIRE")
                    .font(AppTheme.Typography.pillLabel)
                    .tracking(1.2)
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule().fill(backgroundStyle)
        )
        .overlay(
            Capsule()
                .stroke(AppTheme.brandOrange.opacity(isOnFire ? 0 : 0.35), lineWidth: 1)
        )
        .scaleEffect(bumpScale)
        .shadow(
            color: AppTheme.brandOrange.opacity(isOnFire ? 0.5 : 0.25),
            radius: isOnFire ? 10 : 6,
            x: 0,
            y: 2
        )
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

    private var flameStyle: AnyShapeStyle {
        if isOnFire {
            return AnyShapeStyle(Color.white)
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [AppTheme.warning, AppTheme.brandOrange],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var backgroundStyle: AnyShapeStyle {
        if isOnFire {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [AppTheme.warning, AppTheme.brandOrange],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(AppTheme.brandOrange.opacity(0.12))
    }
}
