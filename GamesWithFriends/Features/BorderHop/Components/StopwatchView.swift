import SwiftUI

struct StopwatchView: View {
    let elapsed: TimeInterval
    /// Supplied by the caller: `AppTheme.Retro.panelText` normally,
    /// `AppTheme.Retro.tomato` for an urgent state. Border Hop's stopwatch is
    /// an informational pace stat with no urgency trigger, so it always passes
    /// the calm color today — the parameter stays so a timed mode can raise it
    /// without touching this file.
    let color: Color

    var body: some View {
        Text(formattedTime)
            .font(AppTheme.Retro.Typography.cardTitle)
            .foregroundColor(color)
            .monospacedDigit()
            // §9: the ultraThinMaterial capsule is retired — ink on cream.
            .retroLozenge()
    }

    private var formattedTime: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
