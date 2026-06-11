import SwiftUI

/// The map camera in canvas coordinates. Animating `center`/`zoom` directly (instead of
/// screen-space `scaleEffect` + `offset`) gives straight-line pans with no arcing, and the
/// canvas re-renders vector-crisp at every interpolated step.
struct MapCamera: Equatable {
    var center: CGPoint
    var zoom: CGFloat

    func screenPoint(for canvasPoint: CGPoint, viewSize: CGSize) -> CGPoint {
        CGPoint(
            x: (canvasPoint.x - center.x) * zoom + viewSize.width / 2,
            y: (canvasPoint.y - center.y) * zoom + viewSize.height / 2
        )
    }

    func canvasPoint(for screenPoint: CGPoint, viewSize: CGSize) -> CGPoint {
        CGPoint(
            x: (screenPoint.x - viewSize.width / 2) / zoom + center.x,
            y: (screenPoint.y - viewSize.height / 2) / zoom + center.y
        )
    }

    func visibleRect(viewSize: CGSize) -> CGRect {
        CGRect(
            x: center.x - viewSize.width / (2 * zoom),
            y: center.y - viewSize.height / (2 * zoom),
            width: viewSize.width / zoom,
            height: viewSize.height / zoom
        )
    }
}

struct BorderHopMapView: View {
    var viewModel: BorderHopViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var renderer: MapRenderer?
    @State private var camera = MapCamera(center: .zero, zoom: 2)
    @State private var hasFittedInitially = false
    @State private var pinchStartCamera: MapCamera?
    @State private var panStartCamera: MapCamera?
    @State private var isDragging = false
    @State private var isUserAdjusted = false
    @State private var isWorldView = false

    private let theme = GameTheme.borderHop
    private let maxZoom: CGFloat = 16

    var body: some View {
        GeometryReader { geo in
            let viewSize = geo.size

            ZStack {
                // Ocean background
                (colorScheme == .dark ? Color(hex: "1C1C1E") : Color(hex: "E8E4DF"))
                    .ignoresSafeArea()

                if let renderer {
                    AnimatedMapContent(
                        viewModel: viewModel,
                        renderer: renderer,
                        camera: camera,
                        viewSize: viewSize,
                        colorScheme: colorScheme,
                        onTapCountry: { viewModel.handleTap(countryId: $0) }
                    )
                }
            }
            .contentShape(Rectangle())
            .gesture(mapGestures(viewSize: viewSize))
            .overlay(alignment: .topTrailing) {
                miniMap(viewSize: viewSize)
                    .padding(.trailing, AppTheme.Spacing.md)
                    .padding(.top, 64) // below the HUD row
            }
            .overlay(alignment: .bottomTrailing) {
                if isUserAdjusted || isWorldView {
                    recenterButton(viewSize: viewSize)
                        .padding(.trailing, AppTheme.Spacing.md)
                        .padding(.bottom, 96) // above the destination bar
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isUserAdjusted || isWorldView)
            .onAppear {
                setupRenderer()
                fitInitiallyIfPossible(viewSize: viewSize)
            }
            .onChange(of: viewSize) { _, newSize in
                fitInitiallyIfPossible(viewSize: newSize)
            }
            .onChange(of: viewModel.currentCountryId) { _, newId in
                focusNeighborhood(newId, viewSize: viewSize, animated: true)
            }
        }
    }

    // MARK: - Camera Control

    private func setupRenderer() {
        if renderer == nil {
            let geoPolygons = BorderHopGeoData.loadFeatures()
            renderer = MapRenderer(countries: viewModel.graph.allCountries, geoPolygons: geoPolygons)
        }
    }

    private func fitInitiallyIfPossible(viewSize: CGSize) {
        guard !hasFittedInitially, viewSize.width > 0, viewSize.height > 0 else { return }
        hasFittedInitially = true
        focusNeighborhood(viewModel.currentCountryId, viewSize: viewSize, animated: false)
    }

    /// Frame the given country plus its neighbors. Far-flung neighbors are clamped out by
    /// the renderer and surface as edge indicators instead of dragging the zoom out.
    private func focusNeighborhood(_ countryId: String, viewSize: CGSize, animated: Bool) {
        guard let renderer, viewSize.width > 0, viewSize.height > 0 else { return }

        let neighborIds = Array(viewModel.graph.neighborIds(of: countryId))
        guard let rect = renderer.neighborhoodRect(currentId: countryId, neighborIds: neighborIds),
              rect.width > 0, rect.height > 0 else { return }

        let fitZoom = min(viewSize.width / rect.width, viewSize.height / rect.height)
        // Fit zoom is capped below max so a microstate neighborhood still shows context;
        // the player can always pinch in further.
        let zoom = min(max(fitZoom, minZoom(viewSize: viewSize)), 10)
        let target = clamped(
            MapCamera(center: CGPoint(x: rect.midX, y: rect.midY), zoom: zoom),
            viewSize: viewSize
        )

        isUserAdjusted = false
        isWorldView = false
        if animated && !reduceMotion {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                camera = target
            }
        } else {
            camera = target
        }
    }

