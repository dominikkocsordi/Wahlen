import SwiftUI
import AVFoundation

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - Timing

/// Kapselt die Montage-Phasen. Die Counting-Dauer richtet sich nach der
/// Länge von montage.m4a, sodass `verifying` genau mit dem Track-Ende abschließt.
enum MontageTiming {
    static let votingClosedDuration: TimeInterval = 5.5   // Genug Zeit für den Drop-Burst
    static let decryptingDuration:   TimeInterval = 3.0
    static let verifyingDuration:    TimeInterval = 4.0
    static let minCountingDuration:  TimeInterval = 6.0
    static let fallbackMusicDuration: TimeInterval = 20.0

    /// Wird einmal aus dem Bundle gelesen und gecached.
    static let musicDuration: TimeInterval = {
        guard let url = Bundle.main.url(forResource: "montage", withExtension: "m4a"),
              let player = try? AVAudioPlayer(contentsOf: url) else {
            return fallbackMusicDuration
        }
        let dur = player.duration
        return dur > 0 ? dur : fallbackMusicDuration
    }()

    static var countingDuration: TimeInterval {
        max(minCountingDuration, musicDuration - decryptingDuration - verifyingDuration)
    }
}

// MARK: - Datenmodell

struct MontageImage: Identifiable, Equatable {
    let id = UUID()
    let path: String
    var position: CGPoint
    var rotation: Angle
    var scale: CGFloat
}

private struct MontageItemView: View {
    let img: MontageImage

    var body: some View {
        Group {
            #if canImport(AppKit)
            if let nsImage = NSImage(contentsOfFile: img.path) {
                Image(nsImage: nsImage).resizable()
            }
            #elseif canImport(UIKit)
            if let uiImage = UIImage(contentsOfFile: img.path) {
                Image(uiImage: uiImage).resizable()
            }
            #endif
        }
        .scaledToFill()
        .frame(width: 260, height: 195)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: .black.opacity(0.45), radius: 14, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.22), lineWidth: 1)
        )
        .position(img.position)
        .rotationEffect(img.rotation)
        .scaleEffect(img.scale)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.4).combined(with: .opacity),
            removal: .opacity.combined(with: .scale(scale: 0.8))
        ))
    }
}

// MARK: - Haupt-View

struct VotingProcessingView: View {
    let state: PresentationState

    // Reaktive Store-Anbindung – Zähler folgt der echten Stimmenanzahl.
    @State private var store = ElectionStore.shared

    // Bild-Montage
    @State private var availableImagePaths: [String] = []
    @State private var imageCursor: Int = 0
    @State private var slotOrder: [Int] = []
    @State private var slotCursor: Int = 0
    @State private var visibleImages: [MontageImage] = []
    @State private var imageTask: Task<Void, Never>?

    // Audio
    @State private var audioPlayer: AVAudioPlayer?

    // Animationen
    @State private var spinnerRotation: Double = 0
    @State private var pulse: CGFloat = 1.0
    @State private var animationsStarted: Bool = false

    // Counting-Progress (0...1) – wird über Counting-Dauer linear animiert.
    @State private var progress: Double = 0

    // Aktuelle Stimmenanzahl, live aus dem Store.
    private var actualVotes: Int {
        guard let id = state.sessionId else { return 0 }
        return store.votes(for: id).count
    }
    private var displayedCount: Int {
        max(0, min(actualVotes, Int((progress * Double(actualVotes)).rounded())))
    }

    // MARK: - State Helpers

    private var isProcessing: Bool {
        switch state {
        case .decrypting, .counting, .verifying: return true
        default: return false
        }
    }

    private var isCounting: Bool {
        if case .counting = state { return true }
        return false
    }

    private var imageInterval: TimeInterval {
        switch state {
        case .decrypting: return 1.6
        case .counting:   return 1.0
        case .verifying:  return 1.4
        default:          return 1.6
        }
    }

    private var currentTitle: String {
        switch state {
        case .decrypting: return "Entschlüsselung"
        case .counting:   return "Auszählung"
        case .verifying:  return "Prüfung"
        default:          return ""
        }
    }

