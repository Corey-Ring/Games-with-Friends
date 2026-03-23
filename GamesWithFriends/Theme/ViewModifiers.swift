import SwiftUI

// MARK: - Game Card Modifier
struct GameCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(colorScheme == .dark ? AppTheme.darkCard : AppTheme.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .shadow(
                color: colorScheme == .dark ? Color.white.opacity(0.04) : AppTheme.Shadow.cardColor,
                radius: AppTheme.Shadow.cardRadius,
                x: AppTheme.Shadow.cardX,
                y: AppTheme.Shadow.cardY
            )
    }
}

extension View {
    func gameCard() -> some View {
        modifier(GameCardModifier())
    }
}

// MARK: - Accent Pill Modifier
struct AccentPillModifier: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(AppTheme.Typography.pillLabel)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.medium))
    }
}

extension View {
    func accentPill(color: Color) -> some View {
        modifier(AccentPillModifier(color: color))
    }
}

// MARK: - Pressable Button Style
struct PressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(reduceMotion ? 1.0 : (configuration.isPressed ? 0.97 : 1.0))
            .animation(reduceMotion ? nil : AppTheme.Animation.buttonPress, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

extension View {
    func pressable() -> some View {
        self.buttonStyle(PressableButtonStyle())
    }
}

// MARK: - Staggered Appear
struct StaggeredAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : (reduceMotion ? 0 : 20))
            .onAppear {
                if reduceMotion {
                    appeared = true
                } else {
                    withAnimation(
                        .easeOut(duration: AppTheme.Animation.cardEnterDuration)
                        .delay(Double(index) * AppTheme.Animation.cardEnterDelay)
                    ) {
                        appeared = true
                    }
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}
