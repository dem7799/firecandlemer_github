import SwiftUI

enum AppColors {
    static let primary = Color.orange
    static let secondary = Color.pink
    static let background = Color(red: 0.06, green: 0.06, blue: 0.08)
    static let cardBackground = Color.white.opacity(0.08)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let overlayBG = Color.black.opacity(0.5)
}

enum AppSpacing {
    static let xs: CGFloat = 6
    static let s: CGFloat = 10
    static let m: CGFloat = 16
    static let l: CGFloat = 24
    static let xl: CGFloat = 32
}

enum AppRadii {
    static let s: CGFloat = 8
    static let m: CGFloat = 14
    static let l: CGFloat = 20
    static let xl: CGFloat = 28
}

enum AppTypography {
    static let title = Font.system(.title, design: .rounded).weight(.bold)
    static let subtitle = Font.system(.title3, design: .rounded).weight(.semibold)
    static let body = Font.system(.body, design: .rounded)
}
