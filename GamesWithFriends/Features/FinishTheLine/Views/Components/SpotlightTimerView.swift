//
//  SpotlightTimerView.swift
//  GamesWithFriends
//

import SwiftUI

/// Round timer that transitions through color states as time runs out.
/// - Normal (>30s): accent color (plum)
/// - Caution (11-30s): tangerine
/// - Danger (<=10s): tomato, with a gentle pulse
///
/// Retro treatment only: the dial rides a cream plate with an ink rule and the
/// numerals read ink-on-cream until the urgent stop. The `progress` math, the
/// trim/rotation animation, the pulse trigger and the three thresholds are
/// unchanged.
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
        // Divide by the round's own duration so a fresh round starts at a full
        // ring. On Fire can bank time above `totalDuration`, so clamp to 1.0 to
        // pin the ring at full instead of overflowing.
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, timeRemaining / totalDuration))
    }

    /// Arc color for the current stop — same thresholds as before, candy hues.
    private var displayColor: Color {
        if timeRemaining <= 10 {
            return FinishTheLineStyle.timerUrgentArc
        } else if timeRemaining <= 30 {
            return FinishTheLineStyle.timerCautionArc
        } else {
            return accentColor
        }
    }

    /// Numerals stay ink-on-cream until the urgent stop turns them tomato
    /// (§3 recipe) — same trigger, no new condition.
    private var numeralColor: Color {
        timeRemaining <= 10 ? FinishTheLineStyle.timerUrgentArc : FinishTheLineStyle.timerCalmText
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                // Cream dial plate with an ink rule.
                Circle()
                    .fill(AppTheme.Retro.panel)
                    .frame(width: 36, height: 36)
                Circle()
                    .stroke(AppTheme.Retro.ink, lineWidth: 2)
                    .frame(width: 36, height: 36)

                // Unfilled track: ink at 15% (§4 gotcha 6).
                Circle()
                    .inset(by: 3)
                    .stroke(AppTheme.Retro.ink.opacity(0.15), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .inset(by: 3)
                    .trim(from: 0, to: progress)
                    .stroke(
                        displayColor,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: progress)

                Image(systemName: "timer")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(numeralColor)
            }
            .scaleEffect(pulse && timeRemaining <= 10 && !reduceMotion ? 1.08 : 1.0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                value: pulse
            )

            Text(String(format: "%02d", seconds))
                .font(AppTheme.Retro.Typography.heading(28, relativeTo: .title))
                .foregroundColor(numeralColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.2), value: seconds)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Capsule().fill(AppTheme.Retro.panel))
        .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
        .background(
            Capsule()
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
        .onAppear {
            pulse = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(seconds) seconds remaining")
    }
}