    private func showWorldView(viewSize: CGSize) {
        guard let renderer else { return }
        let canvas = renderer.canvasSize
        let target = MapCamera(
            center: CGPoint(x: canvas.width / 2, y: canvas.height / 2),
            zoom: min(viewSize.width / canvas.width, viewSize.height / canvas.height)
        )
        isWorldView = true
        if reduceMotion {
            camera = target
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) { camera = target }
        }
    }

    private func minZoom(viewSize: CGSize) -> CGFloat {
        guard let renderer else { return 1 }
        return min(viewSize.width / renderer.canvasSize.width, viewSize.height / renderer.canvasSize.height)
    }

    private func clamped(_ camera: MapCamera, viewSize: CGSize) -> MapCamera {
        guard let renderer else { return camera }
        var result = camera
        result.zoom = min(max(camera.zoom, minZoom(viewSize: viewSize)), maxZoom)

        // Wrap x into the world; clamp y so the view never scrolls past the poles
        let canvas = renderer.canvasSize
        var x = result.center.x.truncatingRemainder(dividingBy: canvas.width)
        if x < 0 { x += canvas.width }
        result.center.x = x

        let halfVisibleHeight = viewSize.height / (2 * result.zoom)
        if halfVisibleHeight >= canvas.height / 2 {
            result.center.y = canvas.height / 2
        } else {
            result.center.y = min(max(result.center.y, halfVisibleHeight), canvas.height - halfVisibleHeight)
        }
        return result
    }

    // MARK: - Gestures

    private func mapGestures(viewSize: CGSize) -> some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .onChanged { value in
                    let base = pinchStartCamera ?? camera
                    if pinchStartCamera == nil { pinchStartCamera = camera }
                    var next = base
                    next.zoom = base.zoom * value
                    camera = clamped(next, viewSize: viewSize)
                    isUserAdjusted = true
                }
                .onEnded { _ in
                    pinchStartCamera = nil
                },
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let translation = value.translation
                    guard isDragging || abs(translation.width) > 10 || abs(translation.height) > 10 else { return }
                    let base = panStartCamera ?? camera
                    if panStartCamera == nil { panStartCamera = camera }
                    isDragging = true
                    var next = camera
                    next.center = CGPoint(
                        x: base.center.x - translation.width / camera.zoom,
                        y: base.center.y - translation.height / camera.zoom
                    )
                    camera = clamped(next, viewSize: viewSize)
                }
                .onEnded { value in
                    if isDragging {
                        isUserAdjusted = true
                    } else {
                        handleTap(at: value.startLocation, viewSize: viewSize)
                    }
                    isDragging = false
                    panStartCamera = nil
                }
        )
    }

    private func handleTap(at location: CGPoint, viewSize: CGSize) {
        guard let renderer else { return }

        var canvasPoint = camera.canvasPoint(for: location, viewSize: viewSize)
        var x = canvasPoint.x.truncatingRemainder(dividingBy: renderer.canvasSize.width)
        if x < 0 { x += renderer.canvasSize.width }
        canvasPoint.x = x

        let priorityIds = Set(
            viewModel.countryStates
                .filter { $0.value == .frontier || $0.value == .destination }
                .map { $0.key }
        )

        // Constant ~24pt screen tolerance regardless of zoom level
        let tolerance = 24 / camera.zoom
        if let countryId = renderer.hitTest(point: canvasPoint, priorityIds: priorityIds, tolerance: tolerance) {
            viewModel.handleTap(countryId: countryId)
        }
    }

    // MARK: - Mini-map

    /// Always-visible world overview: where you are, where the goal is, what the camera sees.
    private func miniMap(viewSize: CGSize) -> some View {
        Group {
            if let renderer {
                let canvas = renderer.canvasSize
                let width: CGFloat = 112
                let height = width * canvas.height / canvas.width

                Canvas { context, size in
                    let scale = size.width / canvas.width

                    var mapContext = context
                    mapContext.scaleBy(x: scale, y: scale)
                    let landColor = colorScheme == .dark
                        ? Color.white.opacity(0.22)
                        : Color(hex: "B8B4AF")
                    mapContext.fill(Path(renderer.combinedLandPath), with: .color(landColor))

                    // Camera viewport
                    let visible = camera.visibleRect(viewSize: viewSize)
                    let viewport = CGRect(
                        x: visible.minX * scale,
                        y: visible.minY * scale,
                        width: visible.width * scale,
                        height: visible.height * scale
                    ).intersection(CGRect(origin: .zero, size: size))
                    if !viewport.isNull, viewport.width < size.width - 2 {
                        context.stroke(Path(roundedRect: viewport, cornerRadius: 2), with: .color(theme.accentColor), lineWidth: 1)
                    }

                    // Destination dot
                    if let dest = renderer.projectedCountries[viewModel.destinationCountryId] {
                        let p = CGPoint(x: dest.centroid.x * scale, y: dest.centroid.y * scale)
                        context.fill(Circle().path(in: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(AppTheme.medalGold))
                    }

                    // Player dot
                    if let current = renderer.projectedCountries[viewModel.currentCountryId] {
                        let p = CGPoint(x: current.centroid.x * scale, y: current.centroid.y * scale)
                        context.fill(Circle().path(in: CGRect(x: p.x - 3.5, y: p.y - 3.5, width: 7, height: 7)), with: .color(.white))
                        context.fill(Circle().path(in: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(theme.accentColor))
                    }
                }
                .frame(width: width, height: height)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .onTapGesture {
                    HapticManager.light()
                    if isWorldView {
                        focusNeighborhood(viewModel.currentCountryId, viewSize: viewSize, animated: true)
                    } else {
                        showWorldView(viewSize: viewSize)
                    }
                }
                .accessibilityLabel("World overview. Tap to toggle world view.")
            }
        }
    }

    private func recenterButton(viewSize: CGSize) -> some View {
        Button {
            HapticManager.light()
            focusNeighborhood(viewModel.currentCountryId, viewSize: viewSize, animated: true)
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18))
                .foregroundColor(theme.accentColor)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
        }
        .accessibilityLabel("Recenter on current country")
    }
}

