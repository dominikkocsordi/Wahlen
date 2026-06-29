import Foundation
import AVFoundation
import Observation

@MainActor
@Observable
final class MusicService {
    static let shared = MusicService()

    enum Track: String, CaseIterable, Sendable {
        case buildup = "reveal_buildup"
        case winner = "reveal_winner"

        var fileNames: [String] {
            switch self {
            case .buildup: return ["reveal_buildup", "buildup", "anspann"]
            case .winner: return ["reveal_winner", "winner", "sieger"]
            }
        }

        var extensions: [String] { ["mp3", "m4a", "wav", "caf", "aiff"] }
    }

    private var buildupPlayer: AVAudioPlayer?
    private var winnerPlayer: AVAudioPlayer?
    private var fadeTask: Task<Void, Never>?

    var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.enabledKey)
            if !isEnabled { stopAll() }
        }
    }

    private static let enabledKey = "fsbs.wahlen.music.enabled"

    private init() {
        let stored = UserDefaults.standard.object(forKey: Self.enabledKey) as? Bool
        self.isEnabled = stored ?? true
    }

    func hasFile(for track: Track) -> Bool {
        resolveURL(for: track) != nil
    }

    func playBuildup() {
        guard isEnabled, let url = resolveURL(for: .buildup) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = 0.9
            player.prepareToPlay()
            player.play()
            buildupPlayer = player
        } catch {
            buildupPlayer = nil
        }
    }

    func playWinner() {
        fadeOut(player: buildupPlayer)
        buildupPlayer = nil
        guard isEnabled, let url = resolveURL(for: .winner) else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = 0
            player.volume = 1.0
            player.prepareToPlay()
            player.play()
            winnerPlayer = player
        } catch {
            winnerPlayer = nil
        }
    }

    func stopAll() {
        fadeTask?.cancel()
        fadeTask = nil
        buildupPlayer?.stop()
        winnerPlayer?.stop()
        buildupPlayer = nil
        winnerPlayer = nil
    }

    func toggle() {
        isEnabled.toggle()
    }

    private func fadeOut(player: AVAudioPlayer?) {
        guard let player else { return }
        fadeTask?.cancel()
        fadeTask = Task { @MainActor in
            let steps = 20
            let start = player.volume
            for step in 0..<steps {
                if Task.isCancelled { break }
                let progress = Double(step + 1) / Double(steps)
                player.volume = max(start * Float(1 - progress), 0)
                try? await Task.sleep(for: .milliseconds(40))
            }
            player.stop()
        }
    }

    private func resolveURL(for track: Track) -> URL? {
        for name in track.fileNames {
            for ext in track.extensions {
                if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                    return url
                }
            }
        }
        return nil
    }
}
