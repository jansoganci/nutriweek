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
                            RockyMascotView(mood: .encouraging, size: 72, message: "Let's create your account!")

                            NWCard(cornerRadius: 20, padding: 18, rnAuthShadow: true) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Create Account")
                                        .font(TypographyToken.inter(size: 24, weight: .bold))
                                        .foregroundStyle(ColorToken.textPrimary)

                                    Text("Start your NutriWeek journey with Rocky.")
                                        .font(TypographyToken.inter(size: 14, weight: .regular))
                                        .foregroundStyle(ColorToken.textSecondary)
                                        .padding(.bottom, 8)

                                    NWTextField(
                                        label: "Email",
                                        text: $viewModel.email,
                                        placeholder: "you@example.com",
                                        keyboardType: .emailAddress,
                                        textContentType: .emailAddress,
                                        errorMessage: nil,
                                        showsVisibilityToggle: false,
                                        rnAuthFieldMetrics: true
                                    )

                                    NWTextField(
                                        label: "Password",
                                        text: $viewModel.password,
                                        placeholder: "At least 6 characters",
                                        isSecure: true,
                                        textContentType: .newPassword,
                                        errorMessage: nil,
                                        showsVisibilityToggle: false,
                                        rnAuthFieldMetrics: true
                                    )

                                    NWTextField(
                                        label: "Confirm Password",
                                        text: $viewModel.confirmPassword,
                                        placeholder: "Repeat your password",
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
                                        title: "Create Account",
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
                                            Text("Already have an account? ")
                                                .font(TypographyToken.inter(size: 14, weight: .regular))
                                                .foregroundStyle(ColorToken.textSecondary)
                                            Text("Log in")
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