// MARK: - Animated Map Content

/// Conforming to `Animatable` lets SwiftUI interpolate the camera itself, re-evaluating the
/// canvas (and edge indicators) at every animation step — vector-sharp at any zoom, with
/// labels and markers drawn at constant screen size.
private struct AnimatedMapContent: View, Animatable {
    var viewModel: BorderHopViewModel
    let renderer: MapRenderer
    var camera: MapCamera
    let viewSize: CGSize
    let colorScheme: ColorScheme
    let onTapCountry: (String) -> Void

    private let theme = GameTheme.borderHop

    var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, CGFloat> {
        get { AnimatablePair(AnimatablePair(camera.center.x, camera.center.y), camera.zoom) }
        set {
            camera.center = CGPoint(x: newValue.first.first, y: newValue.first.second)
            camera.zoom = newValue.second
        }
    }

    var body: some View {
        ZStack {
            Canvas { context, size in
                draw(context: context, size: size)
            }

            ForEach(edgeTargets) { target in
                EdgeIndicatorPill(target: target, accentColor: theme.accentColor) {
                    onTapCountry(target.id)
                }
                .position(target.position)
            }
        }
    }

    // MARK: Drawing

    private func draw(context: GraphicsContext, size: CGSize) {
        let isDark = colorScheme == .dark
        let visible = camera.visibleRect(viewSize: size)
        let worldWidth = renderer.canvasSize.width

        var shapeContext = context
        shapeContext.translateBy(x: size.width / 2, y: size.height / 2)
        shapeContext.scaleBy(x: camera.zoom, y: camera.zoom)
        shapeContext.translateBy(x: -camera.center.x, y: -camera.center.y)

        func drawWrapped(_ projected: MapRenderer.ProjectedCountry, _ body: (GraphicsContext, Path) -> Void) {
            for dx in [-worldWidth, 0, worldWidth] {
                guard projected.boundingBox.offsetBy(dx: dx, dy: 0).intersects(visible) else { continue }
                var ctx = shapeContext
                ctx.translateBy(x: dx, y: 0)
                body(ctx, Path(projected.path))
            }
        }

        // 1. Decorative (non-game) countries — subtle land masses
        let decorativeFill = isDark ? Color(hex: "2C2C2E").opacity(0.3) : Color(hex: "D5D0C8")
        let decorativeStroke = isDark ? Color.white.opacity(0.05) : Color(hex: "B8B4AF").opacity(0.4)
        for (_, projected) in renderer.decorativeCountries {
            drawWrapped(projected) { ctx, path in
                ctx.fill(path, with: .color(decorativeFill))
                ctx.stroke(path, with: .color(decorativeStroke), lineWidth: 0.5 / camera.zoom)
            }
        }

        // 2. Game countries, z-ordered so the important states draw on top
        let zOrder: [CountryState] = [.fogged, .visited, .frontier, .destination, .current]
        for targetState in zOrder {
            for (id, projected) in renderer.projectedCountries {
                let state = viewModel.countryStates[id] ?? .fogged
                guard state == targetState else { continue }
                drawWrapped(projected) { ctx, path in
                    drawCountryShape(context: ctx, path: path, state: state, isDark: isDark)
                }
            }
        }

        // 3. Trail, labels, and markers in screen space — constant size, always crisp
        drawTrail(context: context, size: size)
        drawLabels(context: context, size: size, isDark: isDark)
        drawMarkers(context: context, size: size)
    }

