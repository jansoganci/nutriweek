import CoreGraphics

/// Locked spacing scale: only these values should be used for layout rhythm.
enum SpacingToken {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48

    /// **Exception:** RN auth/onboarding screens use **20pt** horizontal screen gutters;
    /// keep this single named token instead of forcing 16/24.
    static let gutter: CGFloat = 20
}
