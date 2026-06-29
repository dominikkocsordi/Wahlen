import Foundation

/// Wrappt asynchrone Netzwerk-Operationen und wiederholt sie automatisch
/// bei flüchtigen Fehlern (z. B. „Network connection was lost", `URLError -1005`).
/// Diese Fehler entstehen, wenn URLSession eine bereits geschlossene
/// Keep-Alive-Verbindung wiederverwendet und sind in den meisten Fällen
/// behebbar, indem die Anfrage einfach erneut gesendet wird.
enum NetworkRetry {

    /// Führt `operation` aus und versucht es bei flüchtigen Fehlern
    /// bis zu `maxAttempts`-mal mit exponentiellem Backoff erneut.
    static func run<T>(
        maxAttempts: Int = 3,
        _ operation: () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        for attempt in 0..<maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                guard isTransient(error), attempt < maxAttempts - 1 else {
                    throw error
                }
                // Backoff: 250 ms, 500 ms, 1 s, …
                let delay = pow(2.0, Double(attempt)) * 0.25
                try? await Task.sleep(for: .seconds(delay))
            }
        }
        throw lastError ?? URLError(.unknown)
    }

    /// Prüft, ob es sich um einen typischen flüchtigen Netzwerkfehler handelt.
    private static func isTransient(_ error: Error) -> Bool {
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        switch nsError.code {
        case NSURLErrorNetworkConnectionLost,    // -1005  "Network connection was lost"
             NSURLErrorTimedOut,                  // -1001  Timeout
             NSURLErrorCannotConnectToHost,       // -1004  temporär nicht erreichbar
             NSURLErrorCannotFindHost,            // -1003  DNS noch nicht da
             NSURLErrorNotConnectedToInternet,    // -1009  Offline
             NSURLErrorDNSLookupFailed,           // -1006
             NSURLErrorBadServerResponse,         // -1011
             NSURLErrorResourceUnavailable:       // -1008
            return true
        default:
            return false
        }
    }
}
