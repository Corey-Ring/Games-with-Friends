import SwiftUI

// ART_DIRECTION §6: spot illustrations replace decorative SF Symbols. Flat
// candy fills, 3 pt ink outlines in a 64 pt art box, rounded joins, faces per
// Rule 6, at most one sparkle garnish per spot. The first six are ported from
// the adopted Option C artboard SVGs; the three below-the-fold games follow
// the same recipe.
enum RetroSpotKind: CaseIterable, Hashable {
    case speechBubbles   // Conversation Starters
    case globe           // Country Letter Challenge
    case burstFive       // Name 5
    case borderMap       // Border Blitz
    case filmFrame       // Movie Chain
    case starFace        // Casting Director
    case heart           // Vibe Check
    case suitcase        // Border Hop
    case clapperboard    // Finish the Line

    init?(gameID: String) {
        switch gameID {
        case "conversation-starters": self = .speechBubbles
        case "country-letter-game": self = .globe
        case "name-5-game": self = .burstFive
        case "border-blitz": self = .borderMap
        case "movie-chain": self = .filmFrame
        case "casting-director": self = .starFace
        case "vibecheck": self = .heart
        case "border-hop": self = .suitcase
        case "finish-the-line": self = .clapperboard
        default: return nil
        }
    }
}

/// One spot illustration, scaled to fit its container. Decorative — hidden
/// from accessibility (hub cards carry the game name as their label).
struct RetroSpotIllustration: View {
    let kind: RetroSpotKind

