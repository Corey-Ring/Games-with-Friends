//
//  SpotlightTimerView.swift
//  GamesWithFriends
//

import SwiftUI

/// Round timer that transitions through color states as time runs out.
/// - Normal (>30s): accent color
/// - Caution (11-30s): warning orange
/// - Danger (<=10s): error red, with a gentle pulse
struct SpotlightTimerView: View {
    let timeRemaining: TimeInterval
    let totalDuration: TimeInterval
    let accentColor: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false

    private var seconds: Int {
        max(0, Int(ceil(timeRemaining)))
    }

    private var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, timeRemaining / totalDuration))
    }

    private var displayColor: Color {
        if timeRemaining <= 10 {
            return AppTheme.error
        } else if timeRemaining <= 30 {
            return AppTheme.warning
        } else {
            return accentColor
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .stroke(displayColor.opacity(0.18), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        displayColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)

                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(displayColor)
            }
            .scaleEffect(pulse && timeRemaining <= 10 && !reduceMotion ? 1.08 : 1.0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                value: pulse
            )

            Text(String(format: "%02d", seconds))
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(displayColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: seconds)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            Capsule()
                .fill(displayColor.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(displayColor.opacity(0.25), lineWidth: 1)
        )
        .onAppear {
            pulse = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(seconds) seconds remaining")
    }
}
