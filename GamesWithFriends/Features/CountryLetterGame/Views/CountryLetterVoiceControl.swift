import SwiftUI

/// The guess card's mic switch. One raised lozenge carries all four voice
/// states so the affordance never moves: it reads "Use your voice" before
/// permission is granted, shows a live level meter while listening, and
/// deep-links to Settings once the mic has been blocked.
struct CountryLetterVoiceControl: View {
    var viewModel: CountryGameViewModel

    var body: some View {
        Group {
            if viewModel.voiceState == .denied,
               let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                Link(destination: settingsURL) { label }
            } else {
                Button {
                    Task { await viewModel.toggleVoice() }
                } label: {
                    label
                }
            }
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
    }

    private var label: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(AppTheme.Retro.Typography.pillLabel)

            if viewModel.voiceState == .listening {
                CountryLetterVoiceMeter(audioLevel: viewModel.speechManager.audioLevel)
            }

            Text(title)
                .font(AppTheme.Retro.Typography.pillLabel)
                .lineLimit(1)
        }
        .foregroundColor(textColor)
        .retroLozenge(fill)
    }

    private var icon: String {
        switch viewModel.voiceState {
        case .listening: return "mic.fill"
        case .off: return "mic.slash.fill"
        case .needsPermission: return "mic.badge.plus"
        case .denied: return "mic.slash.fill"
        }
    }

    private var title: String {
        switch viewModel.voiceState {
        case .listening: return "Listening"
        case .off: return "Voice off"
        case .needsPermission: return "Use your voice"
        case .denied: return "Mic blocked"
        }
    }

    /// Grass while the mic is live or on offer, tomato when blocked, cream
    /// when the player switched it off (§3.2 one-accent rule: grass only).
    private var fill: Color {
        switch viewModel.voiceState {
        case .listening, .needsPermission: return CountryLetterStyle.accent
        case .off: return AppTheme.Retro.panel
        case .denied: return CountryLetterStyle.errorColor
        }
    }

    private var textColor: Color {
        viewModel.voiceState == .off ? AppTheme.Retro.panelText : CountryLetterStyle.chipTextColor(on: fill)
    }

    private var accessibilityLabel: String {
        switch viewModel.voiceState {
        case .listening: return "Microphone on, listening for country names"
        case .off: return "Microphone off"
        case .needsPermission: return "Use your voice"
        case .denied: return "Microphone access blocked"
        }
    }

    private var accessibilityHint: String {
        switch viewModel.voiceState {
        case .listening: return "Turns voice guessing off"
        case .off: return "Turns voice guessing on"
        case .needsPermission: return "Asks for microphone access so you can say your guesses"
        case .denied: return "Opens Settings"
        }
    }
}

/// Pocket version of the Border Blitz level meter, sized to sit inside a
/// lozenge. Same five-bar envelope and spring cadence.
private struct CountryLetterVoiceMeter: View {
    let audioLevel: Float
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let barMultipliers: [Float] = [0.6, 0.85, 1.0, 0.85, 0.6]
    private let minHeight: CGFloat = 3
    private let maxHeight: CGFloat = 14

    var body: some View {
        HStack(spacing: 2) {
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
