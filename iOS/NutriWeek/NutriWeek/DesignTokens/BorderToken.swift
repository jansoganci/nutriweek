import CoreGraphics

enum BorderToken {
    /// Default cards, dividers, hairline chrome.
    static let hairline: CGFloat = 1

    /// Inputs and selectable surfaces (RN used 1.5 often).
    static let `default`: CGFloat = 1.5

    /// Focus rings, radio outlines, strong emphasis.
    static let emphasis: CGFloat = 2
}
