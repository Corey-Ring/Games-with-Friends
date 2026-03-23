import SwiftUI

struct AppTheme {
    // MARK: - Brand Colors
    static let brandOrange = Color(hex: "FF6B35")
    static let deepCharcoal = Color(hex: "1C1C1E")
    static let warmLinen = Color(hex: "F5F3F0")
    static let pureWhite = Color.white
    static let mediumGray = Color(hex: "636366")

    // MARK: - Game Accent Colors
    static let coralRed = Color(hex: "E8533F")
    static let warmGold = Color(hex: "D4943A")
    static let softMauve = Color(hex: "C48EB0")
    static let tealGreen = Color(hex: "4FBFA5")
    static let skyBlue = Color(hex: "5B9BD5")
    static let forestGreen = Color(hex: "6DAE6D")
    static let electricIndigo = Color(hex: "7B6CF6")

    // MARK: - Semantic Colors
    static let success = Color(hex: "34C759")
    static let error = Color(hex: "FF3B30")
    static let warning = Color(hex: "FF9500")
    static let medalGold = Color(hex: "FFD700")
    static let medalSilver = Color(hex: "C0C0C0")
    static let medalBronze = Color(hex: "CD7F32")
    static let overlay = Color.black.opacity(0.4)

    // MARK: - Dark Mode Surfaces
    static let darkBackground = Color(hex: "1C1C1E")
    static let darkCard = Color(hex: "2C2C2E")
    static let darkElevated = Color(hex: "3A3A3C")
    static let darkMutedText = Color(hex: "AEAEB2")

    // MARK: - Typography (Dynamic Type enabled)
    struct Typography {
        static let hero: Font = .largeTitle.bold()
        static let screenTitle: Font = .title.bold()
        static let sectionHeader: Font = .title2.bold()
        static let subsectionHeader: Font = .title3
        static let cardTitle: Font = .headline
        static let body: Font = .body
        static let detail: Font = .callout
        static let secondary: Font = .subheadline
        static let caption: Font = .caption
        static let footnote: Font = .footnote
        static let buttonLabel: Font = .headline
        static let tabLabel: Font = .caption2
        static let pillLabel: Font = .caption.weight(.semibold)
    }

    // MARK: - Spacing (8pt grid)
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct Radius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let card: CGFloat = 16
        static let large: CGFloat = 20
    }

    // MARK: - Shadows
    struct Shadow {
        static let cardColor = Color.black.opacity(0.08)
        static let cardRadius: CGFloat = 8
        static let cardX: CGFloat = 0
        static let cardY: CGFloat = 2

        static let elevatedColor = Color.black.opacity(0.08)
        static let elevatedRadius: CGFloat = 8
        static let elevatedX: CGFloat = 0
        static let elevatedY: CGFloat = 4

        static let topEdgeColor = Color.black.opacity(0.06)
        static let topEdgeRadius: CGFloat = 4
        static let topEdgeY: CGFloat = -2
    }

    // MARK: - Animation Timing
    struct Animation {
        static let buttonPress: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.6)
        static let cardTap: SwiftUI.Animation = .spring(response: 0.3, dampingFraction: 0.7)
        static let scoreCounter: SwiftUI.Animation = .easeOut(duration: 0.3)
        static let cardEnterDuration: Double = 0.3
        static let cardEnterDelay: Double = 0.05 // per item stagger
    }
}
