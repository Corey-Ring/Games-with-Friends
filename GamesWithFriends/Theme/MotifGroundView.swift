import SwiftUI

/// Populated retro page ground (ART_DIRECTION.md §3.1, §7).
/// Decorative only: accessibility-hidden, never hit-testable, static.
/// Pass `exclusions` (in this view's coordinate space) for regions that must
/// stay motif-free (§7: none within 12pt of interactive areas — the layout
/// engine adds the clearance).
struct MotifGroundView: View {
    var seed: UInt64 = 0xCAFE_D00D
    var density: CGFloat = 1.0
    var exclusions: [CGRect] = []
    var palette: [Color] = [
        AppTheme.Retro.cream,
        AppTheme.Retro.bubblegum,
        AppTheme.Retro.tomato,
        AppTheme.Retro.grass,
    ]
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.Retro.ground.ignoresSafeArea()
            Canvas { context, size in
                // §3.3: dark mode drops density and uses accents only (no cream).
                let dark = colorScheme == .dark
                let effectiveDensity = dark ? density * 0.6 : density
                let colors = dark ? Array(palette.dropFirst()) : palette
                guard !colors.isEmpty else { return }
                let motifs = MotifFieldLayout.generate(seed: seed, size: size,
                                                       density: effectiveDensity,
                                                       avoiding: exclusions)
                for motif in motifs {
                    draw(motif, in: context, colors: colors)
                }
            }
            .ignoresSafeArea()
        }
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }

    private func draw(_ motif: Motif, in context: GraphicsContext, colors: [Color]) {
        var ctx = context
        ctx.translateBy(x: motif.position.x, y: motif.position.y)
        ctx.rotate(by: .degrees(motif.rotationDegrees))
        let s = motif.size
        let color = colors[motif.colorIndex % colors.count]
        let ink = AppTheme.Retro.ink
        let line = max(1.2, s * 0.12)

        switch motif.kind {
        case .dot:
            let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)
            ctx.fill(Path(ellipseIn: rect), with: .color(color))
            ctx.stroke(Path(ellipseIn: rect), with: .color(ink), lineWidth: line)

        case .daisy:
            // Six petal ellipses around an ink-outlined center.
            let petal = CGRect(x: -s * 0.16, y: -s * 0.62, width: s * 0.32, height: s * 0.5)
            for i in 0..<6 {
                var petalCtx = ctx
                petalCtx.rotate(by: .degrees(Double(i) * 60))
                petalCtx.fill(Path(ellipseIn: petal), with: .color(color))
                petalCtx.stroke(Path(ellipseIn: petal), with: .color(ink), lineWidth: line)
            }
            let center = CGRect(x: -s * 0.18, y: -s * 0.18, width: s * 0.36, height: s * 0.36)
            ctx.fill(Path(ellipseIn: center), with: .color(AppTheme.Retro.mustard))
            ctx.stroke(Path(ellipseIn: center), with: .color(ink), lineWidth: line)

        case .sparkle:
            // 4-point star: long spikes with a pinched waist.
            var path = Path()
            let long = s * 0.7, waist = s * 0.16
            path.move(to: CGPoint(x: 0, y: -long))
            path.addLine(to: CGPoint(x: waist, y: -waist))
            path.addLine(to: CGPoint(x: long, y: 0))
            path.addLine(to: CGPoint(x: waist, y: waist))
            path.addLine(to: CGPoint(x: 0, y: long))
            path.addLine(to: CGPoint(x: -waist, y: waist))
            path.addLine(to: CGPoint(x: -long, y: 0))
            path.addLine(to: CGPoint(x: -waist, y: -waist))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
            ctx.stroke(path, with: .color(ink), lineWidth: line)

        case .heart:
            var path = Path()
            let w = s, h = s
            path.move(to: CGPoint(x: 0, y: h * 0.45))
            path.addCurve(to: CGPoint(x: -w * 0.5, y: -h * 0.2),
                          control1: CGPoint(x: -w * 0.55, y: h * 0.15),
                          control2: CGPoint(x: -w * 0.55, y: -h * 0.25))
            path.addArc(center: CGPoint(x: -w * 0.25, y: -h * 0.2), radius: w * 0.25,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addArc(center: CGPoint(x: w * 0.25, y: -h * 0.2), radius: w * 0.25,
                        startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
            path.addCurve(to: CGPoint(x: 0, y: h * 0.45),
                          control1: CGPoint(x: w * 0.55, y: -h * 0.25),
                          control2: CGPoint(x: w * 0.55, y: h * 0.15))
            path.closeSubpath()
            ctx.fill(path, with: .color(color))
            ctx.stroke(path, with: .color(ink), lineWidth: line)

        case .squiggle:
            var path = Path()
            path.move(to: CGPoint(x: -s * 0.8, y: 0))
            path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: -s * 0.4, y: -s * 0.6))
            path.addQuadCurve(to: CGPoint(x: s * 0.8, y: 0), control: CGPoint(x: s * 0.4, y: s * 0.6))
            ctx.stroke(path, with: .color(color),
                       style: StrokeStyle(lineWidth: max(2, s * 0.18), lineCap: .round))
        }
    }
}

#Preview("Motif ground") {
    MotifGroundView(exclusions: [CGRect(x: 20, y: 300, width: 350, height: 200)])
}
