import SwiftUI

/// Individual clue tile component — cream chip with ink outline; the tier
/// rides on the order badge, icon, and (for the latest clue) the stroke.
struct ClueChipView: View {
    let clue: Clue
    let isLatest: Bool

    var body: some View {
        HStack(spacing: 6) {
            // Order badge — tier-colored disc with ink outline (§2 rule 1).
            Text("\(clue.orderNumber)")
                .font(AppTheme.Typography.tabLabel)
                .fontWeight(.bold)
                .foregroundStyle(CastingDirectorStyle.chipTextColor(on: tierAccentColor))
                .frame(width: 20, height: 20)
                .background(Circle().fill(tierAccentColor))
                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))

            // Type icon
            Image(systemName: clue.type.icon)
                .font(AppTheme.Typography.tabLabel)
                .foregroundStyle(AppTheme.Retro.panelText.opacity(0.7))

            // Clue text
            Text(clue.text)
                .font(AppTheme.Typography.caption)
                .fontWeight(isLatest ? .semibold : .regular)
                .foregroundStyle(AppTheme.Retro.panelText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .fill(AppTheme.Retro.panel)
        )
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .fill(AppTheme.Retro.ink)
                .offset(x: 3, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                .stroke(isLatest ? tierAccentColor : AppTheme.Retro.ink,
                        lineWidth: isLatest ? AppTheme.Retro.strokeHeavy : 2)
        )
        .opacity(isLatest ? 1.0 : 0.9)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Clue \(clue.orderNumber): \(clue.text)")
    }

    var tierAccentColor: Color {
        CastingDirectorStyle.tierColor(clue.tier)
    }
}
