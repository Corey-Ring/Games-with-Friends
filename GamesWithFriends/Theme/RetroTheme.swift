import SwiftUI
import UIKit

// ART_DIRECTION.md §3 (color), §5 (shape). Phase-1 foundation; no shipped
// screen references these until its migration phase lands.
extension AppTheme {
    enum Retro {
        // MARK: - Candy palette (§3.1)
        static let mustard = Color(hex: "F2B417")
        static let cream = Color(hex: "FBF2E0")
        static let ink = Color(hex: "1B1B1B")
        static let cocoa = Color(hex: "55351D")
        static let bubblegum = Color(hex: "F387B8")
        static let tomato = Color(hex: "E8442E")
        static let tangerine = Color(hex: "F07C24")
        static let cornflower = Color(hex: "6C9BD2")
        static let poolBlue = Color(hex: "5BC0DF")
        static let grass = Color(hex: "57A34F")
        static let lilac = Color(hex: "A08BE0")
        static let berry = Color(hex: "C64B7E")
        static let plum = Color(hex: "8E4585")

        // MARK: - Dark mode "shop at night" (§3.3)
        static let darkGround = Color(hex: "2A1A10")
        static let darkPanel = Color(hex: "3A2A1C")

        // MARK: - Adaptive surfaces (same dynamic-provider pattern as AppTheme.cardSurface)
        /// Page ground: mustard by day, deep cocoa at night.
        static let ground = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(darkGround) : UIColor(mustard)
        })
        /// Panel/lozenge fill: cream by day, dark cocoa panel at night.
        static let panel = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(darkPanel) : UIColor(cream)
        })
        /// Text on `panel`: ink by day, cream at night.
        static let panelText = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(cream) : UIColor(ink)
        })

        // MARK: - Shape language (§5)
        static let strokeWidth: CGFloat = 2.5
        static let strokeHeavy: CGFloat = 3
        struct Radius {
            static let card: CGFloat = 18
            static let inner: CGFloat = 12
        }
        static let shadowOffset: CGFloat = 5
        static let shadowPressedOffset: CGFloat = 2
        static let pressTravel: CGFloat = 3
        /// Max rotation jitter for cards/lockups, in degrees (§5).
        static let maxCardTilt: Double = 1.5
    }
}
