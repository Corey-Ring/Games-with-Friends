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
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<barMultipliers.count, id: \.self) { index in
                let effectiveLevel = isListening ? CGFloat(audioLevel * barMultipliers[index]) : 0
                let height = minHeight + (maxHeight - minHeight) * effectiveLevel

                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 6, height: height)
                    .animation(.spring(response: 0.15), value: audioLevel)
            }
        }
        .frame(height: maxHeight)
        .accessibilityElement()
        .accessibilityLabel(isListening ? "Microphone active" : "Microphone inactive")
    }
}
