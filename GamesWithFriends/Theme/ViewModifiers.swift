import SwiftUI

// MARK: - Game Card Modifier
struct GameCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .background(AppTheme.pureWhite)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .shadow(color: AppTheme.Shadow.cardColor, radius: AppTheme.Shadow.cardRadius, x: AppTheme.Shadow.cardX, y: AppTheme.Shadow.cardY)
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
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(AppTheme.Animation.buttonPress, value: configuration.isPressed)
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

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(
                    .easeOut(duration: AppTheme.Animation.cardEnterDuration)
                    .delay(Double(index) * AppTheme.Animation.cardEnterDelay)
                ) {
                    appeared = true
                }
            }
    }
}

extension View {
    func staggeredAppear(index: Int) -> some View {
        modifier(StaggeredAppearModifier(index: index))
    }
}