    private func drawCountryShape(context: GraphicsContext, path: Path, state: CountryState, isDark: Bool) {
        let accent = theme.accentColor
        let zoom = camera.zoom

        switch state {
        case .fogged:
            let fillColor = isDark ? Color(hex: "3A3A3C").opacity(0.6) : Color(hex: "C8C3BB")
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(isDark ? Color.white.opacity(0.08) : Color(hex: "9E9A94").opacity(0.5)), lineWidth: 0.5 / zoom)

        case .frontier:
            context.fill(path, with: .color(accent.opacity(isDark ? 0.30 : 0.24)))
            var glowContext = context
            glowContext.addFilter(.shadow(color: accent.opacity(0.5), radius: 6 / zoom))
            glowContext.stroke(path, with: .color(accent), lineWidth: 2 / zoom)

        case .visited:
            let fillColor = isDark
                ? AppTheme.darkMutedText.opacity(0.15)
                : AppTheme.mediumGray.opacity(0.20)
            context.fill(path, with: .color(fillColor))
            context.stroke(path, with: .color(accent.opacity(0.4)), style: StrokeStyle(lineWidth: 1 / zoom, dash: [4 / zoom, 3 / zoom]))

        case .current:
            context.fill(path, with: .color(isDark ? accent.opacity(0.9) : accent))
            context.stroke(path, with: .color(.white), lineWidth: 2 / zoom)

        case .destination:
            let gold = AppTheme.medalGold
            var glowContext = context
            glowContext.addFilter(.shadow(color: gold.opacity(0.6), radius: 8 / zoom))
            glowContext.stroke(path, with: .color(gold), lineWidth: 2.5 / zoom)
            context.fill(path, with: .color(gold.opacity(isDark ? 0.35 : 0.30)))
        }
    }

    /// Screen position of a country's centroid, picking the world-wrap copy nearest the camera
    private func screenPosition(of projected: MapRenderer.ProjectedCountry, size: CGSize) -> CGPoint {
        let wrapped = renderer.nearestWrapped(projected.centroid, to: camera.center)
        return camera.screenPoint(for: wrapped, viewSize: size)
    }

    private func drawTrail(context: GraphicsContext, size: CGSize) {
        guard viewModel.actualPath.count >= 2 else { return }

        var trailPath = Path()
        for (i, id) in viewModel.actualPath.enumerated() {
            guard let projected = renderer.projectedCountries[id] else { continue }
            let point = screenPosition(of: projected, size: size)
            if i == 0 {
                trailPath.move(to: point)
            } else {
                trailPath.addLine(to: point)
            }
        }

        context.stroke(
            trailPath,
            with: .color(theme.accentColor.opacity(0.55)),
            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
        )
    }

    /// Labels drawn at constant screen size with a soft halo, collision-avoided.
    /// Priority: current > destination > frontier > visited (visited only when zoomed in).
    private func drawLabels(context: GraphicsContext, size: CGSize, isDark: Bool) {
        struct LabelCandidate {
            let text: String
            let position: CGPoint
            let color: Color
            let bold: Bool
        }

        let frontierColor = isDark ? Color.white : AppTheme.deepCharcoal
        let destinationColor = isDark ? AppTheme.medalGold : Color(hex: "9A7B00")
        var candidates: [LabelCandidate] = []

        func name(_ id: String) -> String {
            viewModel.graph.country(for: id)?.name ?? ""
        }

        // 1. Current country
        if let projected = renderer.projectedCountries[viewModel.currentCountryId] {
            candidates.append(LabelCandidate(
                text: name(viewModel.currentCountryId),
                position: screenPosition(of: projected, size: size),
                color: .white, bold: true
            ))
        }

        // 2. Destination
        if viewModel.destinationCountryId != viewModel.currentCountryId,
           let projected = renderer.projectedCountries[viewModel.destinationCountryId] {
            candidates.append(LabelCandidate(
                text: name(viewModel.destinationCountryId),
                position: screenPosition(of: projected, size: size),
                color: destinationColor, bold: true
            ))
        }

        // 3. Frontier — sorted for stable label placement between frames
        let frontierIds = viewModel.countryStates
            .filter { $0.value == .frontier }
            .map { $0.key }
            .sorted()
        for id in frontierIds where id != viewModel.currentCountryId && id != viewModel.destinationCountryId {
            guard let projected = renderer.projectedCountries[id] else { continue }
            candidates.append(LabelCandidate(
                text: name(id),
                position: screenPosition(of: projected, size: size),
                color: frontierColor, bold: true
            ))
        }

        // 4. Visited — context only, when zoomed in enough to have room
        if camera.zoom >= 3 {
            let visitedIds = viewModel.countryStates
                .filter { $0.value == .visited }
                .map { $0.key }
                .sorted()
            for id in visitedIds {
                guard let projected = renderer.projectedCountries[id] else { continue }
                candidates.append(LabelCandidate(
                    text: name(id),
                    position: screenPosition(of: projected, size: size),
                    color: isDark ? AppTheme.darkMutedText : AppTheme.mediumGray, bold: false
                ))
            }
        }

        let screenBounds = CGRect(origin: .zero, size: size).insetBy(dx: -40, dy: -20)
        var placedRects: [CGRect] = []

        for candidate in candidates {
            guard screenBounds.contains(candidate.position) else { continue }

            let font: Font = candidate.bold ? .caption.weight(.semibold) : .caption2
            let resolved = context.resolve(
                Text(candidate.text).font(font).foregroundColor(candidate.color)
            )
            let textSize = resolved.measure(in: CGSize(width: 220, height: 50))
            let labelRect = CGRect(
                x: candidate.position.x - textSize.width / 2 - 2,
                y: candidate.position.y + 8,
                width: textSize.width + 4,
                height: textSize.height + 4
            )

            guard !placedRects.contains(where: { $0.intersects(labelRect) }) else { continue }
            placedRects.append(labelRect)

            var haloContext = context
            haloContext.addFilter(.shadow(
                color: isDark ? Color.black.opacity(0.8) : Color.white.opacity(0.9),
                radius: 1.5
            ))
            haloContext.draw(resolved, at: CGPoint(x: labelRect.minX + 2, y: labelRect.minY + 2), anchor: .topLeading)
        }
    }

    private func drawMarkers(context: GraphicsContext, size: CGSize) {
        let onScreen = CGRect(origin: .zero, size: size).insetBy(dx: -20, dy: -20)

        // Player marker on the current country
        if let current = renderer.projectedCountries[viewModel.currentCountryId] {
            let point = screenPosition(of: current, size: size)
            if onScreen.contains(point) {
                let markerRect = CGRect(x: point.x - 7, y: point.y - 20, width: 14, height: 14)
                var shadowContext = context
                shadowContext.addFilter(.shadow(color: .black.opacity(0.35), radius: 2, y: 1))
                shadowContext.fill(Circle().path(in: markerRect), with: .color(.white))
                context.fill(Circle().path(in: markerRect.insetBy(dx: 3.5, dy: 3.5)), with: .color(theme.accentColor))
            }
        }

        // Destination flag
        if viewModel.currentCountryId != viewModel.destinationCountryId,
           let dest = renderer.projectedCountries[viewModel.destinationCountryId] {
            let point = screenPosition(of: dest, size: size)
            if onScreen.contains(point) {
                let resolved = context.resolve(
                    Text(Image(systemName: "flag.checkered"))
                        .font(.system(size: 18))
                        .foregroundColor(AppTheme.medalGold)
                )
                var shadowContext = context
                shadowContext.addFilter(.shadow(color: .black.opacity(0.4), radius: 1.5))
                shadowContext.draw(resolved, at: CGPoint(x: point.x, y: point.y - 16))
            }
        }
    }

    // MARK: Edge Indicators

    /// Frontier countries and the destination that sit off-screen become tappable pills
    /// clamped to the screen edge, pointing toward their real position — the player always
    /// sees every available move and where the goal is.
    private var edgeTargets: [EdgeTarget] {
        guard !viewModel.hasArrived, viewSize.width > 0 else { return [] }

        let bounds = CGRect(origin: .zero, size: viewSize)
        // Keep pills clear of the HUD (top), destination bar (bottom), and mini-map (trailing)
        let safeArea = CGRect(
            x: 16, y: 72,
            width: bounds.width - 32,
            height: bounds.height - 72 - 104
        )

        var ids = viewModel.countryStates
            .filter { $0.value == .frontier }
            .map { $0.key }
            .sorted()
        if viewModel.destinationCountryId != viewModel.currentCountryId,
           !ids.contains(viewModel.destinationCountryId) {
            ids.append(viewModel.destinationCountryId)
        }

        var targets: [EdgeTarget] = []
        var placedRects: [CGRect] = []

        for id in ids {
            guard let projected = renderer.projectedCountries[id] else { continue }
            let real = screenPosition(of: projected, size: viewSize)
            guard !bounds.insetBy(dx: 16, dy: 16).contains(real) else { continue }

            var clamped = CGPoint(
                x: min(max(real.x, safeArea.minX + 44), safeArea.maxX - 44),
                y: min(max(real.y, safeArea.minY + 16), safeArea.maxY - 16)
            )
            let angle = Angle(radians: atan2(real.y - clamped.y, real.x - clamped.x))

            // Nudge down if overlapping an already-placed pill
            var pillRect = CGRect(x: clamped.x - 55, y: clamped.y - 16, width: 110, height: 32)
            var attempts = 0
            while placedRects.contains(where: { $0.intersects(pillRect) }), attempts < 8 {
                clamped.y += 36
                pillRect = pillRect.offsetBy(dx: 0, dy: 36)
                attempts += 1
            }
            placedRects.append(pillRect)

            targets.append(EdgeTarget(
                id: id,
                name: viewModel.graph.country(for: id)?.name ?? id,
                position: clamped,
                angle: angle,
                isDestination: id == viewModel.destinationCountryId
            ))
        }
        return targets
    }
}

// MARK: - Edge Indicator

private struct EdgeTarget: Identifiable {
    let id: String
    let name: String
    let position: CGPoint
    let angle: Angle
    let isDestination: Bool
}

private struct EdgeIndicatorPill: View {
    let target: EdgeTarget
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.xs) {
                if target.isDestination {
                    Image(systemName: "flag.checkered")
                        .font(.caption2)
                        .foregroundColor(AppTheme.medalGold)
                }
                Text(target.name)
                    .font(AppTheme.Typography.pillLabel)
                    .lineLimit(1)
                Image(systemName: "arrowtriangle.right.fill")
                    .font(.system(size: 8))
                    .rotationEffect(target.angle)
                    .foregroundColor(target.isDestination ? AppTheme.medalGold : accentColor)
            }
            .padding(.horizontal, AppTheme.Spacing.sm)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().stroke(
                    target.isDestination ? AppTheme.medalGold : accentColor,
                    lineWidth: 1.5
                )
            )
        }
        .pressable()
    }
}
