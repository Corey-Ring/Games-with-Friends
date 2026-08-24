//
//  QuoteCardView.swift
//  GamesWithFriends
//

import SwiftUI

/// The headline card players read aloud. The source is hidden while the card
/// is live (no spoilers — that's the tip-of-tongue tension), fading in only as
/// a lifeline hint or once the card resolves. On resolution the blank fills
/// with the missing word — grass for a correct answer, tangerine for the skip
/// "groan reveal" — and the attribution slides in underneath.
struct QuoteCardView: View {
    let quote: Quote
    let accentColor: Color
    let resolution: FinishTheLineViewModel.CardResolution?
    let showSource: Bool
    let isOnFire: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Category chip — gives players a scan-hint. Semantic variety is
            // allowed on chips inside a cream card (playbook §3), so each
            // category wears its own candy hue with an ink outline.
            HStack(spacing: AppTheme.Spacing.xs) {
                Image(systemName: quote.category.iconName)
                    .font(.caption2)
                Text(quote.category.displayName.uppercased())
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .tracking(1.2)
            }
            .foregroundColor(FinishTheLineStyle.chipTextColor(on: categoryFill))
            .retroLozenge(categoryFill)

            // Quote body — blank fills in with the answer on resolution
            QuoteBodyText(
                setup: quote.setup,
                accentColor: accentColor,
                fill: fillTreatment
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            // Source line — hidden until resolved or hint-revealed
            if showSource {
                Rectangle()
                    .fill(AppTheme.Retro.ink)
                    .frame(height: 2)

                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: resolution == nil ? "lightbulb.fill" : "quote.opening")
                        .font(.caption)
                        .foregroundColor(AppTheme.Retro.cocoa)
                    Text(quote.source)
                        .font(AppTheme.Typography.detail.italic())
                        .foregroundColor(AppTheme.Retro.cocoa)
                        .lineLimit(2)
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(AppTheme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .fill(AppTheme.Retro.panel)
        )
        // Rule 1: uniform ink outline always; the resolution/ember state rides
        // a second inset rule so the card can shout without losing its line.
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeHeavy)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card - 4)
                .inset(by: 5)
                .stroke(stateRuleColor, lineWidth: stateRuleWidth)
        )
        // Rule 2: hard offset shadow, never a colored blur.
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.card)
                .fill(AppTheme.Retro.ink)
                .offset(x: AppTheme.Retro.shadowOffset, y: AppTheme.Retro.shadowOffset)
        )
        .scaleEffect(resolution == .correct && !reduceMotion ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: resolution)
        .animation(.easeOut(duration: 0.3), value: showSource)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
    }

    // MARK: - Resolution styling

    private var categoryFill: Color {
        FinishTheLineStyle.categoryColor(quote.category)
    }

    private var fillTreatment: QuoteBodyText.Fill? {
        switch resolution {
        case .correct:
            return QuoteBodyText.Fill(word: quote.missingWord,
                                      color: FinishTheLineStyle.correctColor)
        case .skipped:
            return QuoteBodyText.Fill(word: quote.missingWord,
                                      color: FinishTheLineStyle.skippedColor)
        case nil:
            return nil
        }
    }

    /// Inner state rule: grass on a correct answer, tangerine on a skip, the
    /// tangerine ember while On Fire, and clear otherwise.
    private var stateRuleColor: Color {
        switch resolution {
        case .correct:
            return FinishTheLineStyle.correctColor
        case .skipped:
            return FinishTheLineStyle.skippedColor
        case nil:
            return isOnFire ? FinishTheLineStyle.streakOnFireColor : .clear
        }
    }

    private var stateRuleWidth: CGFloat {
        switch resolution {
        case .correct: return 4
        case .skipped: return 3
        case nil: return isOnFire ? 3 : 0
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

/// Renders the setup string with the ___ token replaced by a stylized blank so
/// it reads at a glance — or, once resolved, by the missing word in the
/// resolution color. The blank logic is unchanged; only the face and colors
/// move to the retro tokens.
private struct QuoteBodyText: View {
    struct Fill {
        let word: String
        let color: Color
    }

    let setup: String
    let accentColor: Color
    let fill: Fill?

    /// Scales with Dynamic Type — this is the primary readable game content,
    /// not a decorative display element. The old `@ScaledMetric` is replaced by
    /// `relativeTo:`, the §4-prescribed scaling hook for the display faces;
    /// stacking both would scale the size twice.
    private let quoteSize: CGFloat = 30

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            styledText
                // §4: display-scale content goes Lilita One, ink on cream.
                .font(AppTheme.Retro.Typography.heading(quoteSize, relativeTo: .title))
                .foregroundColor(AppTheme.Retro.panelText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .minimumScaleFactor(0.7)
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
