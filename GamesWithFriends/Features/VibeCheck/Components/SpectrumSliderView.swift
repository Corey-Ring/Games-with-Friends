import SwiftUI

/// A vertical spectrum slider with polar opposite labels
struct SpectrumSliderView: View {
    let spectrum: VibeCheckSpectrum
    @Binding var position: Double  // 0.0 = top, 1.0 = bottom
    var isInteractive: Bool = true
    var showTargetPosition: Bool = false
    var targetPosition: Double = 0.5
    var showScoringZones: Bool = false
    var showGuessPosition: Bool = false
    var guessPosition: Double = 0.5

    private let sliderHeight: CGFloat = 260
    private let handleSize: CGFloat = 36
    private let trackWidth: CGFloat = 56

    var body: some View {
        VStack(spacing: 16) {
            // Top label
            Text(spectrum.topLabel.uppercased())
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            // Slider area
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background track with gradient
                    backgroundTrack

                    // Scoring zones (only shown on reveal or prompt setter view)
                    if showScoringZones {
                        scoringZonesOverlay(height: geometry.size.height)
                    }

                    // Target position indicator
                    if showTargetPosition {
                        targetIndicator(height: geometry.size.height)
                    }

                    // Guess position indicator (for reveal)
                    if showGuessPosition {
                        guessIndicator(height: geometry.size.height)
                    }

                    // Draggable handle (when interactive)
                    if isInteractive {
                        draggableHandle(height: geometry.size.height)
                    }
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
                .gesture(
                    isInteractive ?
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let height = geometry.size.height
                            let usableHeight = height - handleSize
                            // Convert tap/drag location to position
                            let adjustedY = value.location.y - handleSize / 2
                            let clampedY = max(0, min(usableHeight, adjustedY))
                            let newPosition = clampedY / usableHeight

                            // Only trigger haptic if position actually changed significantly
                            if abs(newPosition - position) > 0.01 {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                            }

                            position = newPosition
                        }
                    : nil
                )
            }
            .frame(height: sliderHeight)

            // Bottom label
            Text(spectrum.bottomLabel.uppercased())
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal)
    }

    // MARK: - Components

    private var backgroundTrack: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.3),
                        Color.purple.opacity(0.1),
                        Color.blue.opacity(0.1),
                        Color.blue.opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: trackWidth)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .frame(width: trackWidth)
            }
    }

    private func scoringZonesOverlay(height: CGFloat) -> some View {
        let targetY = targetPosition * height

        return ZStack {
            // Draw zones from outside in (miss -> perfect)
            ForEach(Array(ScoringZone.allCases.reversed().enumerated()), id: \.offset) { _, zone in
                let zoneHeight = zone.threshold * height * 2  // *2 because it extends both ways
                RoundedRectangle(cornerRadius: 8)
                    .fill(zone.color.opacity(0.3))
                    .frame(width: trackWidth - 8, height: min(zoneHeight, height))
                    .position(x: trackWidth / 2, y: targetY)
            }
        }
        .frame(width: trackWidth)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func targetIndicator(height: CGFloat) -> some View {
        let yPosition = targetPosition * (height - handleSize) + handleSize / 2

        return ZStack {
            // Target line
            Rectangle()
                .fill(Color.green)
                .frame(width: trackWidth + 20, height: 4)

            // Target marker
            Circle()
                .fill(Color.green)
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                }
        }
        .position(x: trackWidth / 2 + (UIScreen.main.bounds.width - trackWidth) / 2 - 16, y: yPosition)
        .frame(width: trackWidth)
        .frame(maxWidth: .infinity)
    }

    private func guessIndicator(height: CGFloat) -> some View {
        let yPosition = guessPosition * (height - handleSize) + handleSize / 2

        return ZStack {
            // Guess line
            Rectangle()
                .fill(Color.orange)
                .frame(width: trackWidth + 20, height: 4)

            // Guess marker
            Circle()
                .fill(Color.orange)
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                }
        }
        .position(x: trackWidth / 2 + (UIScreen.main.bounds.width - trackWidth) / 2 - 16, y: yPosition)
        .frame(width: trackWidth)
        .frame(maxWidth: .infinity)
    }

    private func draggableHandle(height: CGFloat) -> some View {
        let yPosition = position * (height - handleSize) + handleSize / 2
        let centerX = (UIScreen.main.bounds.width - 32) / 2  // Account for horizontal padding

        return ZStack {
            // Position indicator line inside the bar, connecting to the handle
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: trackWidth - 8, height: 3)
                .position(x: centerX, y: yPosition)

            // Handle on the right side
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: handleSize, height: handleSize)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                .overlay {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .position(x: centerX + trackWidth / 2 + handleSize / 2 - 4, y: yPosition)

            // Percentage label on the left side
            percentageLabel(yPosition: yPosition, centerX: centerX)
        }
        .allowsHitTesting(false) // Let the parent handle all gestures
        .frame(maxWidth: .infinity)
    }

    private func percentageLabel(yPosition: CGFloat, centerX: CGFloat) -> some View {
        // Calculate percentage and determine which label to show
        // position 0.0 = 100% top label, position 1.0 = 100% bottom label
        let percentage: Int
        let label: String

        if position <= 0.5 {
            // Closer to top - show top label percentage
            percentage = Int(round((1 - position * 2) * 100))
            label = spectrum.topLabel
        } else {
            // Closer to bottom - show bottom label percentage
            percentage = Int(round((position - 0.5) * 2 * 100))
            label = spectrum.bottomLabel
        }

        return VStack(spacing: 2) {
            Text("\(percentage)%")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 70, alignment: .trailing)
        .position(x: centerX - trackWidth / 2 - 45, y: yPosition)
    }
}

// MARK: - Prompt Setter Version (shows target and scoring zones)

