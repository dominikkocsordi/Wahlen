import SwiftUI

struct LoginView: View {
    @State private var auth = AuthService.shared
    @State private var email: String = ""
    @State private var code: String = ""
    @FocusState private var emailFocused: Bool
    @FocusState private var codeFocused: Bool

    var body: some View {
        ZStack {
            LinearGradient(colors: [Theme.background, Color(hex: 0x081F47)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            HStack(spacing: 0) {
                brandPanel
                formPanel
            }
        }
        .preferredColorScheme(.dark)
    }

    private var brandPanel: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            Text("FSBS")
                .font(AppFont.display(140, weight: .heavy))
                .tracking(6)
                .foregroundStyle(Theme.white)
                .shadow(color: Theme.lightBlue.opacity(0.25), radius: 24)
            Rectangle()
                .fill(LinearGradient(colors: [Theme.turquoise, Theme.lightBlue],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: 240, height: 3)
                .clipShape(Capsule())
            Text("Fachschaft Business School e.V.")
                .font(AppFont.title(28, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(Theme.white.opacity(0.9))
            Text("Wahlleitung & Beamer-Steuerung")
                .font(AppFont.body(15, weight: .medium))
                .tracking(2)
                .foregroundStyle(Theme.muted)
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(60)
        .background(Theme.background)
    }

    private var formPanel: some View {
        VStack(alignment: .leading, spacing: 22) {
            Spacer()
            switch auth.stage {
            case .email:
                emailForm
            case .otp(let sentEmail):
                otpForm(sentEmail: sentEmail)
            }
            Spacer()
        }
        .padding(60)
        .frame(maxWidth: 520, maxHeight: .infinity)
        .background(Theme.panel.opacity(0.55))
        .animation(.easeInOut(duration: 0.25), value: auth.stage)
    }

    private var emailForm: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Anmeldung")
                    .font(AppFont.display(34, weight: .bold))
                    .foregroundStyle(Theme.white)
                Text("Wir senden Ihnen einen 8-stelligen Einmal-Code per E-Mail.")
                    .font(AppFont.body(15))
                    .foregroundStyle(Theme.muted)
            }

            VStack(alignment: .leading, spacing: 16) {
                fieldLabel("E-Mail")
                TextField("name@fsbs.de", text: $email)
                    .textFieldStyle(.plain)
                    .focused($emailFocused)
                    .padding(14)
                    .background(Theme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Theme.white)
                    .font(AppFont.body(15, weight: .medium))
                    .onSubmit { requestCode() }
                    .onAppear { emailFocused = true }
            }

            errorBanner

            Button {
                requestCode()
            } label: {
                if auth.isLoading {
                    ProgressView().controlSize(.small)
                        .tint(Theme.background)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Code anfordern")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
            .disabled(email.isEmpty || auth.isLoading)
        }
    }

    private func otpForm(sentEmail: String) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Code eingeben")
                    .font(AppFont.display(34, weight: .bold))
                    .foregroundStyle(Theme.white)
                Text("Bitte den 8-stelligen Code aus der E-Mail an ")
                    .font(AppFont.body(15))
                    .foregroundStyle(Theme.muted)
                + Text(sentEmail)
                    .font(AppFont.body(15, weight: .semibold))
                    .foregroundStyle(Theme.white)
                + Text(" eingeben.")
                    .font(AppFont.body(15))
                    .foregroundStyle(Theme.muted)
            }

            VStack(alignment: .leading, spacing: 16) {
                fieldLabel("Einmal-Code")
                TextField("12345678", text: $code)
                    .textFieldStyle(.plain)
                    .focused($codeFocused)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .background(Theme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(Theme.white)
                    .font(AppFont.mono(28, weight: .semibold))
                    .tracking(8)
                    .onChange(of: code) { _, newValue in
                        let digits = newValue.filter(\.isNumber)
                        let trimmed = String(digits.prefix(8))
                        if trimmed != newValue { code = trimmed }
                    }
                    .onSubmit { verifyCode(email: sentEmail) }
                    .onAppear { codeFocused = true }
            }

            if let info = auth.infoMessage {
                Text(info)
                    .font(AppFont.body(13))
                    .foregroundStyle(Theme.turquoise)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Theme.turquoise.opacity(0.12)))
            }

            errorBanner

            VStack(spacing: 10) {
                Button {
                    verifyCode(email: sentEmail)
                } label: {
                    if auth.isLoading {
                        ProgressView().controlSize(.small)
                            .tint(Theme.background)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Anmelden")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.turquoise))
                .disabled(code.count != 8 || auth.isLoading)

                HStack {
                    Button("Andere E-Mail") {
                        code = ""
                        auth.resetToEmailStage()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.muted)
                    .font(AppFont.body(13, weight: .medium))

                    Spacer()

                    Button("Neuen Code anfordern") {
                        code = ""
                        Task { _ = await auth.requestOTP(email: sentEmail) }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.lightBlue)
                    .font(AppFont.body(13, weight: .semibold))
                    .disabled(auth.isLoading)
                }
                .padding(.top, 4)
            }
        }
    }

    @ViewBuilder
    private var errorBanner: some View {
        if let err = auth.lastError {
            Text(err)
                .font(AppFont.body(13))
                .foregroundStyle(Theme.red)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.red.opacity(0.12)))
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(AppFont.body(11, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(Theme.muted)
    }

    private func requestCode() {
        let clean = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        Task { _ = await auth.requestOTP(email: clean) }
    }

    private func verifyCode(email: String) {
        guard code.count == 8 else { return }
        Task { _ = await auth.verifyOTP(email: email, token: code) }
    }
}
