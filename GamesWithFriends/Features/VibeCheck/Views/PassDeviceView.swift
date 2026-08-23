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

        /// Candy remap of the retired `.purple` / `.orange` literals — the two
        /// role fills live in VibeCheckStyle so both modes share them.
        var color: Color {
            switch self {
            case .promptSetter: return VibeCheckStyle.setterRole
            case .guessingTeam: return VibeCheckStyle.guesserRole
            }
        }
    }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Privacy screen: the hand-off column owns the middle, motifs
                // fill the gutters and the top/bottom bands (§7).
                MotifGroundView(seed: 0x71BE_0C03,
                                exclusions: [CGRect(x: 8, y: 96,
                                                    width: geo.size.width - 16,
                                                    height: max(0, geo.size.height - 200))])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                // Device passing icon on a cream spot plate (§9 — no naked SF
                // hero); the pulse still carries the "hand it over" beat.
                ZStack {
                    Circle().fill(AppTheme.Retro.panel)
                    Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 52))
                        .foregroundColor(AppTheme.Retro.panelText)
                        .symbolEffect(.pulse, options: .repeating)
                }
                .frame(width: 110, height: 110)

                // Pass instruction
                VStack(spacing: AppTheme.Spacing.md) {
                    Text("Pass the device to")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .retroLozenge()

                    // The name is the loudest object on the screen: chunky
                    // Lilita locked in a hard-shadowed role panel (§4/§5).
                    Text(teamName)
                        .font(AppTheme.Retro.Typography.heading(34, relativeTo: .largeTitle))
                        .foregroundColor(VibeCheckStyle.roleTextColor(on: role.color))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .retroPanel(role.color)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                .fill(AppTheme.Retro.ink)
                                .offset(x: AppTheme.Retro.shadowOffset,
                                        y: AppTheme.Retro.shadowOffset)
                        )
                        .rotationEffect(.degrees(-1))

                    // Role badge
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: role.icon)
                        Text(role.title)
                    }
                    .font(AppTheme.Retro.Typography.heading(17))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .retroLozenge()
                    .rotationEffect(.degrees(0.8))
                }

                // Instructions — body copy always lands on cream (§8).
                Text(role.instruction)
                    .font(AppTheme.Typography.secondary)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .retroLozenge()
                    .padding(.horizontal, AppTheme.Spacing.lg)

                Spacer()

                // Ready button
                RetroPrimaryButton(title: "I'm Ready", icon: "hand.tap.fill",
                                   accent: role.color,
                                   textColor: VibeCheckStyle.roleTextColor(on: role.color)) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onReady()
                }
                .padding(.horizontal)

                // Privacy reminder
                if role == .guessingTeam {
                    Text("Don't look until everyone is ready!")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .retroLozenge()
                } else {
                    Text("Keep the target position secret!")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .retroLozenge()
                }
            }
            .padding()
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
