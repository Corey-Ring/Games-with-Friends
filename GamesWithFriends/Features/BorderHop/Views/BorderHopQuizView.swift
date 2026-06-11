import SwiftUI

/// Border-crossing quiz sheet. Every question is built to be glanceable: a one-line stem
/// naming the country, short choices, and — once answered — a one-line takeaway that
/// states the fact worth remembering before the map returns.
struct BorderHopQuizView: View {
    let question: QuizQuestion
    let eliminatedChoices: Set<String>
    let strikeCount: Int
    let resolved: Bool
    let revealed: Bool
    let takeaway: LearnedFact?
    let onAnswer: (String) -> Void
    let countryName: String
    let graph: CountryGraph

    private let theme = GameTheme.borderHop
    private let choiceLabels = ["A", "B", "C", "D"]

    @State private var shakingChoice: String? = nil
    @State private var shakeOffset: CGFloat = 0
    @State private var choicesRevealed: Set<Int> = []
    @State private var showCelebration: Bool = false
    @State private var celebrationParticles: [CelebrationParticle] = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The value that counts as correct for this question type
    private var correctValue: String {
        switch question.type {
        case .funFact, .export:
            return question.correctFact ?? ""
        case .flagIdentification, .capital:
            return question.countryId
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                header

                ZStack {
                    choicesStack
                    if showCelebration {
                        celebrationOverlay
                            .allowsHitTesting(false)
                    }
                }

                takeawayFooter

                Color.clear.frame(height: AppTheme.Spacing.lg)
            }
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(.ultraThinMaterial)
                    .padding(.bottom, -AppTheme.Radius.large)
            )
            .clipped()
            .padding(.horizontal, AppTheme.Spacing.sm)
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear(perform: handleAppear)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(stem)
                .font(AppTheme.Typography.subsectionHeader)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, AppTheme.Spacing.md)

            if !resolved {
                Text("Answer to cross the border")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.6))
            }

            strikeRow
        }
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private var stem: String {
        switch question.type {
        case .funFact:
            return "Which is true of \(countryName)?"
        case .flagIdentification:
            return "Which flag belongs to \(countryName)?"
        case .export:
            return "What's \(countryName)'s #1 export?"
        case .capital:
            return "What's the capital of \(countryName)?"
        }
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
                    .scaleEffect(index < strikeCount ? 1.2 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: strikeCount)
            }
        }
        .padding(.top, 2)
    }

    // MARK: - Choices

    @ViewBuilder
    private var choicesStack: some View {
        switch question.type {
        case .flagIdentification:
            flagChoicesGrid
        case .funFact, .export:
            textChoicesStack(choices: question.factChoices ?? [])
        case .capital:
            textChoicesStack(choices: (question.countryChoices ?? []).map { $0 }, isCapital: true)
        }
    }

    /// Short text rows — used for facts, exports, and capitals
    private func textChoicesStack(choices: [String], isCapital: Bool = false) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(choices.enumerated()), id: \.element) { index, choice in
                textAnswerButton(for: choice, index: index, isCapital: isCapital)
                    .opacity(choicesRevealed.contains(index) ? 1 : 0)
                    .offset(y: choicesRevealed.contains(index) ? 0 : 24)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: choicesRevealed)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var flagChoicesGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 6), GridItem(.flexible(), spacing: 6)], spacing: 6) {
            ForEach(Array((question.countryChoices ?? []).enumerated()), id: \.element) { index, countryId in
                flagAnswerButton(for: countryId)
                    .opacity(choicesRevealed.contains(index) ? 1 : 0)
                    .offset(y: choicesRevealed.contains(index) ? 0 : 24)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: choicesRevealed)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    // MARK: - Answer Buttons

    @ViewBuilder
    private func textAnswerButton(for choice: String, index: Int, isCapital: Bool) -> some View {
        let isEliminated = eliminatedChoices.contains(choice)
        let isCorrectChoice = choice == correctValue
        let isCorrectReveal = resolved && isCorrectChoice
        let isShaking = shakingChoice == choice
        let label = isCorrectReveal ? "✓" : (index < choiceLabels.count ? choiceLabels[index] : "?")

        let display: String = {
            if isCapital {
                return graph.country(for: choice)?.capital ?? choice
            }
            if question.type == .export {
                return choice.localizedCapitalized
            }
            return choice
        }()

        Button {
            handleSelection(choice)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.sm) {
                Text(label)
                    .font(AppTheme.Typography.pillLabel)
                    .foregroundColor(prefixColor(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal))
                    .frame(width: 18, alignment: .leading)

                Text(display)
                    .font(AppTheme.Typography.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonChrome(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal, isRevealedAnswer: revealed && isCorrectChoice)
        }
        .disabled(isEliminated || resolved)
        .scaleEffect(isCorrectReveal ? 1.02 : 1.0)
        .offset(x: isShaking ? shakeOffset : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCorrectReveal)
    }

    @ViewBuilder
    private func flagAnswerButton(for countryId: String) -> some View {
        let isEliminated = eliminatedChoices.contains(countryId)
        let isCorrectChoice = countryId == correctValue
        let isCorrectReveal = resolved && isCorrectChoice
        let isShaking = shakingChoice == countryId
        let emoji = CountryFlagProvider.flag(for: countryId) ?? "🏳️"
        let name = graph.country(for: countryId)?.name ?? countryId

        Button {
            handleSelection(countryId)
        } label: {
            VStack(spacing: 2) {
                Text(emoji)
                    .font(.system(size: 44))
                // Reveal the country name once this choice is settled — every
                // eliminated flag teaches "that one was X", not just "wrong"
                if isEliminated || isCorrectReveal {
                    Text(name)
                        .font(AppTheme.Typography.caption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 72)
            .buttonChrome(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal, isRevealedAnswer: revealed && isCorrectChoice)
        }
        .disabled(isEliminated || resolved)
        .scaleEffect(isCorrectReveal ? 1.03 : 1.0)
        .offset(x: isShaking ? shakeOffset : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCorrectReveal)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEliminated)
    }

    // MARK: - Takeaway

    /// The one-line fact stamp shown after the question resolves — the thing to remember
    @ViewBuilder
    private var takeawayFooter: some View {
        if let takeaway {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: revealed ? "lightbulb.fill" : "checkmark.seal.fill")
                    .foregroundColor(revealed ? AppTheme.warning : AppTheme.success)

                Text(takeaway.text)
                    .font(AppTheme.Typography.secondary)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .fill((revealed ? AppTheme.warning : AppTheme.success).opacity(0.18))
            )
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.top, AppTheme.Spacing.xs)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: takeaway)
        }
    }

    // MARK: - Interaction

    private func handleSelection(_ answer: String) {
        guard !resolved, !eliminatedChoices.contains(answer) else { return }

        if answer == correctValue {
            triggerCelebration()
        } else {
            shakingChoice = answer
            withAnimation(.default) { shakeOffset = 10 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 8)) { shakeOffset = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shakingChoice = nil }
        }
        onAnswer(answer)
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        if reduceMotion {
            choicesRevealed = Set(0..<8)
            return
        }

        // Staggered choice entrance — 150ms initial delay, then 100ms between each
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.1) {
                _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    choicesRevealed.insert(i)
                }
            }
        }
    }

    // MARK: - Celebration

    private func triggerCelebration() {
        guard !reduceMotion else { return }
        let palette: [Color] = [
            AppTheme.success,
            AppTheme.medalGold,
            theme.accentColor,
            .white
        ]
        var particles: [CelebrationParticle] = []
        for i in 0..<20 {
            particles.append(
                CelebrationParticle(
                    id: i,
                    x: CGFloat.random(in: 0.1...0.9),
                    y: CGFloat.random(in: 0.2...0.8),
                    size: CGFloat.random(in: 4...10),
                    color: palette[i % palette.count],
                    angle: .degrees(Double.random(in: 0..<360)),
                    distance: CGFloat.random(in: 40...120),
                    delay: Double(i) * 0.02
                )
            )
        }
        celebrationParticles = particles
        showCelebration = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            showCelebration = false
        }
    }

    @ViewBuilder
    private var celebrationOverlay: some View {
        GeometryReader { geo in
            ZStack {
                CelebrationRipple()
                ForEach(celebrationParticles) { particle in
                    CelebrationDot(particle: particle)
                        .position(
                            x: particle.x * geo.size.width,
                            y: particle.y * geo.size.height
                        )
                }
            }
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
    /// Correct answer surfaced after 3 strikes — teaching styling, not celebration
    let isRevealedAnswer: Bool

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.medium)
                    .stroke(border, lineWidth: isCorrectReveal ? 1.5 : 1)
            )
    }

    private var background: some ShapeStyle {
        if isRevealedAnswer { return AnyShapeStyle(AppTheme.warning.opacity(0.15)) }
        if isCorrectReveal { return AnyShapeStyle(AppTheme.success.opacity(0.12)) }
        if isEliminated { return AnyShapeStyle(AppTheme.error.opacity(0.08)) }
        return AnyShapeStyle(Color.white)
    }

    private var foreground: Color {
        if isEliminated { return .gray }
        return AppTheme.deepCharcoal
    }

    private var border: some ShapeStyle {
        if isRevealedAnswer { return AnyShapeStyle(AppTheme.warning) }
        if isCorrectReveal { return AnyShapeStyle(AppTheme.success) }
        if isEliminated { return AnyShapeStyle(Color.gray.opacity(0.2)) }
        return AnyShapeStyle(AppTheme.compassRose.opacity(0.4))
    }
}

