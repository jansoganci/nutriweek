import CoreGraphics
import CoreText
import Foundation

/// Registers bundled Inter static fonts at process scope (`CTFontManagerRegisterFontsForURL`).
/// Fonts are included under `Resources/Fonts/*.ttf` and sync into the app via the Xcode folder group.
enum FontRegistration {
    private static let interFontFiles = [
        "Inter-Regular",
        "Inter-Medium",
        "Inter-SemiBold",
        "Inter-Bold",
    ]

    /// Call once on app launch (e.g. from `NutriWeekApp.init()`).
    static func registerInterFonts() {
        for base in interFontFiles {
            guard let url = Bundle.main.url(forResource: base, withExtension: "ttf") else {
                #if DEBUG
                assertionFailure("NutriWeek: missing font \(base).ttf in bundle — check Resources/Fonts.")
                #endif
                continue
            }
            var error: Unmanaged<CFError>?
            let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            #if DEBUG
            if !ok, let err = error?.takeRetainedValue() {
                assertionFailure("NutriWeek: font register failed \(base): \(err)")
            }
            #endif
        }
    }
}
