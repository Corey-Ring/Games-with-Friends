import SwiftUI

struct StopwatchView: View {
    let elapsed: TimeInterval
    let color: Color
    var showReward: Bool = false

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Text(formattedTime)
                .font(AppTheme.Typography.cardTitle)
                .foregroundColor(color)
                .monospacedDigit()

            if showReward {
                Text("-3s")
                    .font(AppTheme.Typography.pillLabel)
                    .foregroundColor(AppTheme.success)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(Capsule().fill(.ultraThinMaterial))
        .animation(.easeInOut(duration: 0.5), value: color)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showReward)
    }

    private var formattedTime: String {
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}
