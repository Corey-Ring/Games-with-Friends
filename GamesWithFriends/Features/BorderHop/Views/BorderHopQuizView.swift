import SwiftUI

struct BorderHopQuizView: View {
    let question: QuizQuestion
    let eliminatedChoices: Set<String>
    let strikeCount: Int
    let onAnswer: (String) -> Void
    let countryName: String

    private let theme = GameTheme.borderHop
    private let choiceLabels = ["A", "B", "C", "D"]

    @State private var selectedCorrect: String? = nil
    @State private var shakingChoice: String? = nil
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 4) {
                    Text(countryName)
                        .font(AppTheme.Typography.subsectionHeader)
                        .foregroundColor(.white)

                    Text("Which fact is true?")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.6))

                    // Strike indicators on their own row
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
                .padding(.top, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.sm)

                // Choices — ViewThatFits prevents greedy ScrollView from leaving empty space
                ViewThatFits(in: .vertical) {
                    choicesStack
                    ScrollView(.vertical, showsIndicators: false) {
                        choicesStack
                    }
                    .frame(maxHeight: UIScreen.main.bounds.height * 0.68)
                }

                // Safe area spacer at bottom
                Color.clear.frame(height: 20)
            }
            .background(
                // Only round the top corners so the panel connects flush to the screen edge
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(.ultraThinMaterial)
                    .padding(.bottom, -AppTheme.Radius.large)
            )
            .clipped()
            .padding(.horizontal, 12)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var choicesStack: some View {
        VStack(spacing: 6) {
            ForEach(Array(question.choices.enumerated()), id: \.element) { index, fact in
                answerButton(for: fact, index: index)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    @ViewBuilder
    private func answerButton(for fact: String, index: Int) -> some View {
        let isEliminated = eliminatedChoices.contains(fact)
        let isCorrectReveal = selectedCorrect == fact
        let isShaking = shakingChoice == fact
        let label = isCorrectReveal ? "✓" : (index < choiceLabels.count ? choiceLabels[index] : "?")

        Button {
            guard !isEliminated && selectedCorrect == nil else { return }
            handleSelection(fact)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(buttonBackground(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal))
            .foregroundColor(buttonForeground(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal))
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(buttonBorder(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal), lineWidth: 1)
            )
        }
        .disabled(isEliminated || selectedCorrect != nil)
        .scaleEffect(isCorrectReveal ? 1.01 : 1.0)
        .offset(x: isShaking ? shakeOffset : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCorrectReveal)
    }

    private func handleSelection(_ fact: String) {
        if fact == question.correctFact {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedCorrect = fact
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onAnswer(fact)
            }
        } else {
            shakingChoice = fact
            withAnimation(.default) { shakeOffset = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 8)) { shakeOffset = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shakingChoice = nil }
            onAnswer(fact)
        }
    }

    // MARK: - Styling

    private func prefixColor(isEliminated: Bool, isCorrectReveal: Bool) -> Color {
        if isCorrectReveal { return AppTheme.success }
        if isEliminated { return .gray }
        return AppTheme.compassRose
    }

    private func buttonBackground(isEliminated: Bool, isCorrectReveal: Bool) -> some ShapeStyle {
        if isCorrectReveal { return AnyShapeStyle(AppTheme.success.opacity(0.12)) }
        if isEliminated { return AnyShapeStyle(AppTheme.error.opacity(0.08)) }
        return AnyShapeStyle(Color.white)
    }

    private func buttonForeground(isEliminated: Bool, isCorrectReveal: Bool) -> Color {
        if isEliminated { return .gray }
        return AppTheme.deepCharcoal
    }

    private func buttonBorder(isEliminated: Bool, isCorrectReveal: Bool) -> some ShapeStyle {
        if isCorrectReveal { return AnyShapeStyle(AppTheme.success) }
        if isEliminated { return AnyShapeStyle(Color.gray.opacity(0.2)) }
        return AnyShapeStyle(AppTheme.compassRose.opacity(0.4))
    }
}
