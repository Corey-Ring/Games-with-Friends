//
//  QuoteCardView.swift
//  GamesWithFriends
//

import SwiftUI

/// The headline card players read aloud. The source is hidden while the card
/// is live (no spoilers — that's the tip-of-tongue tension), fading in only as
/// a lifeline hint or once the card resolves. On resolution the blank fills
/// with the missing word — green for a correct answer, amber for the skip
/// "groan reveal" — and the attribution slides in underneath.
struct QuoteCardView: View {
    let quote: Quote
    let accentColor: Color
    let resolution: FinishTheLineViewModel.CardResolution?
    let showSource: Bool
    let isOnFire: Bool

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

            // Quote body — blank fills in with the answer on resolution
            QuoteBodyText(
                setup: quote.setup,
                accentColor: accentColor,
                fill: fillTreatment
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            // Source line — hidden until resolved or hint-revealed
            if showSource {
                Divider()
                    .overlay(accentColor.opacity(0.3))

                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: resolution == nil ? "lightbulb.fill" : "quote.opening")
                        .font(.caption)
                        .foregroundColor(accentColor.opacity(0.65))
                    Text(quote.source)
                        .font(AppTheme.Typography.detail.italic())
                        .foregroundColor(AppTheme.mediumGray)
                        .lineLimit(2)
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
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
                .stroke(borderStyle, lineWidth: borderWidth)
        )
        .shadow(
            color: shadowColor,
            radius: resolution != nil ? 24 : 12,
            x: 0,
            y: 6
        )
        .scaleEffect(resolution == .correct && !reduceMotion ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: resolution)
        .animation(.easeOut(duration: 0.3), value: showSource)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Resolution styling

    private var fillTreatment: QuoteBodyText.Fill? {
        switch resolution {
        case .correct:
            return QuoteBodyText.Fill(word: quote.missingWord, color: AppTheme.success)
        case .skipped:
            return QuoteBodyText.Fill(word: quote.missingWord, color: AppTheme.warning)
        case nil:
            return nil
        }
    }

    private var borderStyle: AnyShapeStyle {
        switch resolution {
        case .correct:
            return AnyShapeStyle(AppTheme.success)
        case .skipped:
            return AnyShapeStyle(AppTheme.warning)
        case nil:
            if isOnFire {
                // Ember treatment matches the StreakBadge flame gradient.
                return AnyShapeStyle(
                    LinearGradient(
                        colors: [AppTheme.warning, AppTheme.brandOrange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            }
            return AnyShapeStyle(accentColor.opacity(0.18))
        }
    }

    private var borderWidth: CGFloat {
        switch resolution {
        case .correct: return 4
        case .skipped: return 3
        case nil: return isOnFire ? 2.5 : 1.5
        }
    }

    private var shadowColor: Color {
        switch resolution {
        case .correct: return AppTheme.success.opacity(0.4)
        case .skipped: return AppTheme.warning.opacity(0.35)
        case nil: return isOnFire ? AppTheme.brandOrange.opacity(0.3) : accentColor.opacity(0.18)
        }
    }

    private var accessibilityText: String {
        let line = quote.setup.replacingOccurrences(of: "___", with: "blank")
        switch resolution {
        case .correct:
            return "Correct! The word was \(quote.missingWord). From \(quote.source)."
        case .skipped:
            return "Skipped. The word was \(quote.missingWord). From \(quote.source)."
        case nil:
            if showSource {
                return "Hint: from \(quote.source). Complete the line: \(line)"
            }
            return "Complete the line: \(line)"
        }
    }
}

// MARK: - Quote body text with styled blank

/// Renders the setup string with the ___ token replaced by a stylized pill so
/// the blank reads at a glance — or, once resolved, by the missing word in the
/// resolution color.
private struct QuoteBodyText: View {
    struct Fill {
        let word: String
        let color: Color
    }

    let setup: String
    let accentColor: Color
    let fill: Fill?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            styledText
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(AppTheme.deepCharcoal)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var styledText: Text {
        let parts = setup.components(separatedBy: "___")
        var result = Text("")
        for (index, part) in parts.enumerated() {
            result = result + Text(part)
            if index < parts.count - 1 {
                if let fill {
                    // The reveal: the answer lands in the sentence.
                    result = result + Text(fill.word)
                        .foregroundColor(fill.color)
                        .underline()
                } else {
                    // The styled blank: underscored in accent color, same weight.
                    result = result + Text("______")
                        .foregroundColor(accentColor)
                        .underline()
                }
            }
        }
        return result
    }
}