    var body: some View {
        Canvas { context, size in
            let scale = min(size.width, size.height) / 64
            context.scaleBy(x: scale, y: scale)
            RetroSpotPainter.draw(kind, in: &context)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Painter

enum RetroSpotPainter {
    private static let ink = AppTheme.Retro.ink

    static func draw(_ kind: RetroSpotKind, in context: inout GraphicsContext) {
        switch kind {
        case .speechBubbles: speechBubbles(&context)
        case .globe: globe(&context)
        case .burstFive: burstFive(&context)
        case .borderMap: borderMap(&context)
        case .filmFrame: filmFrame(&context)
        case .starFace: starFace(&context)
        case .heart: heart(&context)
        case .suitcase: suitcase(&context)
        case .clapperboard: clapperboard(&context)
        }
    }

    // MARK: Shared vocabulary

    /// Flat fill + uniform ink outline (Rules 1 and 2).
    private static func paint(_ c: inout GraphicsContext, _ path: Path,
                              fill: Color, lineWidth: CGFloat = 3) {
        c.fill(path, with: .color(fill))
        c.stroke(path, with: .color(ink),
                 style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
    }

    /// Dot eyes + smile (Rule 6). Cream on dark fills, ink on light fills.
    private static func face(_ c: inout GraphicsContext,
                             leftEye: CGPoint, rightEye: CGPoint,
                             color: Color = AppTheme.Retro.ink) {
        for eye in [leftEye, rightEye] {
            let dot = Path(ellipseIn: CGRect(x: eye.x - 1.8, y: eye.y - 1.8,
                                             width: 3.6, height: 3.6))
            c.fill(dot, with: .color(color))
        }
        var smile = Path()
        smile.move(to: CGPoint(x: leftEye.x, y: leftEye.y + 5))
        smile.addQuadCurve(to: CGPoint(x: rightEye.x, y: rightEye.y + 5),
                           control: CGPoint(x: (leftEye.x + rightEye.x) / 2,
                                            y: leftEye.y + 9))
        c.stroke(smile, with: .color(color),
                 style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
    }

    private static func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat) -> Path {
        var p = Path()
        for i in 0..<10 {
            let r = i.isMultiple(of: 2) ? outer : inner
            let angle = Angle(degrees: Double(i) * 36 - 90).radians
            let pt = CGPoint(x: center.x + r * CGFloat(cos(angle)),
                             y: center.y + r * CGFloat(sin(angle)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }

    private static func sparklePath(center: CGPoint, r: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: center.x, y: center.y - r))
        p.addLine(to: CGPoint(x: center.x + r * 0.25, y: center.y - r * 0.25))
        p.addLine(to: CGPoint(x: center.x + r, y: center.y))
        p.addLine(to: CGPoint(x: center.x + r * 0.25, y: center.y + r * 0.25))
        p.addLine(to: CGPoint(x: center.x, y: center.y + r))
        p.addLine(to: CGPoint(x: center.x - r * 0.25, y: center.y + r * 0.25))
        p.addLine(to: CGPoint(x: center.x - r, y: center.y))
        p.addLine(to: CGPoint(x: center.x - r * 0.25, y: center.y - r * 0.25))
        p.closeSubpath()
        return p
    }

    // MARK: Conversation Starters — two chatting bubbles

    private static func speechBubbles(_ c: inout GraphicsContext) {
        var big = Path()
        big.move(to: CGPoint(x: 8, y: 14))
        big.addLine(to: CGPoint(x: 38, y: 14))
        big.addQuadCurve(to: CGPoint(x: 43, y: 19), control: CGPoint(x: 43, y: 14))
        big.addLine(to: CGPoint(x: 43, y: 33))
        big.addQuadCurve(to: CGPoint(x: 38, y: 38), control: CGPoint(x: 43, y: 38))
        big.addLine(to: CGPoint(x: 22, y: 38))
        big.addLine(to: CGPoint(x: 13, y: 46))
        big.addLine(to: CGPoint(x: 13, y: 38))
        big.addLine(to: CGPoint(x: 8, y: 38))
        big.addQuadCurve(to: CGPoint(x: 3, y: 33), control: CGPoint(x: 3, y: 38))
        big.addLine(to: CGPoint(x: 3, y: 19))
        big.addQuadCurve(to: CGPoint(x: 8, y: 14), control: CGPoint(x: 3, y: 14))
        big.closeSubpath()
        paint(&c, big, fill: AppTheme.Retro.bubblegum)
        face(&c, leftEye: CGPoint(x: 18, y: 24), rightEye: CGPoint(x: 28, y: 24))

        var small = Path()
        small.move(to: CGPoint(x: 44, y: 30))
        small.addLine(to: CGPoint(x: 54, y: 30))
        small.addQuadCurve(to: CGPoint(x: 58, y: 34), control: CGPoint(x: 58, y: 30))
        small.addLine(to: CGPoint(x: 58, y: 42))
        small.addQuadCurve(to: CGPoint(x: 54, y: 46), control: CGPoint(x: 58, y: 46))
        small.addLine(to: CGPoint(x: 54, y: 52))
        small.addLine(to: CGPoint(x: 47, y: 46))
        small.addLine(to: CGPoint(x: 44, y: 46))
        small.addQuadCurve(to: CGPoint(x: 40, y: 42), control: CGPoint(x: 40, y: 46))
        small.addLine(to: CGPoint(x: 40, y: 34))
        small.addQuadCurve(to: CGPoint(x: 44, y: 30), control: CGPoint(x: 40, y: 30))
        small.closeSubpath()
        paint(&c, small, fill: AppTheme.Retro.poolBlue)
    }

    // MARK: Country Letter Challenge — smiling globe

    private static func globe(_ c: inout GraphicsContext) {
        let sphere = Path(ellipseIn: CGRect(x: 10, y: 10, width: 44, height: 44))
        paint(&c, sphere, fill: AppTheme.Retro.grass)

        var lat1 = Path()
        lat1.move(to: CGPoint(x: 12, y: 26))
        lat1.addQuadCurve(to: CGPoint(x: 32, y: 26), control: CGPoint(x: 22, y: 32))
        lat1.addQuadCurve(to: CGPoint(x: 50, y: 28), control: CGPoint(x: 42, y: 20))
        var lat2 = Path()
        lat2.move(to: CGPoint(x: 14, y: 42))
        lat2.addQuadCurve(to: CGPoint(x: 32, y: 42), control: CGPoint(x: 23, y: 37))
        lat2.addQuadCurve(to: CGPoint(x: 48, y: 40), control: CGPoint(x: 41, y: 47))
        for lat in [lat1, lat2] {
            c.stroke(lat, with: .color(AppTheme.Retro.cream),
                     style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        face(&c, leftEye: CGPoint(x: 26, y: 30), rightEye: CGPoint(x: 38, y: 30))
    }

    // MARK: Name 5 — sixteen-point burst with a big 5

    private static func burstFive(_ c: inout GraphicsContext) {
        let pts: [CGPoint] = [
            CGPoint(x: 32, y: 4), CGPoint(x: 37, y: 18), CGPoint(x: 51, y: 12),
            CGPoint(x: 45, y: 25), CGPoint(x: 60, y: 28), CGPoint(x: 46, y: 34),
            CGPoint(x: 54, y: 46), CGPoint(x: 40, y: 42), CGPoint(x: 38, y: 58),
            CGPoint(x: 30, y: 45), CGPoint(x: 20, y: 54), CGPoint(x: 23, y: 39),
            CGPoint(x: 8, y: 38), CGPoint(x: 21, y: 30), CGPoint(x: 12, y: 16),
            CGPoint(x: 27, y: 21)
        ]
        var burst = Path()
        burst.move(to: pts[0])
        for p in pts.dropFirst() { burst.addLine(to: p) }
        burst.closeSubpath()
        paint(&c, burst, fill: AppTheme.Retro.tomato)

        let five = Text("5").font(AppTheme.Retro.Typography.heading(22, relativeTo: .title2))
        c.draw(five.foregroundStyle(ink), at: CGPoint(x: 33.2, y: 33.2))
        c.draw(five.foregroundStyle(Color.white), at: CGPoint(x: 32, y: 32))
    }

    // MARK: Border Blitz — country blob with dashed borders and a flag

    private static func borderMap(_ c: inout GraphicsContext) {
        var blob = Path()
        blob.move(to: CGPoint(x: 10, y: 20))
        blob.addQuadCurve(to: CGPoint(x: 26, y: 10), control: CGPoint(x: 14, y: 8))
        blob.addQuadCurve(to: CGPoint(x: 40, y: 8), control: CGPoint(x: 34, y: 12))
        blob.addQuadCurve(to: CGPoint(x: 56, y: 16), control: CGPoint(x: 52, y: 4))
        blob.addQuadCurve(to: CGPoint(x: 52, y: 32), control: CGPoint(x: 59, y: 26))
        blob.addQuadCurve(to: CGPoint(x: 48, y: 44), control: CGPoint(x: 46, y: 37))
        blob.addQuadCurve(to: CGPoint(x: 40, y: 53), control: CGPoint(x: 49, y: 52))
        blob.addQuadCurve(to: CGPoint(x: 28, y: 47), control: CGPoint(x: 31, y: 54))
        blob.addQuadCurve(to: CGPoint(x: 19, y: 41), control: CGPoint(x: 26, y: 41))
        blob.addQuadCurve(to: CGPoint(x: 8, y: 31), control: CGPoint(x: 9, y: 40))
        blob.addQuadCurve(to: CGPoint(x: 10, y: 20), control: CGPoint(x: 7, y: 24))
        blob.closeSubpath()
        paint(&c, blob, fill: AppTheme.Retro.poolBlue)

        var b1 = Path()
        b1.move(to: CGPoint(x: 20, y: 26))
        b1.addQuadCurve(to: CGPoint(x: 44, y: 30), control: CGPoint(x: 28, y: 34))
        var b2 = Path()
        b2.move(to: CGPoint(x: 24, y: 42))
        b2.addQuadCurve(to: CGPoint(x: 38, y: 44), control: CGPoint(x: 32, y: 40))
        for border in [b1, b2] {
            c.stroke(border, with: .color(.white),
                     style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [4, 4]))
        }

        var flag = Path()
        flag.move(to: CGPoint(x: 40, y: 14))
        flag.addLine(to: CGPoint(x: 40, y: 6))
        flag.addLine(to: CGPoint(x: 50, y: 9))
        flag.addLine(to: CGPoint(x: 40, y: 12))
        flag.closeSubpath()
        paint(&c, flag, fill: AppTheme.Retro.tomato, lineWidth: 2)
    }

    // MARK: Movie Chain — film frame with a star

    private static func filmFrame(_ c: inout GraphicsContext) {
        let frame = Path(roundedRect: CGRect(x: 6, y: 16, width: 52, height: 34),
                         cornerRadius: 5)
        paint(&c, frame, fill: AppTheme.Retro.mustard)
        var rails = Path()
        rails.move(to: CGPoint(x: 16, y: 16))
        rails.addLine(to: CGPoint(x: 16, y: 50))
        rails.move(to: CGPoint(x: 48, y: 16))
        rails.addLine(to: CGPoint(x: 48, y: 50))
        c.stroke(rails, with: .color(ink), style: StrokeStyle(lineWidth: 2.4))
        let star = starPath(center: CGPoint(x: 32, y: 33), outer: 9, inner: 3.6)
        paint(&c, star, fill: AppTheme.Retro.tomato, lineWidth: 2)
    }

    // MARK: Casting Director — smiling star

    private static func starFace(_ c: inout GraphicsContext) {
        let star = starPath(center: CGPoint(x: 32, y: 29), outer: 24, inner: 9.5)
        paint(&c, star, fill: AppTheme.Retro.tangerine)
        face(&c, leftEye: CGPoint(x: 27, y: 26), rightEye: CGPoint(x: 37, y: 26))
    }

    // MARK: Vibe Check — smiling heart (new, berry)

    private static func heart(_ c: inout GraphicsContext) {
        var h = Path()
        h.move(to: CGPoint(x: 32, y: 54))
        h.addCurve(to: CGPoint(x: 11, y: 18),
                   control1: CGPoint(x: 12, y: 40), control2: CGPoint(x: 6, y: 27))
        h.addCurve(to: CGPoint(x: 32, y: 16),
                   control1: CGPoint(x: 16, y: 8), control2: CGPoint(x: 28, y: 8))
        h.addCurve(to: CGPoint(x: 53, y: 18),
                   control1: CGPoint(x: 36, y: 8), control2: CGPoint(x: 48, y: 8))
        h.addCurve(to: CGPoint(x: 32, y: 54),
                   control1: CGPoint(x: 58, y: 27), control2: CGPoint(x: 52, y: 40))
        h.closeSubpath()
        paint(&c, h, fill: AppTheme.Retro.berry)
        face(&c, leftEye: CGPoint(x: 26, y: 27), rightEye: CGPoint(x: 38, y: 27),
             color: AppTheme.Retro.cream)
        let sparkle = sparklePath(center: CGPoint(x: 56, y: 9), r: 6)
        paint(&c, sparkle, fill: AppTheme.Retro.cream, lineWidth: 2)
    }

    // MARK: Border Hop — hopping suitcase (new, cornflower)

    private static func suitcase(_ c: inout GraphicsContext) {
        let handle = Path(roundedRect: CGRect(x: 24, y: 14, width: 16, height: 10),
                          cornerRadius: 4)
        paint(&c, handle, fill: AppTheme.Retro.cornflower, lineWidth: 2.4)
        let body = Path(roundedRect: CGRect(x: 10, y: 22, width: 44, height: 30),
                        cornerRadius: 6)
        paint(&c, body, fill: AppTheme.Retro.cornflower)
        let sticker = Path(ellipseIn: CGRect(x: 42, y: 27, width: 9, height: 9))
        paint(&c, sticker, fill: AppTheme.Retro.cream, lineWidth: 2)
        face(&c, leftEye: CGPoint(x: 23, y: 36), rightEye: CGPoint(x: 33, y: 36))
        var hop = Path()
        hop.move(to: CGPoint(x: 6, y: 14))
        hop.addQuadCurve(to: CGPoint(x: 20, y: 8), control: CGPoint(x: 10, y: 4))
        c.stroke(hop, with: .color(ink),
                 style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [3, 4]))
    }

    // MARK: Finish the Line — smiling clapperboard (new, plum)

    private static func clapperboard(_ c: inout GraphicsContext) {
        let bar = Path(roundedRect: CGRect(x: 8, y: 16, width: 48, height: 11),
                       cornerRadius: 3)
        c.fill(bar, with: .color(AppTheme.Retro.plum))
        var striped = c
        striped.clip(to: bar)
        for i in 0..<4 {
            let x0 = CGFloat(10 + i * 12)
            var s = Path()
            s.move(to: CGPoint(x: x0, y: 27))
            s.addLine(to: CGPoint(x: x0 + 5, y: 16))
            s.addLine(to: CGPoint(x: x0 + 10, y: 16))
            s.addLine(to: CGPoint(x: x0 + 5, y: 27))
            s.closeSubpath()
            striped.fill(s, with: .color(AppTheme.Retro.cream))
        }
        c.stroke(bar, with: .color(ink),
                 style: StrokeStyle(lineWidth: 3, lineJoin: .round))
        let board = Path(roundedRect: CGRect(x: 8, y: 29, width: 48, height: 24),
                         cornerRadius: 4)
        paint(&c, board, fill: AppTheme.Retro.plum)
        face(&c, leftEye: CGPoint(x: 26, y: 38), rightEye: CGPoint(x: 38, y: 38),
             color: AppTheme.Retro.cream)
        let sparkle = sparklePath(center: CGPoint(x: 58, y: 8), r: 5)
        paint(&c, sparkle, fill: AppTheme.Retro.cream, lineWidth: 2)
    }
}

// MARK: - Preview

#Preview("Retro Spots") {
    ZStack {
        AppTheme.Retro.ground.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
            ForEach(RetroSpotKind.allCases, id: \.self) { kind in
                ZStack {
                    Circle().fill(AppTheme.Retro.panel)
                    Circle().stroke(AppTheme.Retro.ink,
                                    lineWidth: AppTheme.Retro.strokeWidth)
                    RetroSpotIllustration(kind: kind)
                        .padding(8)
                }
                .frame(width: 80, height: 80)
            }
        }
        .padding()
    }
}
