import SwiftUI

/// The guess card's mic switch. One raised lozenge carries all four voice
/// states so the affordance never moves: it reads "Use your voice" before
/// permission is granted, shows a live level meter while listening, and
/// deep-links to Settings once the mic has been blocked.
struct CountryLetterVoiceControl: View {
    var viewModel: CountryGameViewModel

    var body: some View {
        let state = viewModel.voiceState
        let look = Presentation.for(state)

        Group {
            if state == .denied,
               let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: settingsURL) { label(look, listening: false) }
            } else {
                Button {
                    Task { await viewModel.toggleVoice() }
                } label: {
                    label(look, listening: state == .listening)
                }
            }
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
        .accessibilityLabel(look.accessibilityLabel)
        .accessibilityHint(look.accessibilityHint)
    }

    private func label(_ look: Presentation, listening: Bool) -> some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: look.icon)
                .font(AppTheme.Retro.Typography.pillLabel)

            if listening {
                // The meter reads the audio level itself so ~50 updates a
                // second re-render five bars, not the whole lozenge.
                CountryLetterVoiceMeter(speechManager: viewModel.speechManager)
            }

            Text(look.title)
                .font(AppTheme.Retro.Typography.pillLabel)
                .lineLimit(1)
        }
        .foregroundColor(look.textColor)
        .retroLozenge(look.fill)
    }

    /// Everything a state shows, in one place, so a new state can't ship
    /// with a stale icon or VoiceOver string.
    private struct Presentation {
        let icon: String
        let title: String
        let fill: Color
        let textColor: Color
        let accessibilityLabel: String
        let accessibilityHint: String

        static func `for`(_ state: CountryGameViewModel.VoiceState) -> Presentation {
            switch state {
            case .listening:
                // Grass while live or on offer (§3.2 one-accent rule: grass only).
                return Presentation(icon: "mic.fill", title: "Listening",
                                    fill: CountryLetterStyle.accent,
                                    textColor: CountryLetterStyle.chipTextColor(on: CountryLetterStyle.accent),
                                    accessibilityLabel: "Microphone on, listening for country names",
                                    accessibilityHint: "Turns voice guessing off")
            case .off:
                return Presentation(icon: "mic.slash.fill", title: "Voice off",
                                    fill: AppTheme.Retro.panel,
                                    textColor: AppTheme.Retro.panelText,
                                    accessibilityLabel: "Microphone off",
                                    accessibilityHint: "Turns voice guessing on")
            case .needsPermission:
                return Presentation(icon: "mic.badge.plus", title: "Use your voice",
                                    fill: CountryLetterStyle.accent,
                                    textColor: CountryLetterStyle.chipTextColor(on: CountryLetterStyle.accent),
                                    accessibilityLabel: "Use your voice",
                                    accessibilityHint: "Asks for microphone access so you can say your guesses")
            case .denied:
                return Presentation(icon: "mic.slash.fill", title: "Mic blocked",
                                    fill: CountryLetterStyle.errorColor,
                                    textColor: CountryLetterStyle.chipTextColor(on: CountryLetterStyle.errorColor),
                                    accessibilityLabel: "Microphone access blocked",
                                    accessibilityHint: "Opens Settings")
            }
        }
    }
}

/// Pocket version of the Border Blitz level meter, sized to sit inside a
/// lozenge. Same five-bar envelope and spring cadence.
private struct CountryLetterVoiceMeter: View {
    let speechManager: CountryLetterSpeechRecognitionManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let barMultipliers: [Float] = [0.6, 0.85, 1.0, 0.85, 0.6]
    private let minHeight: CGFloat = 3
    private let maxHeight: CGFloat = 14

    var body: some View {
        let audioLevel = speechManager.audioLevel
        HStack(spacing: AppTheme.Spacing.xs) {
            ForEach(0..<barMultipliers.count, id: \.self) { index in
                let level = CGFloat(audioLevel * barMultipliers[index])
                RoundedRectangle(cornerRadius: 1)
                    .fill(AppTheme.Retro.ink)
                    .frame(width: 3, height: minHeight + (maxHeight - minHeight) * level)
                    .animation(reduceMotion ? nil : .spring(response: 0.15), value: audioLevel)
            }
        }
        .frame(height: maxHeight)
        .accessibilityHidden(true)
    }
}
