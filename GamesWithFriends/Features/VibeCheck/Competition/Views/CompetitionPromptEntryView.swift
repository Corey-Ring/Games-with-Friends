import SwiftUI

struct CompetitionPromptEntryView: View {
    @Bindable var viewModel: CompetitionVibeCheckViewModel
    @FocusState private var isPromptFieldFocused: Bool

    private var canSubmit: Bool {
        !viewModel.currentPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            // Text entry screen: plain ground, no motifs behind the keyboard
            // (§3 recipe / §7 — nothing within 12pt of an input).
            AppTheme.Retro.ground.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    // Header
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
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        HStack {
            if let round = viewModel.currentRound {
                Text("Round \(round.roundNumber)")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.panelText)
                    .retroLozenge()
            }

            Spacer()

            if let setter = viewModel.vibeSetter {
                // §8: the setter chip's plum fill takes cream text.
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "person.fill.questionmark")
                    Text("\(setter.name) - Vibe Setter")
                }
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.setterRole))
                .retroLozenge(VibeCheckStyle.setterRole)
            }
        }
    }

    private var instructionsCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Ink-outlined badge instead of the naked tinted SF glyph (§9).
            VibeCheckStatusBadge(systemImage: "lightbulb.fill",
                                 color: AppTheme.Retro.mustard,
                                 diameter: 28)

            Text("Create a Prompt")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            Text("Think of something that matches the target position. The other players will try to guess where you placed it!")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.cocoa)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .retroCard()
    }

    private var promptInputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Your Prompt:")
                .font(AppTheme.Retro.Typography.cardTitle)
                .foregroundColor(AppTheme.Retro.panelText)

            TextField("Enter something that matches the target...", text: $viewModel.currentPrompt, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...2)
                .focused($isPromptFieldFocused)
                .submitLabel(.done)
                .tint(VibeCheckStyle.accent)
                .onSubmit {
                    if canSubmit {
                        viewModel.submitPrompt()
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }

    private var submitButton: some View {
        RetroPrimaryButton(title: "Submit Prompt", icon: "checkmark",
                           accent: VibeCheckStyle.accent) {
            viewModel.submitPrompt()
        }
        .disabled(!canSubmit)
        .opacity(canSubmit ? 1.0 : 0.6)
    }
}

#Preview {
    let viewModel = CompetitionVibeCheckViewModel()
    viewModel.settings.playerCount = 4
    viewModel.proceedToPlayerSetup()
    viewModel.startGame()
    viewModel.confirmVibeSetterReady()
    return CompetitionPromptEntryView(viewModel: viewModel)
}
