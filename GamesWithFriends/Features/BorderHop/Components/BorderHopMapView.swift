import SwiftUI

struct BorderHopMapView: View {
    var viewModel: BorderHopViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var renderer: MapRenderer?
    @State private var scale: CGFloat = 2.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 2.0
    @State private var lastOffset: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var glowPhase: CGFloat = 0
    @State private var flagOffset: CGFloat = 0

    private let canvasSize = CGSize(width: 2000, height: 1000)
    private let theme = GameTheme.borderHop

    var body: some View {
        GeometryReader { geo in
            let viewSize = geo.size

            ZStack {
                // Ocean background
                (colorScheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "E8E4DF"))
                    .ignoresSafeArea()

                // Map canvas (gestures are on the ZStack, not here)
                // Use conditional to force SwiftUI to rebuild Canvas when renderer changes
                if let renderer {
                    mapCanvas(renderer: renderer)
                        .frame(width: canvasSize.width, height: canvasSize.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .allowsHitTesting(false)
                } else {
                    Color.clear
                        .frame(width: canvasSize.width, height: canvasSize.height)
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let newScale = lastScale * value
                            scale = min(max(newScale, 1.0), 8.0)
                        }
                        .onEnded { _ in
                            lastScale = scale
                        },
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let translation = value.translation
                            if abs(translation.width) > 5 || abs(translation.height) > 5 {
                                isDragging = true
                                offset = CGSize(
                                    width: lastOffset.width + translation.width,
                                    height: lastOffset.height + translation.height
                                )
                            }
                        }
                        .onEnded { value in
                            if isDragging {
                                lastOffset = offset
                            } else {
                                // Short drag = tap. startLocation is in ZStack local space.
                                handleTap(at: value.startLocation, viewSize: viewSize)
                            }
                            isDragging = false
                        }
                )
            )
            .onAppear {
                setupRenderer()
                centerOnStart(viewSize: viewSize)
            }
            .onChange(of: viewModel.currentCountryId) { _, newId in
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        centerOnCountry(newId, viewSize: viewSize)
                    }
                } else {
                    centerOnCountry(newId, viewSize: viewSize)
                }
            }
        }
        .onAppear {
            // Pulsing glow animation
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    glowPhase = 1
                }
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    flagOffset = -2
                }
            }
        }
    }

    // MARK: - Canvas

    private func mapCanvas(renderer: MapRenderer) -> some View {
        Canvas { context, size in
            let isDark = colorScheme == .dark

            // Draw trail lines first (behind countries)
            drawTrailLines(context: &context, renderer: renderer)

            // Draw each country
            for (id, projected) in renderer.projectedCountries {
                let state = viewModel.countryStates[id] ?? .fogged
                drawCountry(
                    context: &context,
                    projected: projected,
                    state: state,
                    isDark: isDark,
                    isDestination: id == viewModel.destinationCountryId
                )
            }

            // Draw player marker on current country
            if let current = renderer.projectedCountries[viewModel.currentCountryId] {
                drawPlayerMarker(context: &context, at: current.centroid)
            }

            // Draw destination flag
            if viewModel.currentCountryId != viewModel.destinationCountryId,
               let dest = renderer.projectedCountries[viewModel.destinationCountryId] {
                drawDestinationFlag(context: &context, at: dest.centroid)
            }
        }
    }

    // MARK: - Drawing Helpers

    private func drawCountry(context: inout GraphicsContext, projected: MapRenderer.ProjectedCountry, state: CountryState, isDark: Bool, isDestination: Bool) {
        let path = Path(projected.path)
        let accent = theme.accentColor

        switch state {
        case .fogged:
            let fillColor = isDark
                ? Color(hex: "2C2C2E").opacity(0.5)
                : Color(hex: "2C2C2E").opacity(0.25)
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(isDark ? Color.white.opacity(0.1) : Color(hex: "2C2C2E").opacity(0.15)), lineWidth: 0.5)

        case .frontier:
            let fillColor = isDark
                ? accent.opacity(0.25)
                : accent.opacity(0.20)
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(accent), lineWidth: 1.5)

            // Glow effect
            let glowRadius = glowPhase * 8
            context.drawLayer { ctx in
                ctx.addFilter(.shadow(color: accent.opacity(0.4), radius: glowRadius))
                ctx.stroke(path, with: .color(accent.opacity(0.3)), lineWidth: 1)
            }

            // Label
            drawLabel(context: &context, text: viewModel.graph.country(for: projected.id)?.name ?? "", at: projected.centroid, color: .white, bold: true)

        case .visited:
            let fillColor = isDark
                ? AppTheme.darkMutedText.opacity(0.15)
                : AppTheme.mediumGray.opacity(0.20)
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(accent.opacity(0.4)), style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))

            // Label
            drawLabel(context: &context, text: viewModel.graph.country(for: projected.id)?.name ?? "", at: projected.centroid, color: AppTheme.mediumGray, bold: false)

        case .current:
            let fillColor = isDark ? accent.opacity(0.9) : accent
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(.white), lineWidth: 2)

            // Label
            drawLabel(context: &context, text: viewModel.graph.country(for: projected.id)?.name ?? "", at: projected.centroid, color: .white, bold: true)

        case .destination:
            // Always visible outline
            context.stroke(path, with: .color(AppTheme.medalGold), lineWidth: 2)
            let fillColor = isDark
                ? AppTheme.medalGold.opacity(0.15)
                : AppTheme.medalGold.opacity(0.10)
            context.fill(path, with: .color(fillColor))

            // Label
            drawLabel(context: &context, text: viewModel.graph.country(for: projected.id)?.name ?? "", at: projected.centroid, color: AppTheme.medalGold, bold: true)
        }
    }

    private func drawLabel(context: inout GraphicsContext, text: String, at point: CGPoint, color: Color, bold: Bool) {
        let font: Font = bold ? .caption.weight(.semibold) : .caption
        var textContext = context
        let resolved = textContext.resolve(Text(text).font(font).foregroundColor(color))
        let textSize = resolved.measure(in: CGSize(width: 200, height: 50))
        let origin = CGPoint(x: point.x - textSize.width / 2, y: point.y + 12)
        textContext.draw(resolved, at: origin, anchor: .topLeading)
    }

    private func drawPlayerMarker(context: inout GraphicsContext, at point: CGPoint) {
        let markerSize: CGFloat = 12
        let markerRect = CGRect(x: point.x - markerSize / 2, y: point.y - markerSize - 4, width: markerSize, height: markerSize)
        context.fill(Circle().path(in: markerRect), with: .color(.white))
        context.fill(Circle().path(in: markerRect.insetBy(dx: 3, dy: 3)), with: .color(theme.accentColor))
    }

    private func drawDestinationFlag(context: inout GraphicsContext, at point: CGPoint) {
        let flagPoint = CGPoint(x: point.x, y: point.y - 16 + flagOffset)
        let resolved = context.resolve(
            Text(Image(systemName: "flag.checkered"))
                .font(.system(size: 20))
                .foregroundColor(AppTheme.medalGold)
        )
        context.draw(resolved, at: flagPoint)
    }

    private func drawTrailLines(context: inout GraphicsContext, renderer: MapRenderer) {
        guard viewModel.actualPath.count >= 2 else { return }

        var trailPath = Path()
        for i in 0..<viewModel.actualPath.count {
            let id = viewModel.actualPath[i]
            guard let projected = renderer.projectedCountries[id] else { continue }
            if i == 0 {
                trailPath.move(to: projected.centroid)
            } else {
                trailPath.addLine(to: projected.centroid)
            }
        }

        context.stroke(
            trailPath,
            with: .color(theme.accentColor.opacity(0.6)),
            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
        )
    }

    // MARK: - Interaction

    private func handleTap(at location: CGPoint, viewSize: CGSize) {
        guard let renderer else { return }

        // Inverse of: screen = cx * scale + offset - canvasSize * (scale - 1) / 2
        let canvasPoint = CGPoint(
            x: (location.x - offset.width + canvasSize.width * (scale - 1) / 2) / scale,
            y: (location.y - offset.height + canvasSize.height * (scale - 1) / 2) / scale
        )

        if let countryId = renderer.hitTest(point: canvasPoint) {
            viewModel.handleTap(countryId: countryId)
        }
    }

    // MARK: - Camera

    private func setupRenderer() {
        if renderer == nil {
            renderer = MapRenderer(countries: viewModel.graph.allCountries, canvasSize: canvasSize)
        }
    }

    private func centerOnStart(viewSize: CGSize) {
        centerOnCountry(viewModel.startCountryId, viewSize: viewSize)
    }

    private func centerOnCountry(_ countryId: String, viewSize: CGSize) {
        guard let renderer, let projected = renderer.projectedCountries[countryId] else { return }

        // The visual position of canvas point (cx, cy) on screen is:
        //   screen_x = cx * scale + offset.width - canvasSize.width * (scale - 1) / 2
        // To place (cx, cy) at screen center (viewSize.width/2), solve for offset:
        let centerX = viewSize.width / 2 - projected.centroid.x * scale + (canvasSize.width * scale - canvasSize.width) / 2
        let centerY = viewSize.height / 2 - projected.centroid.y * scale + (canvasSize.height * scale - canvasSize.height) / 2

        offset = CGSize(width: centerX, height: centerY)
        lastOffset = offset
    }
}
