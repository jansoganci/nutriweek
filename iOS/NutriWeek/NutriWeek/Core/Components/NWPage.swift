import SwiftUI

/// Root screen shell: app background + horizontal **gutter** (20pt) inside safe area.
struct NWPage<Content: View>: View {
    private let background: Color
    private let content: Content

    init(
        background: Color = ColorToken.background,
        @ViewBuilder content: () -> Content
    ) {
        self.background = background
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .top) {
            background
                .ignoresSafeArea()
            content
                .padding(.horizontal, SpacingToken.gutter)
        }
    }
}
