import SwiftUI

// ART_DIRECTION §6: spot illustrations replace decorative SF Symbols. Flat
// candy fills, 3 pt ink outlines in a 64 pt art box, rounded joins, faces per
// Rule 6, at most one sparkle garnish per spot. Most are ported from the
// adopted Option C artboard SVGs; the 2026-08-25 globe-flag / bubble-five and
// 2026-09-06 Border Blitz / Border Hop / Finish the Line redesigns follow the
// same recipe (the latter three add the bubble-five's hard offset shadow).
enum RetroSpotKind: CaseIterable, Hashable {
    case speechBubbles   // Conversation Starters
    case globe           // Country Letter Challenge
    case bubbleFive      // Name 5
    case borderMap       // Border Blitz
    case filmFrame       // Movie Chain
    case starFace        // Casting Director
    case heart           // Vibe Check
    case hopMap          // Border Hop
    case quoteBubble     // Finish the Line

    init?(gameID: String) {
        switch gameID {
        case "conversation-starters": self = .speechBubbles
        case "country-letter-game": self = .globe
        case "name-5-game": self = .bubbleFive
        case "border-blitz": self = .borderMap
        case "movie-chain": self = .filmFrame
        case "casting-director": self = .starFace
        case "vibecheck": self = .heart
        case "border-hop": self = .hopMap
        case "finish-the-line": self = .quoteBubble
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
        case .bubbleFive: bubbleFive(&context)
        case .borderMap: borderMap(&context)
        case .filmFrame: filmFrame(&context)
        case .starFace: starFace(&context)
        case .heart: heart(&context)
        case .hopMap: hopMap(&context)
        case .quoteBubble: quoteBubble(&context)
        }
    }

    // MARK: Shared vocabulary

