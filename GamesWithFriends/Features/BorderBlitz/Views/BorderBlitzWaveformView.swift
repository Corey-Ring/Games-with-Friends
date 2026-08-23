//
//  BorderBlitzWaveformView.swift
//  GamesWithFriends
//

import SwiftUI

struct BorderBlitzWaveformView: View {
    let audioLevel: Float
    let isListening: Bool
    let accentColor: Color

    private let barMultipliers: [Float] = [0.6, 0.85, 1.0, 0.85, 0.6]
    private let minHeight: CGFloat = 4
    private let maxHeight: CGFloat = 24

    var body: some View {
        // Recolor + chrome only: the amplitude math, the bar count, the frame
        // heights and the spring cadence below are untouched. Rule 1 puts an
        // ink rule on each bar; Rule 5 puts the whole meter in a cream device
        // so it reads as a printed level gauge rather than floating marks.
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<barMultipliers.count, id: \.self) { index in
                let effectiveLevel = isListening ? CGFloat(audioLevel * barMultipliers[index]) : 0
                let height = minHeight + (maxHeight - minHeight) * effectiveLevel

                RoundedRectangle(cornerRadius: 2)
                    .fill(isListening ? accentColor : AppTheme.Retro.ink.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(AppTheme.Retro.ink, lineWidth: 1)
                    )
                    .frame(width: 6, height: height)
                    .animation(.spring(response: 0.15), value: audioLevel)
            }
        }
        .frame(height: maxHeight)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .retroLozenge()
        .accessibilityElement()
        .accessibilityLabel(isListening ? "Microphone active" : "Microphone inactive")
    }
}
