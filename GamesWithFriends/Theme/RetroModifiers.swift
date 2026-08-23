import SwiftUI
import UIKit

// ART_DIRECTION.md §5: ink outlines on everything, flat fills, hard offset
// shadows; press = shadow collapses while the element travels toward it.

// MARK: - Retro Panel (fill + ink outline, no shadow)
struct RetroPanelModifier: ViewModifier {
    var fill: Color
    var cornerRadius: CGFloat = AppTheme.Retro.Radius.card

    func body(content: Content) -> some View {
        content
            .background(RoundedRectangle(cornerRadius: cornerRadius).fill(fill))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
            )
    }
}

// MARK: - Retro Card (padded panel + static hard shadow) — non-interactive
// surfaces. Interactive elements use RetroRaisedButtonStyle instead so the
// shadow can collapse on press.
struct RetroCardModifier: ViewModifier {
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.md)
            .retroPanel(fill)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                    .fill(AppTheme.Retro.ink)
                    .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
            )
    }
}

// MARK: - Retro Lozenge (capsule pill; §2 rule 5 — text lives in devices)
struct RetroLozengeModifier: ViewModifier {
    var fill: Color

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
    }
}

// MARK: - Raised press style: hard shadow at 5,5 collapses to 2,2 while the
// element travels +3,+3 — pressing a physical button. Reduce Motion: no
// travel/shadow animation; haptic still fires (it isn't visual motion).
struct RetroRaisedButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = AppTheme.Retro.Radius.card
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && !reduceMotion
        let shadow = pressed ? AppTheme.Retro.shadowPressedOffset : AppTheme.Retro.shadowOffset
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppTheme.Retro.ink)
                    .offset(x: shadow, y: shadow)
            )
            .offset(x: pressed ? AppTheme.Retro.pressTravel : 0,
                    y: pressed ? AppTheme.Retro.pressTravel : 0)
            .animation(reduceMotion ? nil : AppTheme.Animation.cardTap, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
    }
}

extension View {
    func retroPanel(_ fill: Color = AppTheme.Retro.panel,
                    cornerRadius: CGFloat = AppTheme.Retro.Radius.card) -> some View {
        modifier(RetroPanelModifier(fill: fill, cornerRadius: cornerRadius))
    }

    func retroCard(_ fill: Color = AppTheme.Retro.panel) -> some View {
        modifier(RetroCardModifier(fill: fill))
    }

    func retroLozenge(_ fill: Color = AppTheme.Retro.panel) -> some View {
        modifier(RetroLozengeModifier(fill: fill))
    }
}
