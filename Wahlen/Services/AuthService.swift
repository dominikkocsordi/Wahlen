import Foundation
import Supabase
import Auth

enum AuthStage: Equatable {
    case email
    case otp(email: String)
}

@MainActor
@Observable
final class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?
    private(set) var isLoading: Bool = false
    private(set) var stage: AuthStage = .email
    var lastError: String?
    var infoMessage: String?

    private var client: SupabaseClient { SupabaseService.shared.client }
    private var listenerTask: Task<Void, Never>?

    private init() {}

    var isAuthenticated: Bool { currentUser != nil }

    func bootstrap() async {
        listenerTask?.cancel()
        listenerTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await (event, session) in self.client.auth.authStateChanges {
                switch event {
                case .signedIn, .initialSession, .tokenRefreshed, .userUpdated:
                    self.currentUser = session?.user
                case .signedOut:
                    self.currentUser = nil
                    self.stage = .email
                default:
                    break
                }
            }
        }

        do {
            let session = try await client.auth.session
            self.currentUser = session.user
        } catch {
            self.currentUser = nil
        }
    }

    func requestOTP(email: String) async -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        isLoading = true
        defer { isLoading = false }
        do {
            try await client.auth.signInWithOTP(
                email: trimmed,
                shouldCreateUser: false
            )
            self.lastError = nil
            self.infoMessage = "Wir haben einen 8-stelligen Code an \(trimmed) gesendet."
            self.stage = .otp(email: trimmed)
            return true
        } catch {
            self.lastError = friendly(error: error)
            return false
        }
    }

    func verifyOTP(email: String, token: String) async -> Bool {
        let cleanedToken = token
            .components(separatedBy: CharacterSet.whitespaces)
            .joined()
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()

        guard !cleanedToken.isEmpty else { return false }

        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await client.auth.verifyOTP(
                email: email,
                token: cleanedToken,
                type: .email
            )
            switch response {
            case .session(let session):
                self.currentUser = session.user
            case .user(let user):
                self.currentUser = user
            }
            self.lastError = nil
            self.infoMessage = nil
            return true
        } catch {
            self.lastError = friendly(error: error)
            return false
        }
    }

    func resetToEmailStage() {
        stage = .email
        lastError = nil
        infoMessage = nil
    }

    func signOut() async {
        do {
            try await client.auth.signOut()
            self.currentUser = nil
            self.stage = .email
        } catch {
            self.lastError = friendly(error: error)
        }
    }

    private func friendly(error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid") && message.contains("token") {
            return "Ungültiger oder abgelaufener Code. Bitte neu anfordern."
        }
        if message.contains("expired") {
            return "Code ist abgelaufen. Bitte neu anfordern."
        }
        if message.contains("rate") || message.contains("limit") {
            return "Zu viele Versuche. Bitte einen Moment warten."
        }
        if message.contains("user not found") || message.contains("not exist") {
            return "Diese E-Mail ist nicht registriert."
        }
        return error.localizedDescription
    }
}
