import CoreGraphics

/// Corner radii (v1). Uses **two interactive field radii** so SwiftUI can match RN:
/// - `input`: small chips, step dots, tight controls
/// - `field`: rounded `TextField` shells (same 12pt as RN login/register inputs)
enum RadiusToken {
    /// Small chips, StepProgress dots, compact elevated controls.
    static let input: CGFloat = 8

    /// Primary text field corners (matches RN `login` / `register` `TextInput`).
    static let field: CGFloat = 12

    /// Cards, list rows, skeleton blocks (same numeric value as `field`; separate semantics).
    static let card: CGFloat = 12

    /// Large cards, bottom sheets, primary panels.
    static let sheet: CGFloat = 16

    /// Pills, toasts, full-round controls.
    static let pill: CGFloat = 999
}
