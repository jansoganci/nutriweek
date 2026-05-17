import SwiftUI

struct RegisterView: View {
    @Bindable var viewModel: AuthViewModel
    let onShowLogin: () -> Void

    private var canSubmit: Bool {
        !viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && viewModel.password.count >= 6
            && viewModel.confirmPassword.count >= 6
            && !viewModel.isLoading
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                let padTop = geo.safeAreaInsets.top + 20
                let padBottom = geo.safeAreaInsets.bottom + 24
                let centeringHeight = max(0, geo.size.height - padTop - padBottom)

                ScrollView {
                    VStack {
                        Spacer(minLength: 0)
                        VStack(spacing: 18) {
                            RockyMascotView(mood: .encouraging, size: 72, message: String(localized: "auth.register.rocky_message"))

                            NWCard(cornerRadius: 20, padding: 18, rnAuthShadow: true) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(LocalizedStringKey("auth.register.title"))
                                        .font(TypographyToken.inter(size: 24, weight: .bold))
                                        .foregroundStyle(ColorToken.textPrimary)

                                    Text(LocalizedStringKey("auth.register.subtitle"))
                                        .font(TypographyToken.inter(size: 14, weight: .regular))
                                        .foregroundStyle(ColorToken.textSecondary)
                                        .padding(.bottom, 8)

                                    NWTextField(
                                        label: String(localized: "auth.register.email_label"),
                                        text: $viewModel.email,
                                        placeholder: String(localized: "auth.register.email_placeholder"),
                                        keyboardType: .emailAddress,
                                        textContentType: .emailAddress,
                                        errorMessage: nil,
                                        showsVisibilityToggle: false,
                                        rnAuthFieldMetrics: true
                                    )

                                    NWTextField(
                                        label: String(localized: "auth.register.password_label"),
                                        text: $viewModel.password,
                                        placeholder: String(localized: "auth.register.password_placeholder"),
                                        isSecure: true,
                                        textContentType: .newPassword,
                                        errorMessage: nil,
                                        showsVisibilityToggle: false,
                                        rnAuthFieldMetrics: true
                                    )

                                    NWTextField(
                                        label: String(localized: "auth.register.confirm_password_label"),
                                        text: $viewModel.confirmPassword,
                                        placeholder: String(localized: "auth.register.confirm_password_placeholder"),
                                        isSecure: true,
                                        textContentType: .password,
                                        errorMessage: nil,
                                        showsVisibilityToggle: false,
                                        rnAuthFieldMetrics: true
                                    )

                                    if let msg = viewModel.errorMessage, !msg.isEmpty {
                                        Text(msg)
                                            .font(TypographyToken.inter(size: 13, weight: .regular))
                                            .foregroundStyle(ColorToken.destructive)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.top, 2)
                                    }

                                    NWButton(
                                        title: String(localized: "auth.register.title"),
                                        variant: .primary,
                                        isLoading: viewModel.isLoading,
                                        isEnabled: canSubmit,
                                        isFullWidth: true,
                                        primaryDisabledUsesReducedOpacity: true,
                                        cornerRadius: 14
                                    ) {
                                        Task { await viewModel.signUp() }
                                    }
                                    .padding(.top, 10)

                                    Button {
                                        viewModel.goToLogin()
                                        onShowLogin()
                                    } label: {
                                        HStack(spacing: 0) {
                                            Text(LocalizedStringKey("auth.register.has_account"))
                                                .font(TypographyToken.inter(size: 14, weight: .regular))
                                                .foregroundStyle(ColorToken.textSecondary)
                                            Text(LocalizedStringKey("auth.register.login"))
                                                .font(TypographyToken.inter(size: 14, weight: .bold))
                                                .foregroundStyle(ColorToken.primary)
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.top, 4)
                                }
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: centeringHeight)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, SpacingToken.gutter)
                    .padding(.top, padTop)
                    .padding(.bottom, padBottom)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(ColorToken.background)
            }
            .ignoresSafeArea(edges: .all)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}
