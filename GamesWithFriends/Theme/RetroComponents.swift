import SwiftUI

// MARK: - Retro Primary Button (ART_DIRECTION §5; contrast rules §8)
/// Accent-filled CTA with ink text. §8: ink passes on mustard, bubblegum,
/// poolBlue, cream, tangerine. On plum pass `textColor: AppTheme.Retro.cream`
/// (the one accent dark enough for cream body text); on tomato/grass/lilac/
/// cornflower/berry keep ink text — cream is display-only there.
struct RetroPrimaryButton: View {
    let title: String
    var icon: String? = nil
    var accent: Color = AppTheme.Retro.tangerine
    var textColor: Color = AppTheme.Retro.ink
    let action: () -> Void
    @ScaledMetric(relativeTo: .headline) private var buttonHeight: CGFloat = 52

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(AppTheme.Retro.Typography.heading(17))
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .frame(minHeight: buttonHeight)
            .retroPanel(accent)
        }
        .buttonStyle(RetroRaisedButtonStyle())
    }
}

// MARK: - Retro Category Pill (replaces CategoryPill on migrated screens)
struct RetroCategoryPill: View {
    let title: String
    var icon: String? = nil
    let color: Color
    let isSelected: Bool
    /// §8: default ink works on light accents; pass cream for plum selection.
    var selectedTextColor: Color = AppTheme.Retro.ink
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
            }
            .font(AppTheme.Retro.Typography.pillLabel)
            .foregroundColor(isSelected ? selectedTextColor : AppTheme.Retro.panelText)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Capsule().fill(isSelected ? color : AppTheme.Retro.panel))
            .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth))
        }
        .buttonStyle(RetroRaisedButtonStyle(cornerRadius: 999))
    }
}

// MARK: - Showcase (visual verification surface for phase 1; not shipped in
// any navigation — reachable only via Xcode Previews)
#Preview("Retro Showcase") {
    ZStack {
        MotifGroundView(exclusions: [CGRect(x: 16, y: 80, width: 358, height: 620)])
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                Text("GAMES")
                    .font(AppTheme.Retro.Typography.logo)
                    .foregroundColor(.white)
                    .shadow(color: AppTheme.Retro.tomato, radius: 0, x: 3, y: 3)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.sm)
                    .retroPanel(AppTheme.Retro.bubblegum)
                    .rotationEffect(.degrees(-1.5))

                Text("with friends")
                    .font(AppTheme.Retro.Typography.pillLabel)
                    .foregroundColor(AppTheme.Retro.tomato)
                    .retroLozenge()

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    Text("Card title")
                        .font(AppTheme.Retro.Typography.cardTitle)
                        .foregroundColor(AppTheme.Retro.panelText)
                    Text("Body copy stays SF Pro on a cream panel — ink on cream is always safe (§8).")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Retro.panelText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .retroCard()

                RetroPrimaryButton(title: "Start Game", icon: "play.fill") {}

                HStack(spacing: AppTheme.Spacing.sm) {
                    RetroCategoryPill(title: "All", color: AppTheme.Retro.grass, isSelected: true) {}
                    RetroCategoryPill(title: "Party", color: AppTheme.Retro.grass, isSelected: false) {}
                }
            }
            .padding(AppTheme.Spacing.md)
        }
    }
}