    private var currentSubtitle: String {
        switch state {
        case .decrypting: return "STIMMEN WERDEN ENTSCHLÜSSELT"
        case .counting:   return "STIMMEN WERDEN GEZÄHLT"
        case .verifying:  return "ERGEBNISSE WERDEN VALIDIERT"
        default:          return ""
        }
    }

    private var currentIcon: String {
        switch state {
        case .decrypting: return "lock.shield.fill"
        case .counting:   return "checklist"
        case .verifying:  return "checkmark.shield.fill"
        default:          return "hourglass"
        }
    }

    private var currentTint: Color {
        switch state {
        case .decrypting: return Color(hex: 0x9B7BFF)
        case .counting:   return Color(hex: 0xFFA94D)
        case .verifying:  return Color(hex: 0xFFD75A)
        default:          return .white
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if isProcessing {
                    ForEach(visibleImages) { img in
                        MontageItemView(img: img)
                    }

                    centerPill
                        .frame(maxWidth: 780)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
            }
            .onAppear {
                loadImagesIfNeeded()
                startBaseAnimationsIfNeeded()
                syncForCurrentState(size: geo.size)
            }
            .onChange(of: state) { _, _ in
                syncForCurrentState(size: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                // Slot-Layout an Bildschirmgröße neu binden
                rebuildSlots(for: newSize)
            }
            .onDisappear {
                teardown()
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Liquid Glass Pill

    private var centerPill: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header: Icon + Titel + Spinner
            HStack(spacing: 22) {
                Image(systemName: currentIcon)
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(currentTint)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 64, height: 64)
                    .glassEffect(.regular.tint(currentTint.opacity(0.35)), in: .circle)
                    .scaleEffect(pulse)
                    .shadow(color: currentTint.opacity(0.35), radius: 22)

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentSubtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(3.0)
                        .foregroundStyle(currentTint)
                    Text(currentTitle)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer(minLength: 0)

                Circle()
                    .trim(from: 0, to: 0.78)
                    .stroke(
                        AngularGradient(colors: [currentTint.opacity(0.0), currentTint, .white],
                                        center: .center),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 42, height: 42)
                    .rotationEffect(.degrees(spinnerRotation))
            }

            if isCounting {
                countingSection
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(.horizontal, 36)
        .padding(.vertical, isCounting ? 28 : 24)
        // Liquid-Glass-Hauptfläche
        .glassEffect(.regular.tint(currentTint.opacity(0.12)),
                     in: .rect(cornerRadius: 36, style: .continuous))
        .shadow(color: .black.opacity(0.55), radius: 40, y: 22)
        .shadow(color: currentTint.opacity(0.18), radius: 32)
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: isCounting)
    }

    private var countingSection: some View {
        let total = max(actualVotes, 1)
        let safeProgress = min(max(progress, 0), 1)

        return VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(displayedCount)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(value: Double(displayedCount)))
                    .animation(.snappy(duration: 0.25), value: displayedCount)

                Text("/ \(total)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))

                Spacer(minLength: 0)

                Text("\(Int((safeProgress * 100).rounded())) %")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(currentTint)
            }

            GeometryReader { barGeo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))

                    Capsule()
                        .fill(
                            LinearGradient(colors: [currentTint, currentTint.opacity(0.6)],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .frame(width: max(0, barGeo.size.width * CGFloat(safeProgress)))
                        .shadow(color: currentTint.opacity(0.55), radius: 10)
                }
            }
            .frame(height: 16)
            .glassEffect(.clear, in: .capsule)
        }
    }

    // MARK: - Lifecycle

    private func syncForCurrentState(size: CGSize) {
        rebuildSlotsIfNeeded(for: size)
        if isProcessing {
            startAudioIfNeeded()
            scheduleImageRotation(size: size)
            if isCounting {
                restartCountingAnimation()
            }
        } else {
            teardown()
        }
    }

    private func teardown() {
        stopMontageAudio()
        imageTask?.cancel()
        imageTask = nil
        withAnimation(.easeOut(duration: 0.25)) {
            visibleImages = []
        }
        progress = 0
    }

    // MARK: - Audio

    private func startAudioIfNeeded() {
        if audioPlayer?.isPlaying == true { return }
        MusicService.shared.stopAll()
        guard let url = Bundle.main.url(forResource: "montage", withExtension: "m4a") else { return }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.numberOfLoops = 0
        player.volume = 0.65
        player.prepareToPlay()
        player.play()
        audioPlayer = player
    }

    private func stopMontageAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    // MARK: - Animationen

    private func startBaseAnimationsIfNeeded() {
        guard !animationsStarted else { return }
        animationsStarted = true
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
            spinnerRotation = 360
        }
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulse = 1.08
        }
    }

    private func restartCountingAnimation() {
        progress = 0
        let duration = MontageTiming.countingDuration
        withAnimation(.linear(duration: duration)) {
            progress = 1.0
        }
    }

    // MARK: - Bilder laden

    private func loadImagesIfNeeded() {
        guard availableImagePaths.isEmpty else { return }
        var foundURLs: [URL] = []
        if let subDirURLs = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: "Bilder") {
            foundURLs.append(contentsOf: subDirURLs)
        }
        if foundURLs.isEmpty,
           let rootURLs = Bundle.main.urls(forResourcesWithExtension: nil, subdirectory: nil) {
            foundURLs.append(contentsOf: rootURLs)
        }
        availableImagePaths = foundURLs.map(\.path)
            .filter { path in
                let lower = path.lowercased()
                let isImage = lower.hasSuffix(".jpg")
                    || lower.hasSuffix(".jpeg")
                    || lower.hasSuffix(".png")
                    || lower.hasSuffix(".heic")
                return isImage
                    && !lower.contains("appicon")
                    && !lower.contains("assets.car")
            }
            .shuffled()
        imageCursor = 0
    }

    private func scheduleImageRotation(size: CGSize) {
        imageTask?.cancel()
        imageTask = Task { @MainActor in
            while !Task.isCancelled {
                showNextImage(in: size)
                try? await Task.sleep(for: .seconds(imageInterval))
            }
        }
    }

    private func showNextImage(in size: CGSize) {
        guard !availableImagePaths.isEmpty else { return }
        rebuildSlotsIfNeeded(for: size)

        let path = availableImagePaths[imageCursor % availableImagePaths.count]
        imageCursor += 1

        let position = nextSlotPosition(in: size)
        let newImg = MontageImage(
            path: path,
            position: position,
            rotation: .degrees(Double.random(in: -10...10)),
            scale: CGFloat.random(in: 0.92...1.12)
        )

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            visibleImages.append(newImg)
            if visibleImages.count > 6 {
                visibleImages.removeFirst()
            }
        }
    }

    // MARK: - Slot-Verteilung (8 feste Positionen um die zentrale Pill herum)

    /// Liefert relative Anker-Positionen (0...1) für 8 ausgewogene Slots.
    private static let slotAnchors: [CGPoint] = [
        CGPoint(x: 0.15, y: 0.22),
        CGPoint(x: 0.50, y: 0.14),
        CGPoint(x: 0.85, y: 0.22),
        CGPoint(x: 0.08, y: 0.55),
        CGPoint(x: 0.92, y: 0.55),
        CGPoint(x: 0.15, y: 0.84),
        CGPoint(x: 0.50, y: 0.90),
        CGPoint(x: 0.85, y: 0.84)
    ]

    private func rebuildSlotsIfNeeded(for size: CGSize) {
        if slotOrder.isEmpty {
            rebuildSlots(for: size)
        }
    }

    private func rebuildSlots(for size: CGSize) {
        slotOrder = Array(Self.slotAnchors.indices).shuffled()
        slotCursor = 0
    }

    private func nextSlotPosition(in size: CGSize) -> CGPoint {
        if slotOrder.isEmpty { rebuildSlots(for: size) }
        let idx = slotOrder[slotCursor % slotOrder.count]
        slotCursor += 1
        if slotCursor >= slotOrder.count {
            // Neue Reihenfolge, sobald alle Slots durchlaufen wurden.
            slotOrder.shuffle()
            slotCursor = 0
        }
        let anchor = Self.slotAnchors[idx]
        // Leichte Jitter-Verschiebung, damit die Bilder nicht starr wirken.
        let jitterX = CGFloat.random(in: -28...28)
        let jitterY = CGFloat.random(in: -22...22)
        let x = max(160, min(size.width  - 160, anchor.x * size.width  + jitterX))
        let y = max(140, min(size.height - 140, anchor.y * size.height + jitterY))
        return CGPoint(x: x, y: y)
    }
}
