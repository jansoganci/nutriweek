import SwiftUI

struct LoadingSkeletonView: View {
    enum Variant {
        case card
        case listRow
        case ring
    }

    var variant: Variant

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(ColorToken.muted.opacity(0.6))
            .frame(height: height)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.05),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .mask {
                        Rectangle()
                            .fill(.linearGradient(colors: [.clear, .white, .clear], startPoint: .leading, endPoint: .trailing))
                    }
            }
            .accessibilityHidden(true)
    }

    private var height: CGFloat {
        switch variant {
        case .card: return 140
        case .listRow: return 72
        case .ring: return 88
        }
    }

    private var cornerRadius: CGFloat {
        switch variant {
        case .card: return 18
        case .listRow: return 14
        case .ring: return 44
        }
    }
}
