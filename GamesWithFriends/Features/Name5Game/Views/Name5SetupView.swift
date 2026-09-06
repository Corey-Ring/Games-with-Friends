import SwiftUI

struct Name5SetupView: View {
    @Bindable var viewModel: Name5ViewModel

    var body: some View {
        ZStack {
            GeometryReader { geo in
                // The whole scrolling column is interactive (context cards,
                // toggles, pills, steppers), so motifs keep to the nav strip
                // and the outer edges (§7 — the generator adds the clearance).
                MotifGroundView(seed: 0x4A5E_0F05,
                                exclusions: [CGRect(x: 8, y: 56,
                                                    width: geo.size.width - 16,
                                                    height: geo.size.height - 56)])
            }
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Header: spot plate + framed Lilita title (Rule 4 — the
                    // game name never sits naked on the ground, and Shrikhand
                    // is reserved for the app lockup, §4).
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            Circle().fill(AppTheme.Retro.panel)
                            Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
                            RetroSpotIllustration(kind: .bubbleFive)
                                .frame(width: 64, height: 64)
                        }
                        .frame(width: 84, height: 84)

                        Text("Name Five")
                            .font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
                            .foregroundColor(AppTheme.Retro.ink)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.xs)
                            .retroPanel(Name5Style.accent)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                                    .fill(AppTheme.Retro.ink)
                                    .offset(x: AppTheme.Retro.shadowOffset,
                                            y: AppTheme.Retro.shadowOffset)
                            )
                            .rotationEffect(.degrees(-1))

                        Text("Race against the clock to name 5 things")
                            .font(AppTheme.Typography.secondary)
                            .foregroundColor(AppTheme.Retro.panelText)
                            .multilineTextAlignment(.center)
                            .retroLozenge()
                            .rotationEffect(.degrees(0.8))
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    // Social Context Selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        sectionLabel("Playing with...")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                            ForEach(SocialContext.allCases, id: \.self) { context in
                                ContextCard(
                                    context: context,
                                    isSelected: viewModel.socialContext == context
                                ) {
                                    viewModel.updateConfiguration(context: context)
                                }
                            }
                        }
                    }

                    // Age Group Selection (show only for family or all ages)
                    if viewModel.socialContext == .family {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                            sectionLabel("Age Group")

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.md) {
                                ForEach(AgeGroup.allCases, id: \.self) { age in
                                    AgeGroupCard(
                                        ageGroup: age,
                                        isSelected: viewModel.ageGroup == age
                                    ) {
                                        viewModel.updateConfiguration(age: age)
                                    }
                                }
                            }
                        }
                    }

                    // Difficulty Selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        sectionLabel("Difficulty")

                        HStack(spacing: AppTheme.Spacing.md) {
                            DifficultyToggle(
                                difficulty: .easy,
                                isSelected: viewModel.selectedDifficulties.contains(.easy)
                            ) {
                                viewModel.toggleDifficulty(.easy)
                            }

                            DifficultyToggle(
                                difficulty: .medium,
                                isSelected: viewModel.selectedDifficulties.contains(.medium)
                            ) {
                                viewModel.toggleDifficulty(.medium)
                            }

                            DifficultyToggle(
                                difficulty: .hard,
                                isSelected: viewModel.selectedDifficulties.contains(.hard)
                            ) {
                                viewModel.toggleDifficulty(.hard)
                            }
                        }
                    }

                    // Timer Settings
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Text("Timer")
                                .font(AppTheme.Retro.Typography.cardTitle)
                                .foregroundColor(AppTheme.Retro.panelText)

                            Spacer()

                            // Keep the system control, tint it (§3 recipe).
                            Toggle("", isOn: $viewModel.timerEnabled)
                                .labelsHidden()
                                .tint(Name5Style.accent)
                        }

                        if viewModel.timerEnabled {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    ForEach([15, 30, 45, 60], id: \.self) { duration in
                                        RetroCategoryPill(
                                            title: "\(duration)s",
                                            color: Name5Style.accent,
                                            isSelected: viewModel.timerDuration == duration
                                        ) {
                                            viewModel.updateConfiguration(duration: duration)
                                        }
                                    }
                                }

                                Text(timerDescription(for: viewModel.timerDuration))
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.Retro.cocoa)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .retroCard()

                    // Category Selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Categories")
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(AppTheme.Retro.panelText)

                        Text("Select which categories to include")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.Retro.cocoa)

                        // Selection pills wear the single screen accent (§3
                        // recipe); semantic variety lives on the chips inside
                        // the prompt cards.
                        FlowLayout(spacing: 10) {
                            ForEach(PromptCategory.allCases, id: \.self) { category in
                                RetroCategoryPill(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    color: Name5Style.accent,
                                    isSelected: viewModel.selectedCategories.contains(category)
                                ) {
                                    viewModel.toggleCategory(category)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .retroCard()

                    // Player Count
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Number of Players")
                            .font(AppTheme.Retro.Typography.cardTitle)
                            .foregroundColor(AppTheme.Retro.panelText)

                        HStack {
                            Text("\(viewModel.playerCount) \(viewModel.playerCount == 1 ? "Player" : "Players")")
                                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                                .foregroundColor(AppTheme.Retro.panelText)

                            Spacer()

                            // 44pt accent circles with bold ink glyphs (§3).
                            HStack(spacing: AppTheme.Spacing.md) {
                                Button {
                                    if viewModel.playerCount > 1 {
                                        viewModel.updateConfiguration(players: viewModel.playerCount - 1)
                                    }
                                } label: {
                                    stepperGlyph("minus", enabled: viewModel.playerCount > 1)
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.playerCount <= 1)

                                Button {
                                    if viewModel.playerCount < 20 {
                                        viewModel.updateConfiguration(players: viewModel.playerCount + 1)
                                    }
                                } label: {
                                    stepperGlyph("plus", enabled: viewModel.playerCount < 20)
                                }
                                .buttonStyle(.plain)
                                .disabled(viewModel.playerCount >= 20)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .retroCard()

                    // Available Prompts Info
                    if !viewModel.availablePrompts.isEmpty {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            Name5StatusBadge(systemImage: "checkmark",
                                             color: Name5Style.successColor,
                                             diameter: 20)
                            Text("\(viewModel.availablePrompts.count) prompts available")
                                .font(AppTheme.Typography.secondary)
                                .foregroundColor(AppTheme.Retro.panelText)
                        }
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .retroLozenge()
                    }

                    // Start Button
                    RetroPrimaryButton(title: "Quick Play", icon: "play.fill",
                                       accent: Name5Style.accent) {
                        viewModel.startGame()
                    }
                    .disabled(!viewModel.canStart)
                    .opacity(viewModel.canStart ? 1.0 : 0.6)
                    .padding(.bottom, AppTheme.Spacing.lg)
                }
                .padding()
            }
            .scrollIndicators(.hidden)
        }
    }

    /// Section labels sit on the ground, so they ride a cream lozenge rather
    /// than floating naked over the motif field (§9).
    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(AppTheme.Retro.Typography.heading(18, relativeTo: .title3))
            .foregroundColor(AppTheme.Retro.panelText)
            .retroLozenge()
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func stepperGlyph(_ systemImage: String, enabled: Bool) -> some View {
        Image(systemName: systemImage)
            .font(AppTheme.Typography.cardTitle.weight(.black))
            .foregroundColor(AppTheme.Retro.ink)
            .frame(width: 44, height: 44)
            .background(Circle().fill(enabled ? Name5Style.accent : AppTheme.Retro.panel))
            .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
            .opacity(enabled ? 1 : 0.4)
    }

    private func timerDescription(for duration: Int) -> String {
        switch duration {
        case 15: return "Sprint mode — fast and frantic"
        case 30: return "Standard — a good challenge"
        case 45: return "Relaxed — plenty of time to think"
        case 60: return "Easy going — no rush at all"
        default: return "\(duration) seconds per round"
        }
    }
}

