import Foundation

enum PresentationState: Equatable, Sendable {
    case idle
    case intro
    case slides
    case ballotPreview(sessionId: UUID)
    case open(sessionId: UUID)
    case decrypting(sessionId: UUID)
    case counting(sessionId: UUID)
    case verifying(sessionId: UUID)
    case results(sessionId: UUID)

    var sessionId: UUID? {
        switch self {
        case .idle, .intro, .slides: return nil
        case .ballotPreview(let id), .open(let id), .decrypting(let id),
             .counting(let id), .verifying(let id), .results(let id):
            return id
        }
    }

    var label: String {
        switch self {
        case .idle: return "Bereit"
        case .intro: return "Intro"
        case .slides: return "Folien"
        case .ballotPreview: return "Wahlzettel"
        case .open: return "Offen"
        case .decrypting: return "Entschlüsselung"
        case .counting: return "Auszählung"
        case .verifying: return "Prüfung"
        case .results: return "Ergebnis"
        }
    }
}

enum AdminElectionPhase: String, Sendable {
    case preparation = "Vorbereitung"
    case ballot = "Wahlzettel"
    case open = "Offen"
    case counting = "Auszählung"
    case verification = "Prüfung"
    case result = "Ergebnis"
}
