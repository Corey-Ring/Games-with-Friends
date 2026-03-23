import SwiftUI

struct CompetitionPassDeviceView: View {
    let playerName: String
    let role: PlayerRole
    let onReady: () -> Void

    enum PlayerRole {
        case vibeSetter
        case guesser

        var title: String {
            switch self {
            case .vibeSetter: return "Vibe Setter"
            case .guesser: return "Guesser"
            }
        }

        var icon: String {
            switch self {
            case .vibeSetter: return "person.fill.questionmark"
            case .guesser: return "hand.tap.fill"
            }
        }

        var instruction: String {
            switch self {
            case .vibeSetter: return "You'll see a target position and create a prompt that matches it"
            case .guesser: return "You'll see the prompt and guess where it belongs on the spectrum"
            }
        }

        var color: Color {
            switch self {
            case .vibeSetter: return .purple
            case .guesser: return .orange
            }
        }
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()

            // Device passing icon
            Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
                .symbolEffect(.pulse, options: .repeating)

            // Pass instruction
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Pass the device to")
                    .font(AppTheme.Typography.subsectionHeader)
                    .foregroundStyle(.secondary)

                Text(playerName)
                    .font(AppTheme.Typography.hero)
                    .foregroundStyle(role.color)

                // Role badge
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: role.icon)
                    Text(role.title)
                }
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.vertical, AppTheme.Spacing.sm)
                .background {
                    Capsule()
                        .fill(role.color)
                }
            }

            // Instructions
            Text(role.instruction)
                .font(AppTheme.Typography.secondary)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer()

            // Ready button
            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onReady()
            } label: {
                HStack {
                    Image(systemName: "hand.tap.fill")
                    Text("I'M READY")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background {
                    LinearGradient(
                        colors: [role.color, role.color.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            // Privacy reminder
            if role == .guesser {
                Text("Don't look at other players' guesses!")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Keep the target position secret!")
                    .font(AppTheme.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background {
            LinearGradient(
                colors: [role.color.opacity(0.1), AppTheme.pureWhite],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Wrapper for ViewModel Integration

struct CompetitionVibeSetterPassView: View {
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        if let setter = viewModel.vibeSetter {
            CompetitionPassDeviceView(
                playerName: setter.name,
                role: .vibeSetter
            ) {
                viewModel.confirmVibeSetterReady()
            }
        }
    }
}

struct CompetitionGuesserPassView: View {
    var viewModel: CompetitionVibeCheckViewModel

    var body: some View {
        if let player = viewModel.currentGuessingPlayer {
            CompetitionPassDeviceView(
                playerName: player.name,
                role: .guesser
            ) {
                viewModel.confirmGuessingPlayerReady()
            }
        }
    }
}

#Preview("Vibe Setter") {
    CompetitionPassDeviceView(
        playerName: "Alice",
        role: .vibeSetter
    ) {}
}

#Preview("Guesser") {
    CompetitionPassDeviceView(
        playerName: "Bob",
        role: .guesser
    ) {}
}
