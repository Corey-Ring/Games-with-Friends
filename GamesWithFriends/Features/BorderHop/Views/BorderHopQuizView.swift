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
    @State private var choicesRevealed: Set<Int> = []
    @State private var headerGlowPhase: CGFloat = 0
    @State private var showCelebration: Bool = false
    @State private var celebrationParticles: [CelebrationParticle] = []

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                header

                ZStack {
                    ViewThatFits(in: .vertical) {
                        choicesStack
                        ScrollView(.vertical, showsIndicators: false) {
                            choicesStack
                        }
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.68)
                    }

                    if showCelebration {
                        celebrationOverlay
                            .allowsHitTesting(false)
                    }
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
        .onAppear(perform: handleAppear)
    }

    // MARK: - Header

    @ViewBuilder
    private var header: some View {
        switch question.type {
        case .funFact:
            factHeader
        case .flagIdentification:
            flagHeader
        case .export:
            exportHeader
        }
    }

    private var factHeader: some View {
        VStack(spacing: 4) {
            pulsingCountryName

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
            pulsingCountryName

            Text("Select the correct flag")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.white.opacity(0.6))

            strikeRow
        }
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private var exportHeader: some View {
        VStack(spacing: 4) {
            pulsingCountryName

            Text("What are the top 5 exports?")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.white.opacity(0.6))

            strikeRow
        }
        .padding(.top, AppTheme.Spacing.md)
        .padding(.bottom, AppTheme.Spacing.sm)
    }

    private var pulsingCountryName: some View {
        Text(countryName)
            .font(AppTheme.Typography.subsectionHeader)
            .foregroundColor(.white)
            .scaleEffect(1.0 + headerGlowPhase * 0.02)
            .shadow(
                color: theme.accentColor.opacity(0.6 * headerGlowPhase),
                radius: 8 + headerGlowPhase * 6
            )
            .shadow(
                color: theme.accentColor.opacity(0.3 * headerGlowPhase),
                radius: 16 + headerGlowPhase * 8
            )
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
        case .funFact:
            factChoicesStack
        case .flagIdentification:
            flagChoicesStack
        case .export:
            exportChoicesStack
        }
    }

    private var factChoicesStack: some View {
        VStack(spacing: 6) {
            ForEach(Array((question.factChoices ?? []).enumerated()), id: \.element) { index, fact in
                factAnswerButton(for: fact, index: index)
                    .opacity(choicesRevealed.contains(index) ? 1 : 0)
                    .offset(y: choicesRevealed.contains(index) ? 0 : 24)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: choicesRevealed)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var flagChoicesStack: some View {
        VStack(spacing: 6) {
            ForEach(Array((question.countryChoices ?? []).enumerated()), id: \.element) { index, countryId in
                flagAnswerButton(for: countryId, index: index)
                    .opacity(choicesRevealed.contains(index) ? 1 : 0)
                    .offset(y: choicesRevealed.contains(index) ? 0 : 24)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: choicesRevealed)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.sm)
    }

    private var exportChoicesStack: some View {
        VStack(spacing: 6) {
            ForEach(Array((question.countryChoices ?? []).enumerated()), id: \.element) { index, countryId in
                exportAnswerButton(for: countryId, index: index)
                    .opacity(choicesRevealed.contains(index) ? 1 : 0)
                    .offset(y: choicesRevealed.contains(index) ? 0 : 24)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: choicesRevealed)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
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

    @ViewBuilder
    private func exportAnswerButton(for countryId: String, index: Int) -> some View {
        let isEliminated = eliminatedChoices.contains(countryId)
        let isCorrectReveal = selectedCorrect == countryId
        let isShaking = shakingChoice == countryId
        let label = isCorrectReveal ? "✓" : (index < choiceLabels.count ? choiceLabels[index] : "?")

        // Change to 3 to switch to top-3 mode (also update the header text).
        let exportsToShow = 5
        let exports = (CountryExportProvider.exports(for: countryId) ?? []).prefix(exportsToShow)
        let countryName = graph.country(for: countryId)?.name ?? countryId
        let flagEmoji = CountryFlagProvider.flag(for: countryId) ?? "🏳️"

        Button {
            guard !isEliminated && selectedCorrect == nil else { return }
            handleSelection(countryId, correctValue: question.countryId)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                if isEliminated {
                    HStack(spacing: 6) {
                        Text(flagEmoji)
                            .font(.system(size: 18))
                        Text(countryName)
                            .font(AppTheme.Typography.footnote.weight(.semibold))
                            .foregroundColor(.gray)
                    }
                }

                HStack(alignment: .center, spacing: 10) {
                    Text(label)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(prefixColor(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal))
                        .frame(width: 24, alignment: .leading)

                    HStack(alignment: .top, spacing: 8) {
                        let exportsArray = Array(exports)
                        let splitIndex = (exportsArray.count + 1) / 2
                        let firstColumn = Array(exportsArray.prefix(splitIndex))
                        let secondColumn = Array(exportsArray.dropFirst(splitIndex))

                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(Array(firstColumn.enumerated()), id: \.offset) { i, commodity in
                                Text("\(i + 1). \(commodity.localizedCapitalized)")
                                    .font(AppTheme.Typography.footnote)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(Array(secondColumn.enumerated()), id: \.offset) { i, commodity in
                                Text("\(i + splitIndex + 1). \(commodity.localizedCapitalized)")
                                    .font(AppTheme.Typography.footnote)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonChrome(isEliminated: isEliminated, isCorrectReveal: isCorrectReveal)
        }
        .disabled(isEliminated || selectedCorrect != nil)
        .scaleEffect(isCorrectReveal ? 1.01 : 1.0)
        .offset(x: isShaking ? shakeOffset : 0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCorrectReveal)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isEliminated)
    }

    // MARK: - Interaction

    private func handleSelection(_ answer: String, correctValue: String) {
        if answer == correctValue {
            triggerCelebration()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                selectedCorrect = answer
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
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

    // MARK: - Lifecycle

    private func handleAppear() {
        if reduceMotion {
            // Reveal all choices immediately, skip pulsing glow
            choicesRevealed = Set(0..<8)
            return
        }

        // Header glow pulse
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            headerGlowPhase = 1
        }

        // Staggered choice entrance — 150ms initial delay, then 120ms between each
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15 + Double(i) * 0.12) {
                _ = withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    choicesRevealed.insert(i)
                }
            }
        }
    }

    // MARK: - Celebration

    private func triggerCelebration() {
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
