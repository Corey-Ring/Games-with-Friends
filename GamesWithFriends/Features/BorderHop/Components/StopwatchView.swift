import SwiftUI

struct StopwatchView: View {
    let elapsed: TimeInterval
    let color: Color

    var body: some View {
        Text(formattedTime)
            .font(AppTheme.Typography.cardTitle)
            .foregroundColor(color)
            .monospacedDigit()
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(Capsule().fill(.ultraThinMaterial))
            .animation(.easeInOut(duration: 0.5), value: color)
    }

    private var formattedTime: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