// MARK: - Difficulty Toggle
struct DifficultyToggle: View {
    let difficulty: Difficulty
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.xs) {
                // The ramp color rides on stars inside a cream lozenge, so it
                // stays legible whether the tile is lilac or cream (§8).
                HStack(spacing: 2) {
                    ForEach(0..<Name5Style.difficultyStars(difficulty), id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(AppTheme.Typography.tabLabel)
                            .foregroundColor(Name5Style.difficultyColor(difficulty))
                    }
                }
                .padding(.vertical, 2)
                .retroLozenge()

                Text(difficulty.rawValue)
                    .font(AppTheme.Retro.Typography.heading(17))
                    .foregroundColor(AppTheme.Retro.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .retroPanel(isSelected ? Name5Style.accent : AppTheme.Retro.panel,
                        cornerRadius: AppTheme.Retro.Radius.inner)
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
    }
}

// MARK: - Context Card
struct ContextCard: View {
    let context: SocialContext
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: context.icon)
                    .font(AppTheme.Typography.screenTitle)
                    .foregroundColor(AppTheme.Retro.ink)

                VStack(spacing: AppTheme.Spacing.xs) {
                    Text(context.rawValue)
                        .font(AppTheme.Retro.Typography.heading(17))
                        .foregroundColor(AppTheme.Retro.ink)

                    // §8: the description is body copy, so it rides a cream
                    // lozenge instead of sitting on the lilac fill.
                    Text(context.description)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Retro.panelText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.vertical, 2)
                        .retroLozenge()
                }
            }
            .padding(AppTheme.Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 140)
            .retroPanel(isSelected ? Name5Style.accent : AppTheme.Retro.panel)
        }
        .buttonStyle(RetroRaisedButtonStyle())
    }
}

// MARK: - Age Group Card
struct AgeGroupCard: View {
    let ageGroup: AgeGroup
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: ageGroup.icon)
                    .font(AppTheme.Typography.cardTitle)
                    .foregroundColor(AppTheme.Retro.ink)

                Text(ageGroup.rawValue)
                    .font(AppTheme.Retro.Typography.heading(16, relativeTo: .subheadline))
                    .foregroundColor(AppTheme.Retro.ink)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(AppTheme.Typography.caption.weight(.black))
                        .foregroundColor(AppTheme.Retro.ink)
                }
            }
            .padding(AppTheme.Spacing.sm + 2)
            .retroPanel(isSelected ? Name5Style.accent : AppTheme.Retro.panel,
                        cornerRadius: AppTheme.Retro.Radius.inner)
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: AppTheme.Retro.Radius.inner))
    }
}
