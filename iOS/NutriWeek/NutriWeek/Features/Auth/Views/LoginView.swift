import SwiftUI

struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    let onShowRegister: () -> Void

    @State private var showForgotPasswordAlert = false

    private var canSubmit: Bool {
        !viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.password.isEmpty
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
                            RockyMascotView(mood: .happy, size: 72, message: "Welcome back!")

                            NWCard(cornerRadius: 20, padding: 18, rnAuthShadow: true) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Log In")
                                        .font(TypographyToken.inter(size: 24, weight: .bold))
                                        .foregroundStyle(ColorToken.textPrimary)

                                    Text("Continue where you left off.")
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
                                        placeholder: "Your password",
                                        isSecure: true,
                                        textContentType: .password,
                                        errorMessage: nil,
                                        showsVisibilityToggle: false,
                                        rnAuthFieldMetrics: true
                                    )

                                    HStack {
                                        Spacer(minLength: 0)
                                        Button {
                                            showForgotPasswordAlert = true
                                        } label: {
                                            Text("Forgot Password?")
                                                .font(TypographyToken.inter(size: 13, weight: .semibold))
                                                .foregroundStyle(ColorToken.primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.top, 2)

                                    if let msg = viewModel.errorMessage, !msg.isEmpty {
                                        Text(msg)
                                            .font(TypographyToken.inter(size: 13, weight: .regular))
                                            .foregroundStyle(ColorToken.destructive)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.top, 2)
                                    }

                                    NWButton(
                                        title: "Login",
                                        variant: .primary,
                                        isLoading: viewModel.isLoading,
                                        isEnabled: canSubmit,
                                        isFullWidth: true,
                                        primaryDisabledUsesReducedOpacity: true,
                                        cornerRadius: 14
                                    ) {
                                        Task { await viewModel.signIn() }
                                    }
                                    .padding(.top, 10)

                                    Button(action: onShowRegister) {
                                        HStack(spacing: 0) {
                                            Text("New here? ")
                                                .font(TypographyToken.inter(size: 14, weight: .regular))
                                                .foregroundStyle(ColorToken.textSecondary)
                                            Text("Create account")
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
            .alert("Forgot Password", isPresented: $showForgotPasswordAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Password reset flow will be added soon.")
            }
        }
    }
}