    /// Flat fill + uniform ink outline (Rules 1 and 2); `shadow` adds the
    /// hard ink offset (x == y, no blur) that bubbleFive introduced.
    private static func paint(_ c: inout GraphicsContext, _ path: Path,
                              fill: Color, lineWidth: CGFloat = 3,
                              shadow: CGFloat? = nil) {
        if let shadow {
            c.fill(path.applying(CGAffineTransform(translationX: shadow, y: shadow)),
                   with: .color(ink))
        }
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

    // MARK: Country Letter Challenge — smiling globe flying a letter flag

    private static func globe(_ c: inout GraphicsContext) {
        // Flag rides high so a stretch of bare pole shows between its
        // bottom edge and the sphere — that gap is what makes it read as
        // planted in the north pole rather than stuck on like a sticker.
        let flag = Path(roundedRect: CGRect(x: 37, y: 1, width: 18, height: 11),
                        cornerRadius: 2.5)
        paint(&c, flag, fill: AppTheme.Retro.tomato, lineWidth: 2.4)
        let letter = Text("A").font(AppTheme.Retro.Typography.heading(9.5, relativeTo: .caption))
        c.draw(letter.foregroundStyle(ink), at: CGPoint(x: 46.7, y: 7.2))
        c.draw(letter.foregroundStyle(AppTheme.Retro.cream), at: CGPoint(x: 46, y: 6.5))

        var pole = Path()
        pole.move(to: CGPoint(x: 36, y: 19))
        pole.addLine(to: CGPoint(x: 36, y: 1))
        c.stroke(pole, with: .color(ink),
                 style: StrokeStyle(lineWidth: 2.4, lineCap: .round))

        // Blue ocean with green continents clipped by the rim — the classic
        // cartoon-Earth read. Face floats in open water.
        let sphere = Path(ellipseIn: CGRect(x: 10, y: 17, width: 44, height: 44))
        c.fill(sphere, with: .color(AppTheme.Retro.poolBlue))

        var land1 = Path()
        land1.move(to: CGPoint(x: 8, y: 26))
        land1.addQuadCurve(to: CGPoint(x: 21, y: 19), control: CGPoint(x: 13, y: 18))
        land1.addQuadCurve(to: CGPoint(x: 28, y: 26), control: CGPoint(x: 29, y: 20))
        land1.addQuadCurve(to: CGPoint(x: 20, y: 32), control: CGPoint(x: 27, y: 31))
        land1.addQuadCurve(to: CGPoint(x: 8, y: 26), control: CGPoint(x: 12, y: 33))
        land1.closeSubpath()
        var land2 = Path()
        land2.move(to: CGPoint(x: 47.5, y: 25.5))
        land2.addQuadCurve(to: CGPoint(x: 57, y: 30), control: CGPoint(x: 54.5, y: 23.5))
        land2.addQuadCurve(to: CGPoint(x: 54.5, y: 42), control: CGPoint(x: 59, y: 37))
        land2.addQuadCurve(to: CGPoint(x: 47, y: 41), control: CGPoint(x: 50, y: 45.5))
        land2.addQuadCurve(to: CGPoint(x: 46.5, y: 33.5), control: CGPoint(x: 45.5, y: 38))
        land2.addQuadCurve(to: CGPoint(x: 47.5, y: 25.5), control: CGPoint(x: 47.5, y: 29))
        land2.closeSubpath()
        var land3 = Path()
        land3.move(to: CGPoint(x: 22, y: 54))
        land3.addQuadCurve(to: CGPoint(x: 32, y: 52), control: CGPoint(x: 26, y: 50))
        land3.addQuadCurve(to: CGPoint(x: 34, y: 58), control: CGPoint(x: 37, y: 54))
        land3.addQuadCurve(to: CGPoint(x: 25, y: 60), control: CGPoint(x: 30, y: 62))
        land3.addQuadCurve(to: CGPoint(x: 22, y: 54), control: CGPoint(x: 21, y: 58))
        land3.closeSubpath()

        var ocean = c
        ocean.clip(to: sphere)
        for land in [land1, land2, land3] {
            ocean.fill(land, with: .color(AppTheme.Retro.grass))
            ocean.stroke(land, with: .color(ink),
                         style: StrokeStyle(lineWidth: 2.4, lineJoin: .round))
        }
        c.stroke(sphere, with: .color(ink),
                 style: StrokeStyle(lineWidth: 3, lineJoin: .round))

        face(&c, leftEye: CGPoint(x: 26, y: 38), rightEye: CGPoint(x: 37, y: 38))
    }

    // MARK: Name 5 — chunky bubble-letter 5

    private static func bubbleFive(_ c: inout GraphicsContext) {
        // 70s bubble-letter "5" (mural-coming-soon reference / Rule 4):
        // one fat marker-stroke skeleton rendered three times — ink hard
        // offset shadow, ink keyline tube, lilac face.
        var five = Path()
        five.move(to: CGPoint(x: 43, y: 11.5))
        five.addLine(to: CGPoint(x: 23.5, y: 11.5))
        five.addLine(to: CGPoint(x: 23.5, y: 28.5))
        five.addCurve(to: CGPoint(x: 46, y: 41),
                      control1: CGPoint(x: 38, y: 25.5),
                      control2: CGPoint(x: 46, y: 32))
        five.addCurve(to: CGPoint(x: 28, y: 54),
                      control1: CGPoint(x: 46, y: 50),
                      control2: CGPoint(x: 37, y: 55))
        five.addCurve(to: CGPoint(x: 20.5, y: 50),
                      control1: CGPoint(x: 24.5, y: 53.5),
                      control2: CGPoint(x: 22, y: 52))

        let tube = StrokeStyle(lineWidth: 15.5, lineCap: .round, lineJoin: .round)
        let shadow = five.applying(CGAffineTransform(translationX: 3.5, y: 3.5))
        c.stroke(shadow, with: .color(ink), style: tube)
        c.stroke(five, with: .color(ink), style: tube)
        c.stroke(five, with: .color(AppTheme.Retro.lilac),
                 style: StrokeStyle(lineWidth: 10.5, lineCap: .round, lineJoin: .round))

        let sparkle = sparklePath(center: CGPoint(x: 9, y: 9), r: 5.5)
        paint(&c, sparkle, fill: AppTheme.Retro.cream, lineWidth: 2)
    }

    // MARK: Border Blitz — smiling country struck by a bolt

    private static func borderMap(_ c: inout GraphicsContext) {
        // Cartographic rather than cloud-like: straight coastal runs, one
        // bay on the west, one peninsula on the south-east. The bolt lands
        // on the east coast so the face keeps the open west half.
        var land = Path()
        land.move(to: CGPoint(x: 4, y: 15))
        land.addLine(to: CGPoint(x: 24, y: 11))
        land.addQuadCurve(to: CGPoint(x: 40, y: 13), control: CGPoint(x: 34, y: 8))
        land.addLine(to: CGPoint(x: 38, y: 25))
        land.addQuadCurve(to: CGPoint(x: 50, y: 45), control: CGPoint(x: 48, y: 31))
        land.addLine(to: CGPoint(x: 44, y: 53))
        land.addQuadCurve(to: CGPoint(x: 30, y: 55), control: CGPoint(x: 36, y: 49))
        land.addLine(to: CGPoint(x: 18, y: 57))
        land.addQuadCurve(to: CGPoint(x: 6, y: 45), control: CGPoint(x: 6, y: 55))
        land.addQuadCurve(to: CGPoint(x: 6, y: 27), control: CGPoint(x: 0, y: 35))
        land.closeSubpath()
        paint(&c, land, fill: AppTheme.Retro.poolBlue, shadow: 3.5)
        face(&c, leftEye: CGPoint(x: 20, y: 30), rightEye: CGPoint(x: 32, y: 30))

        var bolt = Path()
        bolt.move(to: CGPoint(x: 51, y: 10))
        bolt.addLine(to: CGPoint(x: 40, y: 32))
        bolt.addLine(to: CGPoint(x: 48, y: 32))
        bolt.addLine(to: CGPoint(x: 42, y: 50))
        bolt.addLine(to: CGPoint(x: 61, y: 26))
        bolt.addLine(to: CGPoint(x: 53, y: 26))
        bolt.addLine(to: CGPoint(x: 59, y: 10))
        bolt.closeSubpath()
        paint(&c, bolt, fill: AppTheme.Retro.tomato, lineWidth: 2.6, shadow: 2.5)
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

    // MARK: Border Hop — pin hopping a shared border (cornflower)

    private static func hopMap(_ c: inout GraphicsContext) {
        // Two neighbours drawn as one landmass (single hard shadow) split
        // by a dashed wavy border; the tomato pin has just landed in the
        // grass destination, the dashed arc shows where it hopped from.
        var landmass = Path()
        landmass.move(to: CGPoint(x: 4, y: 30))
        landmass.addQuadCurve(to: CGPoint(x: 26, y: 22), control: CGPoint(x: 10, y: 14))
        landmass.addQuadCurve(to: CGPoint(x: 60, y: 24), control: CGPoint(x: 44, y: 10))
        landmass.addQuadCurve(to: CGPoint(x: 58, y: 54), control: CGPoint(x: 66, y: 42))
        landmass.addQuadCurve(to: CGPoint(x: 30, y: 60), control: CGPoint(x: 46, y: 64))
        landmass.addQuadCurve(to: CGPoint(x: 8, y: 56), control: CGPoint(x: 16, y: 63))
        landmass.addQuadCurve(to: CGPoint(x: 4, y: 30), control: CGPoint(x: -1, y: 46))
        landmass.closeSubpath()
        c.fill(landmass.applying(CGAffineTransform(translationX: 3.5, y: 3.5)),
               with: .color(ink))

        var border = Path()
        border.move(to: CGPoint(x: 26, y: 22))
        border.addQuadCurve(to: CGPoint(x: 28, y: 42), control: CGPoint(x: 38, y: 34))
        border.addQuadCurve(to: CGPoint(x: 30, y: 60), control: CGPoint(x: 22, y: 50))

        var west = Path()
        west.move(to: CGPoint(x: 4, y: 30))
        west.addQuadCurve(to: CGPoint(x: 26, y: 22), control: CGPoint(x: 10, y: 14))
        west.addQuadCurve(to: CGPoint(x: 28, y: 42), control: CGPoint(x: 38, y: 34))
        west.addQuadCurve(to: CGPoint(x: 30, y: 60), control: CGPoint(x: 22, y: 50))
        west.addQuadCurve(to: CGPoint(x: 8, y: 56), control: CGPoint(x: 16, y: 63))
        west.addQuadCurve(to: CGPoint(x: 4, y: 30), control: CGPoint(x: -1, y: 46))
        west.closeSubpath()
        paint(&c, west, fill: AppTheme.Retro.cornflower, lineWidth: 2.6)

        var east = Path()
        east.move(to: CGPoint(x: 26, y: 22))
        east.addQuadCurve(to: CGPoint(x: 60, y: 24), control: CGPoint(x: 44, y: 10))
        east.addQuadCurve(to: CGPoint(x: 58, y: 54), control: CGPoint(x: 66, y: 42))
        east.addQuadCurve(to: CGPoint(x: 30, y: 60), control: CGPoint(x: 46, y: 64))
        east.addQuadCurve(to: CGPoint(x: 28, y: 42), control: CGPoint(x: 22, y: 50))
        east.addQuadCurve(to: CGPoint(x: 26, y: 22), control: CGPoint(x: 38, y: 34))
        east.closeSubpath()
        paint(&c, east, fill: AppTheme.Retro.grass, lineWidth: 2.6)
        c.stroke(border, with: .color(ink),
                 style: StrokeStyle(lineWidth: 2.6, lineCap: .round, dash: [3.5, 3]))

        var hop = Path()
        hop.move(to: CGPoint(x: 14, y: 36))
        hop.addQuadCurve(to: CGPoint(x: 42, y: 12), control: CGPoint(x: 20, y: 4))
        c.stroke(hop, with: .color(ink),
                 style: StrokeStyle(lineWidth: 2.4, lineCap: .round, dash: [3, 4]))

        var pin = Path()
        pin.move(to: CGPoint(x: 45, y: 40))
        pin.addCurve(to: CGPoint(x: 35, y: 21),
                     control1: CGPoint(x: 45, y: 40), control2: CGPoint(x: 35, y: 31))
        pin.addArc(center: CGPoint(x: 45, y: 21), radius: 10,
                   startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        pin.addCurve(to: CGPoint(x: 45, y: 40),
                     control1: CGPoint(x: 55, y: 31), control2: CGPoint(x: 45, y: 40))
        pin.closeSubpath()
        paint(&c, pin, fill: AppTheme.Retro.tomato, lineWidth: 2.4, shadow: 2.5)
        face(&c, leftEye: CGPoint(x: 41.5, y: 19.5), rightEye: CGPoint(x: 48.5, y: 19.5),
             color: AppTheme.Retro.cream)
    }

    // MARK: Finish the Line — "I know this…" speech bubble (plum)

    private static func quoteBubble(_ c: inout GraphicsContext) {
        var bubble = Path()
        bubble.move(to: CGPoint(x: 14, y: 8))
        bubble.addLine(to: CGPoint(x: 50, y: 8))
        bubble.addQuadCurve(to: CGPoint(x: 58, y: 16), control: CGPoint(x: 58, y: 8))
        bubble.addLine(to: CGPoint(x: 58, y: 36))
        bubble.addQuadCurve(to: CGPoint(x: 50, y: 44), control: CGPoint(x: 58, y: 44))
        bubble.addLine(to: CGPoint(x: 26, y: 44))
        bubble.addLine(to: CGPoint(x: 14, y: 55))
        bubble.addLine(to: CGPoint(x: 14, y: 44))
        bubble.addQuadCurve(to: CGPoint(x: 6, y: 36), control: CGPoint(x: 6, y: 44))
        bubble.addLine(to: CGPoint(x: 6, y: 16))
        bubble.addQuadCurve(to: CGPoint(x: 14, y: 8), control: CGPoint(x: 6, y: 8))
        bubble.closeSubpath()
        paint(&c, bubble, fill: AppTheme.Retro.plum, shadow: 3.5)

        // The tip-of-tongue ellipsis: three cream dots, ink-ringed.
        for x in [20.0, 32.0, 44.0] {
            let dot = Path(ellipseIn: CGRect(x: x - 4.6, y: 21.4, width: 9.2, height: 9.2))
            paint(&c, dot, fill: AppTheme.Retro.cream, lineWidth: 2)
        }
        let sparkle = sparklePath(center: CGPoint(x: 58, y: 6), r: 5)
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
