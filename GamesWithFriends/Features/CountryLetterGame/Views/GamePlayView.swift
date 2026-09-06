import SwiftUI

struct GamePlayView: View {
    @Bindable var viewModel: CountryGameViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dismiss) private var dismiss
    @Environment(\.systemChromeInsets) private var chrome

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // Everything inside the safe area is interactive (nav
                // lozenges, input field, stat cards, the guessed list, the
                // action row), so motifs keep to the outer edges and the
                // strip under the home indicator (§7).
                MotifGroundView(seed: 0xC1A5_0F03,
                                exclusions: [CGRect(x: 8, y: chrome.top,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height
                                                        - chrome.top - chrome.bottom)])
            }
            .ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                // Both ways back, in the same lozenge: left to the hub,
                // right to the letter picker.
                HStack {
                    CountryLetterNavButton(title: "Main menu") {
                        dismiss()
                    }

                    Spacer()

                    CountryLetterNavButton(title: "Pick another letter") {
                        viewModel.changeLetterFromGame()
                    }
                }
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.sm)

                if let letter = viewModel.selectedLetter {
                    instructionBanner(letter: letter)
                }

                // Stats cards
                HStack(spacing: AppTheme.Spacing.md) {
                    StatCard(title: "Progress", value: "\(viewModel.foundCount)/\(viewModel.totalCountries)")
                    StatCard(title: "Remaining", value: "\(viewModel.remainingCount)")
                }
                .padding(.horizontal)

                // Guess input form — typed or spoken. The mic lozenge in the
                // header is the voice affordance; the caption under the field
                // spells out the current state in words.
                VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                    HStack {
                        Text("Country Guess")
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(AppTheme.Retro.panelText)

                        Spacer()

                        CountryLetterVoiceControl(viewModel: viewModel)
                    }

                    HStack(spacing: AppTheme.Spacing.sm) {
                        TextField("Type a country name...", text: $viewModel.currentGuess)
                            .textFieldStyle(.plain)
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .padding(AppTheme.Spacing.sm + 2)
                            .retroPanel(AppTheme.Retro.panel,
                                        cornerRadius: AppTheme.Retro.Radius.inner)
                            .onSubmit {
                                viewModel.submitGuess()
                            }
                            .textInputAutocapitalization(.words)
                            .disableAutocorrection(true)

                        Button(action: {
                            viewModel.submitGuess()
                        }) {
                            Text("Submit")
                                .font(AppTheme.Retro.Typography.heading(17))
                                .foregroundColor(AppTheme.Retro.ink)
                                .padding(.horizontal, AppTheme.Spacing.md)
                                .padding(.vertical, AppTheme.Spacing.sm + 4)
                                .retroPanel(CountryLetterStyle.accent,
                                            cornerRadius: AppTheme.Retro.Radius.inner)
                        }
                        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
                    }

                    Text(voiceHint)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .retroCard()
                .padding(.horizontal)

                // Feedback message — §8: the copy stays ink-on-cream and the
                // semantic color rides on the ink-outlined status badge.
                HStack(spacing: AppTheme.Spacing.sm) {
                    if !viewModel.feedbackMessage.isEmpty {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            CountryStatusBadge(systemImage: feedbackIcon, color: feedbackColor)

                            Text(viewModel.feedbackMessage)
                                .font(AppTheme.Typography.secondary)
                                .foregroundColor(AppTheme.Retro.panelText)
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroLozenge()
                    }
                }
                .frame(minHeight: 30)
                .padding(.horizontal)

                // Guessed countries list
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: AppTheme.Spacing.md) {
                        ForEach(Array(viewModel.guessedCountries.enumerated()), id: \.element.id) { index, country in
                            HStack(spacing: AppTheme.Spacing.sm) {
                                CountryStatusBadge(systemImage: "checkmark",
                                                   color: CountryLetterStyle.correctColor)

                                Text(country.name)
                                    .font(AppTheme.Retro.Typography.cardTitle)
                                    .foregroundColor(AppTheme.Retro.panelText)

                                Spacer()
                            }
                            .retroCard()
                            .staggeredAppear(index: index)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, AppTheme.Spacing.sm)
                }
                .scrollIndicators(.hidden)

                // Action buttons
                HStack(spacing: AppTheme.Spacing.md) {
                    // Tangerine reads as the utility action next to the grass
                    // primary — same split the pilot uses for "Pass" (§3.2's
                    // one-accent rule governs the screen's identity color).
                    RetroPrimaryButton(title: "Hint", icon: "lightbulb.fill",
                                       accent: AppTheme.Retro.tangerine) {
                        viewModel.showHint()
                    }

                    RetroPrimaryButton(title: "Done", icon: "checkmark",
                                       accent: CountryLetterStyle.accent) {
                        viewModel.finishGame()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        // The mic only runs while this screen is on top and the app is in the
        // foreground; the view model owns the muted flag, so a resume never
        // re-arms a mic the player switched off.
        .onAppear { viewModel.activateVoiceIfAllowed() }
        .onDisappear { viewModel.suspendVoice() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.activateVoiceIfAllowed()
            } else {
                viewModel.suspendVoice()
            }
        }
    }

    /// The round's instruction, loud and first: the letter as the screen's
    /// biggest object (chunky Lilita, ink on grass, hard-shadowed — §4/§5)
    /// beside a plain-words brief of what to do.
    private func instructionBanner(letter: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Text(letter)
                .font(AppTheme.Retro.Typography.heading(30, relativeTo: .largeTitle))
                .foregroundColor(AppTheme.Retro.ink)
                .frame(width: 56, height: 56)
                .retroPanel(CountryLetterStyle.accent,
                            cornerRadius: AppTheme.Retro.Radius.inner)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                        .fill(AppTheme.Retro.ink)
                        .offset(x: AppTheme.Retro.shadowOffset,
                                y: AppTheme.Retro.shadowOffset)
                )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Name every country that starts with \(letter)")
                    .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
                    .foregroundColor(AppTheme.Retro.panelText)
                    .fixedSize(horizontal: false, vertical: true)

                Text("There are \(viewModel.totalCountries) to find. Type or say them below.")
                    .font(AppTheme.Typography.secondary)
                    .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
    }

    private var voiceHint: String {
        switch viewModel.voiceState {
        case .listening: return "Or just say it out loud. The mic is on."
        case .off: return "Tap the mic to say your guesses instead of typing."
        case .needsPermission: return "Tap the mic to say your guesses instead of typing."
        case .denied: return "Voice needs microphone access. Tap the mic to open Settings."
        }
    }

    private var feedbackIcon: String {
        switch viewModel.feedbackType {
        case .success: return "checkmark"
        case .error: return "xmark"
        case .info: return "info.circle"
        }
    }

    private var feedbackColor: Color {
        switch viewModel.feedbackType {
        case .success: return CountryLetterStyle.successColor
        case .error: return CountryLetterStyle.errorColor
        case .info: return CountryLetterStyle.infoColor
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.7))

            Text(value)
                .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                .foregroundColor(AppTheme.Retro.panelText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .retroCard()
    }
}
