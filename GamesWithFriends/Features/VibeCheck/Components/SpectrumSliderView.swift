import SwiftUI

/// A vertical spectrum slider with polar opposite labels.
///
/// Retro-migrated (ART_DIRECTION §2/§5/§8): flat candy fills, ink outlines,
/// hard offset shadows. **The geometry math, gesture handling and value
/// mapping below are untouched from the pre-migration file** — every
/// `usableHeight` / `yPosition` expression, the drag conversion, the haptic
/// threshold and the percentage arithmetic are byte-for-byte as found. Only
/// fills, strokes, shadows and label typography changed.
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
        VStack(spacing: AppTheme.Spacing.md) {
            // Top label
            SpectrumPoleLabel(text: spectrum.topLabel, fill: VibeCheckStyle.poleTop)

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
                        targetIndicator(height: geometry.size.height, width: geometry.size.width)
                    }

                    // Guess position indicator (for reveal)
                    if showGuessPosition {
                        guessIndicator(height: geometry.size.height, width: geometry.size.width)
                    }

                    // Draggable handle (when interactive)
                    if isInteractive {
                        draggableHandle(height: geometry.size.height, width: geometry.size.width)
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
            SpectrumPoleLabel(text: spectrum.bottomLabel, fill: VibeCheckStyle.poleBottom)
        }
        .padding(.horizontal)
    }

    // MARK: - Components

    /// Flat cream track inside an ink outline (§2 rules 1–2 — the old
    /// four-stop accent gradient is retired).
    private var backgroundTrack: some View {
        RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
            .fill(AppTheme.Retro.panel)
            .frame(width: trackWidth)
            .frame(maxWidth: .infinity)
            .overlay {
                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                    .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
                    .frame(width: trackWidth)
            }
    }

    private func scoringZonesOverlay(height: CGFloat) -> some View {
        // Use the same usable height as the drag gesture to align zones with interactive area
        let usableHeight = height - handleSize
        let targetY = targetPosition * usableHeight + handleSize / 2

        return ZStack {
            // Draw zones from outside in (miss -> perfect)
            ForEach(Array(ScoringZone.allCases.reversed().enumerated()), id: \.offset) { _, zone in
                let zoneHeight = zone.threshold * usableHeight * 2  // *2 because it extends both ways
                // Flat candy bands, opaque: the tighter zone paints over the
                // looser one instead of the two tints blending (§2 rule 2).
                RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner - 4)
                    .fill(VibeCheckStyle.zoneColor(zone))
                    .frame(width: trackWidth - 8, height: min(zoneHeight, height))
                    .position(x: trackWidth / 2, y: targetY)
            }
        }
        .frame(width: trackWidth)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private func targetIndicator(height: CGFloat, width: CGFloat) -> some View {
        let yPosition = targetPosition * (height - handleSize) + handleSize / 2

        return ZStack {
            // Target line
            Rectangle()
                .fill(VibeCheckStyle.targetMarker)
                .frame(width: trackWidth + 20, height: 4)
                .overlay(Rectangle().stroke(AppTheme.Retro.ink, lineWidth: 1))

            // Target marker
            Circle()
                .fill(VibeCheckStyle.targetMarker)
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .stroke(AppTheme.Retro.ink, lineWidth: 2)
                }
        }
        .position(x: width / 2, y: yPosition)
    }

    private func guessIndicator(height: CGFloat, width: CGFloat) -> some View {
        let yPosition = guessPosition * (height - handleSize) + handleSize / 2

        return ZStack {
            // Guess line
            Rectangle()
                .fill(VibeCheckStyle.guessMarker)
                .frame(width: trackWidth + 20, height: 4)
                .overlay(Rectangle().stroke(AppTheme.Retro.ink, lineWidth: 1))

            // Guess marker
            Circle()
                .fill(VibeCheckStyle.guessMarker)
                .frame(width: 16, height: 16)
                .overlay {
                    Circle()
                        .stroke(AppTheme.Retro.ink, lineWidth: 2)
                }
        }
        .position(x: width / 2, y: yPosition)
    }

    private func draggableHandle(height: CGFloat, width: CGFloat) -> some View {
        let yPosition = position * (height - handleSize) + handleSize / 2
        let centerX = width / 2

        return ZStack {
            // Position indicator line inside the bar, connecting to the handle
            Rectangle()
                .fill(AppTheme.Retro.ink)
                .frame(width: trackWidth - 8, height: 3)
                .position(x: centerX, y: yPosition)

            // Handle on the right side — flat berry disc, ink outline, hard
            // offset shadow instead of the old blurred drop shadow (§2 rule 2).
            Circle()
                .fill(VibeCheckStyle.accent)
                .frame(width: handleSize, height: handleSize)
                .background(
                    Circle()
                        .fill(AppTheme.Retro.ink)
                        .offset(x: 3, y: 3)
                )
                .overlay {
                    Circle()
                        .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
                }
                .overlay {
                    Image(systemName: "line.3.horizontal")
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(VibeCheckStyle.chipTextColor(on: VibeCheckStyle.accent))
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
                .font(AppTheme.Retro.Typography.heading(20, relativeTo: .title3))
                .foregroundColor(AppTheme.Retro.panelText)
            Text(label.uppercased())
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(AppTheme.Retro.panelText.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 70, alignment: .trailing)
        .position(x: centerX - trackWidth / 2 - 45, y: yPosition)
    }
}

// MARK: - Pole Label

/// The spectrum's two ends are semantic, so each pole carries its own candy
/// lozenge (§8: ink passes outright on poolBlue and tangerine, so the label
/// text stays ink at every Dynamic Type size).
struct SpectrumPoleLabel: View {
    let text: String
    let fill: Color

    var body: some View {
        Text(text.uppercased())
            .font(AppTheme.Retro.Typography.heading(17))
            .foregroundColor(VibeCheckStyle.chipTextColor(on: fill))
            .multilineTextAlignment(.center)
            .retroLozenge(fill)
    }
}

// MARK: - Prompt Setter Version (shows target and scoring zones)

struct PromptSetterSliderView: View {
    let spectrum: VibeCheckSpectrum
    let targetPosition: Double

    private let sliderHeight: CGFloat = 260
    private let trackWidth: CGFloat = 56

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Top label
            SpectrumPoleLabel(text: spectrum.topLabel, fill: VibeCheckStyle.poleTop)

            // Slider with scoring zones
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background track
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                        .fill(AppTheme.Retro.panel)
                        .frame(width: trackWidth)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                                .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
                                .frame(width: trackWidth)
                        }

                    // Scoring zones centered on target
                    scoringZonesView(height: geometry.size.height)

                    // Target indicator line
                    targetLine(height: geometry.size.height, width: geometry.size.width)
                }
            }
            .frame(height: sliderHeight)

            // Bottom label
            SpectrumPoleLabel(text: spectrum.bottomLabel, fill: VibeCheckStyle.poleBottom)

            // Legend
            scoringLegend
        }
        .padding(.horizontal)
    }

    private func scoringZonesView(height: CGFloat) -> some View {
        // Match the coordinate system of the main slider (no handle adjustment needed here)
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
                    with: .color(VibeCheckStyle.zoneColor(zone))
                )
            }
        }
    }

    private func targetLine(height: CGFloat, width: CGFloat) -> some View {
        // Match the coordinate system of the main slider (no handle adjustment needed here)
        let yPosition = targetPosition * height

        return Rectangle()
            .fill(AppTheme.Retro.ink)
            .frame(width: trackWidth + 30, height: 3)
            .position(x: width / 2, y: yPosition)
    }

    private var scoringLegend: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(Array(ScoringZone.allCases.prefix(4)), id: \.self) { zone in
                HStack(spacing: AppTheme.Spacing.xs) {
                    Circle()
                        .fill(VibeCheckStyle.zoneColor(zone))
                        .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                        .frame(width: 12, height: 12)
                    Text("\(zone.points)")
                        .font(AppTheme.Retro.Typography.pillLabel)
                        .foregroundColor(AppTheme.Retro.panelText)
                }
            }
        }
        .padding(.vertical, 2)
        .retroLozenge()
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
        VStack(spacing: AppTheme.Spacing.md) {
            // Top label
            SpectrumPoleLabel(text: spectrum.topLabel, fill: VibeCheckStyle.poleTop)

            // Slider with both positions
            GeometryReader { geometry in
                ZStack(alignment: .top) {
                    // Background track
                    RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                        .fill(AppTheme.Retro.panel)
                        .frame(width: trackWidth)
                        .frame(maxWidth: .infinity)
                        .overlay {
                            RoundedRectangle(cornerRadius: AppTheme.Retro.Radius.inner)
                                .stroke(AppTheme.Retro.ink, lineWidth: AppTheme.Retro.strokeWidth)
                                .frame(width: trackWidth)
                        }

                    // Scoring zones
                    scoringZonesView(height: geometry.size.height)

                    // Target line (grass)
                    positionLine(
                        y: targetPosition * geometry.size.height,
                        width: geometry.size.width,
                        color: VibeCheckStyle.targetMarker,
                        label: "Target"
                    )

                    // Guess line
                    positionLine(
                        y: guessPosition * geometry.size.height,
                        width: geometry.size.width,
                        color: VibeCheckStyle.guessMarker,
                        label: "Guess"
                    )
                }
            }
            .frame(height: sliderHeight)

            // Bottom label
            SpectrumPoleLabel(text: spectrum.bottomLabel, fill: VibeCheckStyle.poleBottom)

            // Result
            HStack(spacing: AppTheme.Spacing.sm) {
                Circle()
                    .fill(VibeCheckStyle.zoneColor(zone))
                    .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 2))
                    .frame(width: 20, height: 20)
                Text("+\(zone.points) points")
                    .font(AppTheme.Retro.Typography.heading(17))
                    .foregroundColor(AppTheme.Retro.panelText)
            }
            .padding(.vertical, AppTheme.Spacing.xs)
            .retroLozenge()
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
                    with: .color(VibeCheckStyle.zoneColor(zone))
                )
            }
        }
    }

    private func positionLine(y: CGFloat, width: CGFloat, color: Color, label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Text(label)
                .font(AppTheme.Retro.Typography.pillLabel)
                .foregroundColor(VibeCheckStyle.chipTextColor(on: color))
                .padding(.horizontal, AppTheme.Spacing.xs)
                .padding(.vertical, 1)
                .background(Capsule().fill(color))
                .overlay(Capsule().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                .frame(width: 50, alignment: .trailing)

            Rectangle()
                .fill(color)
                .frame(width: trackWidth + 20, height: 4)
                .overlay(Rectangle().stroke(AppTheme.Retro.ink, lineWidth: 1))

            Circle()
                .fill(color)
                .overlay(Circle().stroke(AppTheme.Retro.ink, lineWidth: 1.5))
                .frame(width: 12, height: 12)
        }
        .position(x: width / 2, y: y)
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
