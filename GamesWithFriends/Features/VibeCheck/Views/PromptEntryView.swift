import SwiftUI

struct PromptEntryView: View {
    @Bindable var viewModel: VibeCheckViewModel
    @FocusState private var isPromptFieldFocused: Bool

    private var canSubmit: Bool {
        !viewModel.currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                // Header - inline at top
                headerSection

                // Instructions card
                instructionsCard

                // Spectrum with target
                if let round = viewModel.currentRound {
                    PromptSetterSliderView(
                        spectrum: round.spectrum,
                        targetPosition: round.targetPosition
                    )
                }

                // Prompt input
                promptInputSection

                // Submit button
                submitButton
            }
            .padding(.horizontal)
            .padding(.top, AppTheme.Spacing.sm)
            .padding(.bottom)
        }
        .background {
            LinearGradient(
                colors: [GameTheme.vibeCheck.accentColor.opacity(0.1), GameTheme.vibeCheck.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            if let round = viewModel.currentRound {
                Text("Round \(round.roundNumber)")
                    .font(AppTheme.Typography.secondary)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let setter = viewModel.promptSetterTeam {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "person.fill.questionmark")
                    Text("\(setter.name) - Prompt Setter")
                }
                .font(AppTheme.Typography.secondary.weight(.semibold))
                .foregroundStyle(.purple)
            }
        }
    }

    private var instructionsCard: some View {
        VStack(spacing: 6) {
            Image(systemName: "lightbulb.fill")
                .font(AppTheme.Typography.subsectionHeader)
                .foregroundStyle(.yellow)

            Text("Create a Prompt")
                .font(AppTheme.Typography.secondary.weight(.semibold))

            Text("Think of something that matches the target position on the spectrum. Your team will try to guess where you placed it!")
                .font(AppTheme.Typography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(AppTheme.pureWhite)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
    }

    private var promptInputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Your Prompt:")
                .font(AppTheme.Typography.secondary.weight(.medium))

            TextField("Enter something that matches the target...", text: $viewModel.currentPrompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...2)
                .focused($isPromptFieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    if canSubmit {
                        viewModel.submitPrompt()
                    }
                }
        }
        .padding(AppTheme.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                .fill(AppTheme.pureWhite)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 3)
        }
    }

    private var submitButton: some View {
        Button {
            viewModel.submitPrompt()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("SUBMIT PROMPT")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background {
                LinearGradient(
                    colors: canSubmit ? [.purple, .blue] : [.gray, .gray],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
    }
}

#Preview {
    let viewModel = VibeCheckViewModel()
    viewModel.settings.teamCount = 1
    viewModel.settings.playersPerTeam = 3
    viewModel.proceedToTeamSetup()
    viewModel.startGame()
    viewModel.confirmPromptSetterReady()
    return PromptEntryView(viewModel: viewModel)
}
