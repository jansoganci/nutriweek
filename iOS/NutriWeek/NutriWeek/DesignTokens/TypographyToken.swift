import SwiftUI

// MARK: - Inter face names (bundled TTF filenames = PostScript names in Inter static build)

private enum InterFont {
    static let regular = "Inter-Regular"
    static let medium = "Inter-Medium"
    static let semibold = "Inter-SemiBold"
    static let bold = "Inter-Bold"
}

/// v1 typography: sizes **12, 14, 16, 18, 20, 24, 28, 52** with named roles.
enum TypographyToken {

    enum Size: CGFloat {
        case caption = 12
        case bodySmall = 14
        case body = 16
        case bodyLarge = 18
        case title3 = 20
        case title2 = 24
        case title1 = 28
        case display = 52
    }

    enum Role {
        case caption
        case bodySmall
        case body
        case bodyLarge
        case title3
        case title2
        case title1
        case display
    }

    /// Maps `Font.Weight` to bundled Inter static files.
    private static func interFontName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light:
            return InterFont.regular
        case .regular:
            return InterFont.regular
        case .medium:
            return InterFont.medium
        case .semibold:
            return InterFont.semibold
        case .bold, .heavy, .black:
            return InterFont.bold
        default:
            return InterFont.regular
        }
    }

    /// Default weight per role (matches common RN usage: labels semibold, titles bold, body regular).
    private static func defaultWeight(for role: Role) -> Font.Weight {
        switch role {
        case .caption, .bodySmall, .body, .bodyLarge:
            return .regular
        case .title3:
            return .semibold
        case .title2, .title1, .display:
            return .bold
        }
    }

    private static func size(for role: Role) -> CGFloat {
        switch role {
        case .caption: return Size.caption.rawValue
        case .bodySmall: return Size.bodySmall.rawValue
        case .body: return Size.body.rawValue
        case .bodyLarge: return Size.bodyLarge.rawValue
        case .title3: return Size.title3.rawValue
        case .title2: return Size.title2.rawValue
        case .title1: return Size.title1.rawValue
        case .display: return Size.display.rawValue
        }
    }

    /// Primary API: role-sized **Inter** text. Pass `weight` to override the role default.
    static func font(_ role: Role, weight: Font.Weight? = nil) -> Font {
        let w = weight ?? defaultWeight(for: role)
        return Font.custom(interFontName(for: w), size: size(for: role))
    }

    /// Raw Inter font for custom layouts (e.g. single-line numeric hero).
    static func inter(size: CGFloat, weight: Font.Weight) -> Font {
        Font.custom(interFontName(for: weight), size: size)
    }

    // MARK: - Line heights (from RN — use with `lineSpacing` or fixed heights where needed)

    enum LineHeight {
        static let caption: CGFloat = 18
        static let tight: CGFloat = 20
        static let relaxed: CGFloat = 24
        static let title: CGFloat = 40
        static let display: CGFloat = 56
    }
}
