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
                            if abs(translation.width) > 12 || abs(translation.height) > 12 {
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
                        zoomToFitNeighborhood(newId, viewSize: viewSize)
                    }
                } else {
                    zoomToFitNeighborhood(newId, viewSize: viewSize)
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

            // Draw decorative (non-game) countries as subtle land masses
            for (_, projected) in renderer.decorativeCountries {
                let path = Path(projected.path)
                let fillColor = isDark
                    ? Color(hex: "2C2C2E").opacity(0.3)
                    : Color(hex: "D5D0C8")
                context.fill(path, with: .color(fillColor))
                context.stroke(path, with: .color(isDark ? Color.white.opacity(0.05) : Color(hex: "B8B4AF").opacity(0.4)), lineWidth: 0.5)
            }

            // Draw trail lines (behind game countries)
            drawTrailLines(context: &context, renderer: renderer)

            // Draw each game country (shapes only — labels drawn separately to avoid overlap)
            for (id, projected) in renderer.projectedCountries {
                let state = viewModel.countryStates[id] ?? .fogged
                drawCountryShape(
                    context: &context,
                    projected: projected,
                    state: state,
                    isDark: isDark,
                    isDestination: id == viewModel.destinationCountryId
                )
            }

            // Draw labels with collision avoidance
            drawLabels(context: &context, renderer: renderer)

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

    /// Draw country shape only (fill, stroke, glow) — labels handled separately
    private func drawCountryShape(context: inout GraphicsContext, projected: MapRenderer.ProjectedCountry, state: CountryState, isDark: Bool, isDestination: Bool) {
        let path = Path(projected.path)
        let accent = theme.accentColor

        switch state {
        case .fogged:
            let fillColor = isDark
                ? Color(hex: "3A3A3C").opacity(0.6)
                : Color(hex: "C8C3BB")
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(isDark ? Color.white.opacity(0.08) : Color(hex: "9E9A94").opacity(0.5)), lineWidth: 0.5)

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

        case .visited:
            let fillColor = isDark
                ? AppTheme.darkMutedText.opacity(0.15)
                : AppTheme.mediumGray.opacity(0.20)
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(accent.opacity(0.4)), style: StrokeStyle(lineWidth: 0.5, dash: [4, 3]))

        case .current:
            let fillColor = isDark ? accent.opacity(0.9) : accent
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(.white), lineWidth: 2)

        case .destination:
            let gold = AppTheme.medalGold

            // Pulsing gold glow
            let glowRadius = glowPhase * 10
            context.drawLayer { ctx in
                ctx.addFilter(.shadow(color: gold.opacity(0.5), radius: glowRadius))
                ctx.stroke(path, with: .color(gold.opacity(0.4)), lineWidth: 1.5)
            }

            // Strong gold fill
            let fillColor = isDark
                ? gold.opacity(0.35)
                : gold.opacity(0.30)
            context.fill(path, with: .color(fillColor))

            // Bold outline
            context.stroke(path, with: .color(gold), lineWidth: 3)
        }
    }

    /// Draw labels for active countries with collision avoidance
    /// Priority order: current > destination > frontier > visited
    /// Fogged countries never get labels
    private func drawLabels(context: inout GraphicsContext, renderer: MapRenderer) {
        let accent = theme.accentColor
        let gold = AppTheme.medalGold

        // Build label candidates in priority order
        struct LabelCandidate {
            let text: String
            let centroid: CGPoint
            let color: Color
            let bold: Bool
        }

        var candidates: [LabelCandidate] = []

        // 1. Current country (highest priority — always shown)
        if let projected = renderer.projectedCountries[viewModel.currentCountryId] {
            let name = viewModel.graph.country(for: viewModel.currentCountryId)?.name ?? ""
            candidates.append(LabelCandidate(text: name, centroid: projected.centroid, color: .white, bold: true))
        }

        // 2. Destination country
        if viewModel.destinationCountryId != viewModel.currentCountryId,
           let projected = renderer.projectedCountries[viewModel.destinationCountryId] {
            let name = viewModel.graph.country(for: viewModel.destinationCountryId)?.name ?? ""
            candidates.append(LabelCandidate(text: name, centroid: projected.centroid, color: gold, bold: true))
        }

        // 3. Frontier countries
        for (id, projected) in renderer.projectedCountries {
            let state = viewModel.countryStates[id] ?? .fogged
            guard state == .frontier, id != viewModel.currentCountryId, id != viewModel.destinationCountryId else { continue }
            let name = viewModel.graph.country(for: id)?.name ?? ""
            candidates.append(LabelCandidate(text: name, centroid: projected.centroid, color: .white, bold: true))
        }

        // 4. Visited countries (lowest priority)
        for (id, projected) in renderer.projectedCountries {
            let state = viewModel.countryStates[id] ?? .fogged
            guard state == .visited else { continue }
            let name = viewModel.graph.country(for: id)?.name ?? ""
            candidates.append(LabelCandidate(text: name, centroid: projected.centroid, color: AppTheme.mediumGray, bold: false))
        }

        // Draw labels, skipping any that overlap with already-placed labels
        var placedRects: [CGRect] = []
        let labelPadding: CGFloat = 2 // minimum gap between labels

        for candidate in candidates {
            let font: Font = candidate.bold ? .caption.weight(.semibold) : .caption
            let resolved = context.resolve(
                Text(candidate.text).font(font).foregroundColor(candidate.color)
            )
            let textSize = resolved.measure(in: CGSize(width: 200, height: 50))
            let labelRect = CGRect(
                x: candidate.centroid.x - textSize.width / 2 - labelPadding,
                y: candidate.centroid.y + 10 - labelPadding,
                width: textSize.width + labelPadding * 2,
                height: textSize.height + labelPadding * 2
            )

            // Check for overlap with already-placed labels
            let overlaps = placedRects.contains { $0.intersects(labelRect) }
            if !overlaps {
                let origin = CGPoint(
                    x: candidate.centroid.x - textSize.width / 2,
                    y: candidate.centroid.y + 10
                )
                context.draw(resolved, at: origin, anchor: .topLeading)
                placedRects.append(labelRect)
            }
        }
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

        let priorityIds = Set(
            viewModel.countryStates
                .filter { $0.value == .frontier || $0.value == .destination }
                .map { $0.key }
        )

        if let countryId = renderer.hitTest(point: canvasPoint, priorityIds: priorityIds) {
            viewModel.handleTap(countryId: countryId)
        }
    }

    // MARK: - Camera

    private func setupRenderer() {
        if renderer == nil {
            let geoPolygons = BorderHopGeoData.loadFeatures()
            renderer = MapRenderer(countries: viewModel.graph.allCountries, geoPolygons: geoPolygons, canvasSize: canvasSize)
        }
    }

    private func centerOnStart(viewSize: CGSize) {
        zoomToFitNeighborhood(viewModel.startCountryId, viewSize: viewSize)
    }

    /// Zoom and center to fit the current country + its frontier neighbors in view
    private func zoomToFitNeighborhood(_ countryId: String, viewSize: CGSize) {
        guard let renderer else {
            centerOnCountry(countryId, viewSize: viewSize)
            return
        }

        // Collect current country + all frontier neighbors
        let neighborIds = viewModel.graph.neighborIds(of: countryId)
        let allIds = [countryId] + Array(neighborIds)
        let bbox = renderer.boundingBox(for: allIds)

        guard bbox != .zero, bbox.width > 0, bbox.height > 0 else {
            centerOnCountry(countryId, viewSize: viewSize)
            return
        }

        // Calculate scale to fit bbox with 25% padding into the view
        let padding: CGFloat = 1.25
        let scaleX = viewSize.width / (bbox.width * padding)
        let scaleY = viewSize.height / (bbox.height * padding)
        let fitScale = min(scaleX, scaleY)

        // Clamp: at least 3× (so small countries stay tappable), at most 6×
        let newScale = min(max(fitScale, 3.0), 6.0)
        scale = newScale
        lastScale = newScale

        // Center on the bbox center
        let bboxCenter = CGPoint(x: bbox.midX, y: bbox.midY)
        let centerX = viewSize.width / 2 - bboxCenter.x * scale + (canvasSize.width * scale - canvasSize.width) / 2
        let centerY = viewSize.height / 2 - bboxCenter.y * scale + (canvasSize.height * scale - canvasSize.height) / 2

        offset = CGSize(width: centerX, height: centerY)
        lastOffset = offset
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
