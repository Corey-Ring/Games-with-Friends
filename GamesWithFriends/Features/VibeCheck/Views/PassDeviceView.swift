import SwiftUI

struct PassDeviceView: View {
    let teamName: String
    let role: TeamRole
    let onReady: () -> Void

    enum TeamRole {
        case promptSetter
        case guessingTeam

        var title: String {
            switch self {
            case .promptSetter: return "Prompt Setter"
            case .guessingTeam: return "Guessing Team"
            }
        }

        var icon: String {
            switch self {
            case .promptSetter: return "person.fill.questionmark"
            case .guessingTeam: return "hand.tap.fill"
            }
        }

        var instruction: String {
            switch self {
            case .promptSetter: return "You'll see a target position and create a prompt that matches it"
            case .guessingTeam: return "You'll see the prompt and guess where it belongs on the spectrum"
            }
        }

        var color: Color {
            switch self {
            case .promptSetter: return .purple
            case .guessingTeam: return .orange
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

                Text(teamName)
                    .font(AppTheme.Typography.hero)
                    .foregroundStyle(role.color)

                // Role badge
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: role.icon)
                    Text(role.title)
                }
                .font(AppTheme.Typography.cardTitle)
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
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
            if role == .guessingTeam {
                Text("Don't look until everyone is ready!")
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
                colors: [role.color.opacity(0.1), Color(.systemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

// MARK: - Wrapper for ViewModel Integration

struct PromptSetterPassView: View {
    var viewModel: VibeCheckViewModel

    var body: some View {
        if let setter = viewModel.promptSetterTeam {
            PassDeviceView(
                teamName: setter.name,
                role: .promptSetter
            ) {
                viewModel.confirmPromptSetterReady()
            }
        }
    }
}

struct GuessingTeamPassView: View {
    var viewModel: VibeCheckViewModel

    var body: some View {
        if let team = viewModel.currentGuessingTeam {
            PassDeviceView(
                teamName: team.name,
                role: .guessingTeam
            ) {
                viewModel.confirmGuessingTeamReady()
            }
        }
    }
}

#Preview("Prompt Setter") {
    PassDeviceView(
        teamName: "Team Alpha",
        role: .promptSetter
    ) {}
}

#Preview("Guessing Team") {
    PassDeviceView(
        teamName: "Team Beta",
        role: .guessingTeam
    ) {}
}
