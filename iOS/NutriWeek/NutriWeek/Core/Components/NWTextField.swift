import SwiftUI

struct NWTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    let errorMessage: String?
    /// RN auth: **`false`** (plain `SecureField`, no eye).
    var showsVisibilityToggle: Bool = true
    /// RN auth `label` / `input`: 13pt label, 12/11 padding, **1pt** border.
    var rnAuthFieldMetrics: Bool = false

    @State private var showSecret: Bool = false

    private var hasError: Bool {
        (errorMessage?.isEmpty == false)
    }

    private var borderWidth: CGFloat {
        rnAuthFieldMetrics ? BorderToken.hairline : BorderToken.default
    }

    private var labelFont: Font {
        rnAuthFieldMetrics
            ? TypographyToken.inter(size: 13, weight: .semibold)
            : TypographyToken.font(.bodySmall, weight: .semibold)
    }

    private var errorFont: Font {
        rnAuthFieldMetrics
            ? TypographyToken.inter(size: 13, weight: .regular)
            : TypographyToken.font(.caption)
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            if !showsVisibilityToggle || !showSecret {
                SecureField(
                    "",
                    text: $text,
                    prompt: Text(placeholder).foregroundStyle(ColorToken.textTertiary)
                )
                .textContentType(textContentType)
            } else {
                TextField(
                    "",
                    text: $text,
                    prompt: Text(placeholder).foregroundStyle(ColorToken.textTertiary)
                )
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(keyboardType == .emailAddress)
            }
        } else {
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(ColorToken.textTertiary)
            )
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(keyboardType == .emailAddress)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(labelFont)
                .foregroundStyle(ColorToken.textSecondary)
                .padding(.top, rnAuthFieldMetrics ? 4 : 0)

            field
                .font(TypographyToken.font(.body))
                .foregroundStyle(ColorToken.textPrimary)
                .padding(.horizontal, rnAuthFieldMetrics ? 12 : SpacingToken.sm)
                .padding(.vertical, rnAuthFieldMetrics ? 11 : SpacingToken.sm)
                .background(ColorToken.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: RadiusToken.field, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: RadiusToken.field, style: .continuous)
                        .stroke(
                            hasError ? ColorToken.destructive : ColorToken.border,
                            lineWidth: borderWidth
                        )
                )

            if showsVisibilityToggle, isSecure {
                HStack {
                    Spacer()
                    Button {
                        showSecret.toggle()
                    } label: {
                        Image(systemName: showSecret ? "eye.slash" : "eye")
                            .foregroundStyle(ColorToken.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, SpacingToken.xxs)
            }

            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(errorFont)
                    .foregroundStyle(ColorToken.destructive)
            }
        }
    }
}
