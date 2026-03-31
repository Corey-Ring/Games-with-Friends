import SwiftUI

struct BorderHopQuizView: View {
    let question: QuizQuestion
    let eliminatedChoices: Set<String>
    let strikeCount: Int
    let onAnswer: (String) -> Void
    let countryName: String
    let graph: CountryGraph

    private let theme = GameTheme.borderHop
    private let choiceLabels = ["A", "B", "C", "D"]

    @State private var selectedCorrect: String? = nil
    @State private var shakingChoice: String? = nil
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                header

                ViewThatFits(in: .vertical) {
                    choicesStack
                    ScrollView(.vertical, showsIndicators: false) {
                        choicesStack
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.68)
                }

                Color.clear.frame(height: 20)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(.ultraThinMaterial)
                    .padding(.bottom, -AppTheme.Radius.large)
            )
            .clipped()
            .padding(.horizontal, 12)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        switch question.type {
        case .funFact:
            factHeader
        case .flagIdentification:
            flagHeader
        }
    }

    private var factHeader: some View {
        VStack(spacing: 4) {
            Text(countryName)
                .font(AppTheme.Typography.subsectionHeader)
                .foregroundColor(.white)

            Text("Which fact is true?")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.white.opacity(0.6))

            strikeRow
        }
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private var flagHeader: some View {
        VStack(spacing: 4) {
            Text(countryName)
                .font(AppTheme.Typography.subsectionHeader)
                .foregroundColor(.white)

            Text("Select the correct flag")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.white.opacity(0.6))

            strikeRow
        }
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private var strikeRow: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(index < strikeCount ? AppTheme.error : .clear)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(
                                index < strikeCount ? AppTheme.error : Color.white.opacity(0.35),
                                lineWidth: 1.5
                            )
                    )
                    .animation(.easeIn(duration: 0.2), value: strikeCount)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Choices

    @ViewBuilder
    private var choicesStack: some View {
        switch question.type {
        case .funFact:
            factChoicesStack
        case .flagIdentification:
            flagChoicesStack
        }
    }

    private var factChoicesStack: some View {
        VStack(spacing: 6) {
            ForEach(Array((question.factChoices ?? []).enumerated()), id: \.element) { index, fact in
                factAnswerButton(for: fact, index: index)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var flagChoicesStack: some View {
        VStack(spacing: 6) {
            ForEach(Array((question.countryChoices ?? []).enumerated()), id: \.element) { index, countryId in
                flagAnswerButton(for: countryId, index: index)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Answer Buttons

    @ViewBuilder
    private func factAnswerButton(for fact: String, index: Int) -> some View {
        let isEliminated = eliminatedChoices.contains(fact)
        let isCorrectReveal = selectedCorrect == fact
        let isShaking = shakingChoice == fact
        let label = isCorrectReveal ? "✓" : (index < choiceLabels.count ? choiceLabels[index] : "?")

        Button {
            guard !isEliminated && selectedCorrect == nil else { return }
            handleSelection(fact, correctValue: question.correctFact ?? "")
        } label: {
            HStack(alignment: .top, spacing: 4) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(prefixColor(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal))
                    .frame(width: 18, alignment: .leading)

                Text(fact)
                    .font(AppTheme.Typography.caption)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonChrome(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal)
        }
        .disabled(isEliminated || selectedCorrect != nil)
        .scaleEffect(isCorrectReveal ? 1.01 : 1.0)
        .offset(x: isShaking ? shakeOffset : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCorrectReveal)
    }

    @ViewBuilder
    private func flagAnswerButton(for countryId: String, index: Int) -> some View {
        let isEliminated = eliminatedChoices.contains(countryId)
        let isCorrectReveal = selectedCorrect == countryId
        let isShaking = shakingChoice == countryId
        let emoji = CountryFlagProvider.flag(for: countryId) ?? "🏳️"
        let name = graph.country(for: countryId)?.name ?? countryId

        Button {
            guard !isEliminated && selectedCorrect == nil else { return }
            handleSelection(countryId, correctValue: question.countryId)
        } label: {
            if isCorrectReveal {
                Text("✓")
                    .font(.title.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .buttonChrome(isEliminated: false, isCorrectReveal: true)
            } else if isEliminated {
                // Show flag + country name so the user knows what they wrongly picked
                VStack(spacing: 2) {
                    Text(emoji)
                        .font(.system(size: 40))
                    Text(name)
                        .font(AppTheme.Typography.caption)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, minHeight: 64)
                .buttonChrome(isEliminated: true, isCorrectReveal: false)
            } else {
                Text(emoji)
                    .font(.system(size: 52))
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .buttonChrome(isEliminated: false, isCorrectReveal: false)
            }
        }
        .disabled(isEliminated || selectedCorrect != nil)
        .scaleEffect(isCorrectReveal ? 1.03 : 1.0)
        .offset(x: isShaking ? shakeOffset : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCorrectReveal)
    }

    // MARK: - Interaction

    private func handleSelection(_ answer: String, correctValue: String) {
        if answer == correctValue {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedCorrect = answer
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onAnswer(answer)
            }
        } else {
            shakingChoice = answer
            withAnimation(.default) { shakeOffset = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 8)) { shakeOffset = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shakingChoice = nil }
            onAnswer(answer)
        }
    }

    // MARK: - Styling Helpers

    private func prefixColor(isEliminated: Bool, isCorrectReveal: Bool) -> Color {
        if isCorrectReveal { return AppTheme.success }
        if isEliminated { return .gray }
        return AppTheme.compassRose
    }
}

// MARK: - Shared Button Chrome Modifier

private struct ButtonChromeModifier: ViewModifier {
    let isEliminated: Bool
    let isCorrectReveal: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(border, lineWidth: 1)
            )
    }

    private var background: some ShapeStyle {
        if isCorrectReveal { return AnyShapeStyle(AppTheme.success.opacity(0.12)) }
        if isEliminated { return AnyShapeStyle(AppTheme.error.opacity(0.08)) }
        return AnyShapeStyle(Color.white)
    }

    private var foreground: Color {
        if isEliminated { return .gray }
        return AppTheme.deepCharcoal
    }

    private var border: some ShapeStyle {
        if isCorrectReveal { return AnyShapeStyle(AppTheme.success) }
        if isEliminated { return AnyShapeStyle(Color.gray.opacity(0.2)) }
        return AnyShapeStyle(AppTheme.compassRose.opacity(0.4))
    }
}

private extension View {
    func buttonChrome(isEliminated: Bool, isCorrectReveal: Bool) -> some View {
        modifier(ButtonChromeModifier(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal))
    }
}