private extension View {
    func buttonChrome(isEliminated: Bool, isCorrectReveal: Bool, isRevealedAnswer: Bool) -> some View {
        modifier(ButtonChromeModifier(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal, isRevealedAnswer: isRevealedAnswer))
    }
}

// MARK: - Celebration Effects

private struct CelebrationParticle: Identifiable {
    let id: Int
    let x: CGFloat       // 0-1 normalized
    let y: CGFloat       // 0-1 normalized
    let size: CGFloat
    let color: Color
    let angle: Angle
    let distance: CGFloat
    let delay: Double
}

private struct CelebrationDot: View {
    let particle: CelebrationParticle
    @State private var animate: Bool = false

    var body: some View {
        let dx = animate ? cos(CGFloat(particle.angle.radians)) * particle.distance : 0
        let dy = animate ? sin(CGFloat(particle.angle.radians)) * particle.distance : 0

        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .offset(x: dx, y: dy)
            .scaleEffect(animate ? 0.1 : 1.0)
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.6).delay(particle.delay)) {
                    animate = true
                }
            }
    }
}

private struct CelebrationRipple: View {
    @State private var progress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let maxDim = max(geo.size.width, geo.size.height)
            let diameter = 20 + progress * (maxDim - 20)
            Circle()
                .stroke(AppTheme.success.opacity(0.6 * (1 - progress)), lineWidth: 3)
                .frame(width: diameter, height: diameter)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .onAppear {
                    withAnimation(.easeOut(duration: 0.6)) {
                        progress = 1
                    }
                }
        }
    }
}
