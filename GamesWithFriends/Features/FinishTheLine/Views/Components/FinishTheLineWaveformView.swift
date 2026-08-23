//
//  FinishTheLineWaveformView.swift
//  GamesWithFriends
//

import SwiftUI

/// Audio-level waveform rendered beneath the quote card. Mirrors the shape of
/// Border Blitz's waveform but with slightly fatter bars.
///
/// Retro treatment is color only: flat accent fills with an ink outline
/// (Rule 1) replace the gradient bars and the soft glow (Rule 2 / §9). The
/// bar count, envelope, amplitude math and spring animation are unchanged.
struct FinishTheLineWaveformView: View {
    let audioLevel: Float
    let isListening: Bool
    let accentColor: Color

    private let barCount = 7
    private let minHeight: CGFloat = 6
    private let maxHeight: CGFloat = 32

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<barCount, id: \.self) { index in
                let multiplier = envelope(for: index)
                let effectiveLevel = isListening ? CGFloat(audioLevel) * CGFloat(multiplier) : 0
                let height = minHeight + (maxHeight - minHeight) * effectiveLevel

                RoundedRectangle(cornerRadius: 3)
                    .fill(isListening ? accentColor : AppTheme.Retro.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(AppTheme.Retro.ink, lineWidth: 1.5)
                    )
                    .frame(width: 8, height: height)
                    .animation(.spring(response: 0.18, dampingFraction: 0.7), value: audioLevel)
            }
        }
        .frame(height: maxHeight)
        .accessibilityElement()
        .accessibilityLabel(isListening ? "Microphone active" : "Microphone inactive")
    }

    /// Gentle envelope — tallest bars in the middle, shorter at the edges.
    private func envelope(for index: Int) -> Float {
        let center = Float(barCount - 1) / 2
        let distance = abs(Float(index) - center)
        let normalized = 1 - (distance / center)
        return max(0.55, normalized)
    }
}
