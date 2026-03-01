import SwiftUI

struct AnimatedScoreText: View {
    let targetScore: Int
    let color: Color
    var font: Font = AppTheme.Typography.hero

    @State private var displayedScore: Int = 0

    var body: some View {
        Text("\(displayedScore)")
            .font(font)
            .fontWeight(.bold)
            .foregroundColor(color)
            .monospacedDigit()
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(AppTheme.Animation.scoreCounter.delay(0.3)) {
                    displayedScore = targetScore
                }
            }
    }
}