struct PromptSetterSliderView: View {
    let spectrum: VibeCheckSpectrum
    let targetPosition: Double

    private let sliderHeight: CGFloat = 260
    private let trackWidth: CGFloat = 56

    var body: some View {
        VStack(spacing: 8) {
            // Top label
            Text(spectrum.topLabel.uppercased())
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            // Slider with scoring zones
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: trackWidth)
                        .frame(maxWidth: .infinity)

                    // Scoring zones centered on target
                    scoringZonesView(height: geometry.size.height)

                    // Target indicator line
                    targetLine(height: geometry.size.height)
                }
            }
            .frame(height: sliderHeight)

            // Bottom label
            Text(spectrum.bottomLabel.uppercased())
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            // Legend
            scoringLegend
        }
        .padding(.horizontal)
    }

    private func scoringZonesView(height: CGFloat) -> some View {
        let targetY = targetPosition * height

        return Canvas { context, size in
            let centerX = size.width / 2

            // Draw zones from outside in
            for zone in ScoringZone.allCases.reversed() {
                let zoneHalfHeight = zone.threshold * height
                let topY = max(0, targetY - zoneHalfHeight)
                let bottomY = min(height, targetY + zoneHalfHeight)
                let zoneHeight = bottomY - topY

                let rect = CGRect(
                    x: centerX - trackWidth / 2 + CGFloat(4),
                    y: topY,
                    width: trackWidth - 8,
                    height: zoneHeight
                )

                context.fill(
                    Path(roundedRect: rect, cornerRadius: 6),
                    with: .color(zone.color.opacity(0.6))
                )
            }
        }
    }

    private func targetLine(height: CGFloat) -> some View {
        let yPosition = targetPosition * height

        return Rectangle()
            .fill(Color.white)
            .frame(width: trackWidth + 30, height: 3)
            .shadow(color: .black.opacity(0.3), radius: 2)
            .position(x: UIScreen.main.bounds.width / 2 - 16, y: yPosition)
    }

    private var scoringLegend: some View {
        HStack(spacing: 12) {
            ForEach(Array(ScoringZone.allCases.prefix(4)), id: \.self) { zone in
                HStack(spacing: 4) {
                    Circle()
                        .fill(zone.color)
                        .frame(width: 10, height: 10)
                    Text("\(zone.points)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Reveal Version (shows target, guess, and zones)

struct RevealSliderView: View {
    let spectrum: VibeCheckSpectrum
    let targetPosition: Double
    let guessPosition: Double
    let zone: ScoringZone

    private let sliderHeight: CGFloat = 300
    private let trackWidth: CGFloat = 60

    var body: some View {
        VStack(spacing: 16) {
            // Top label
            Text(spectrum.topLabel.uppercased())
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            // Slider with both positions
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background track
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: trackWidth)
                        .frame(maxWidth: .infinity)

                    // Scoring zones
                    scoringZonesView(height: geometry.size.height)

                    // Target line (green)
                    positionLine(
                        y: targetPosition * geometry.size.height,
                        color: .green,
                        label: "Target"
                    )

                    // Guess line (team color)
                    positionLine(
                        y: guessPosition * geometry.size.height,
                        color: .orange,
                        label: "Guess"
                    )
                }
            }
            .frame(height: sliderHeight)

            // Bottom label
            Text(spectrum.bottomLabel.uppercased())
                .font(.headline.weight(.bold))
                .foregroundStyle(.primary)

            // Result
            HStack {
                Circle()
                    .fill(zone.color)
                    .frame(width: 20, height: 20)
                Text("+\(zone.points) points")
                    .font(.headline)
                    .foregroundStyle(zone.color)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background {
                Capsule()
                    .fill(zone.color.opacity(0.2))
            }
        }
        .padding(.horizontal)
    }

    private func scoringZonesView(height: CGFloat) -> some View {
        let targetY = targetPosition * height

        return Canvas { context, size in
            let centerX = size.width / 2

            for zone in ScoringZone.allCases.reversed() {
                let zoneHalfHeight = zone.threshold * height
                let topY = max(0, targetY - zoneHalfHeight)
                let bottomY = min(height, targetY + zoneHalfHeight)
                let zoneHeight = bottomY - topY

                let rect = CGRect(
                    x: centerX - trackWidth / 2 + CGFloat(4),
                    y: topY,
                    width: trackWidth - 8,
                    height: zoneHeight
                )

                context.fill(
                    Path(roundedRect: rect, cornerRadius: 6),
                    with: .color(zone.color.opacity(0.4))
                )
            }
        }
    }

    private func positionLine(y: CGFloat, color: Color, label: String) -> some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 50, alignment: .trailing)

            Rectangle()
                .fill(color)
                .frame(width: trackWidth + 20, height: 4)
                .shadow(color: .black.opacity(0.2), radius: 2)

            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
        }
        .position(x: UIScreen.main.bounds.width / 2 - 16, y: y)
    }
}

#Preview("Interactive") {
    struct PreviewWrapper: View {
        @State private var position: Double = 0.5

        var body: some View {
            SpectrumSliderView(
                spectrum: VibeCheckSpectrum(topLabel: "Trashy", bottomLabel: "Classy"),
                position: $position
            )
        }
    }
    return PreviewWrapper()
}

#Preview("Prompt Setter") {
    PromptSetterSliderView(
        spectrum: VibeCheckSpectrum(topLabel: "Trashy", bottomLabel: "Classy"),
        targetPosition: 0.15
    )
}

#Preview("Reveal") {
    RevealSliderView(
        spectrum: VibeCheckSpectrum(topLabel: "Trashy", bottomLabel: "Classy"),
        targetPosition: 0.15,
        guessPosition: 0.20,
        zone: .great
    )
}
