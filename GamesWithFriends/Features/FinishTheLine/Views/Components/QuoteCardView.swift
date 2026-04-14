//
//  QuoteCardView.swift
//  GamesWithFriends
//

import SwiftUI

/// The headline card players read aloud. Renders the setup string with the
/// blank visually called out and flashes on a correct answer.
struct QuoteCardView: View {
    let quote: Quote
    let accentColor: Color
    let isFlashing: Bool

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Category pill — gives players a scan-hint
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: quote.category.iconName)
                    .font(.caption2)
                Text(quote.category.displayName.uppercased())
                    .font(AppTheme.Typography.footnote.weight(.bold))
                    .tracking(1.2)
            }
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule().fill(accentColor)
            )

            // Quote body — styled with a called-out blank
            QuoteBodyText(setup: quote.setup, accentColor: accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .overlay(accentColor.opacity(0.3))

            // Source line
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(accentColor.opacity(0.65))
                Text(quote.source)
                    .font(AppTheme.Typography.detail.italic())
                    .foregroundColor(AppTheme.mediumGray)
                    .lineLimit(2)
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .fill(colorScheme == .dark ? AppTheme.darkCard : AppTheme.pureWhite)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                .stroke(isFlashing ? AppTheme.success : accentColor.opacity(0.18), lineWidth: isFlashing ? 4 : 1.5)
        )
        .shadow(
            color: isFlashing ? AppTheme.success.opacity(0.4) : accentColor.opacity(0.18),
            radius: isFlashing ? 24 : 12,
            x: 0,
            y: 6
        )
        .scaleEffect(isFlashing && !reduceMotion ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFlashing)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quote from \(quote.source). Complete the line: \(accessibleSetup)")
    }

    private var accessibleSetup: String {
        quote.setup.replacingOccurrences(of: "___", with: "blank")
    }
}

// MARK: - Quote body text with styled blank

/// Renders the setup string with the ___ token replaced by a stylized pill so
/// the blank reads at a glance and matches the accent color.
private struct QuoteBodyText: View {
    let setup: String
    let accentColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            styledText
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(AppTheme.deepCharcoal)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Uses AttributedString with a colored underline on the blank token.
    private var styledText: Text {
        let parts = setup.components(separatedBy: "___")
        var result = Text("")
        for (index, part) in parts.enumerated() {
            result = result + Text(part)
            if index < parts.count - 1 {
                // The styled blank: underscored in accent color, same weight.
                result = result + Text("______")
                    .foregroundColor(accentColor)
                    .underline()
            }
        }
        return result
    }
}
