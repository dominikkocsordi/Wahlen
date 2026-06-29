import SwiftUI
import Foundation
import Combine

// MARK: - Datenmodell & Namen
struct BoardMemberPeriod: Identifiable {
    let id = UUID()
    let years: String
    let names: [String]
}

let allBoardMembers: [BoardMemberPeriod] = [
    BoardMemberPeriod(years: "2001–2005", names: ["Gerd Gruber", "Olivia Stocks", "Manuela Gindrig"]),
    BoardMemberPeriod(years: "2005", names: ["Ronny Hinz", "Heike Sachtleben", "Wolfgang Süß"]),
    BoardMemberPeriod(years: "2005–2012", names: ["Thomas Hilz", "Harald Eder", "Wolfgang Süß"]),
    BoardMemberPeriod(years: "2012–2013", names: ["Nora Stockmann", "Hannes Schweizer", "Daniela Reibenspiess"]),
    BoardMemberPeriod(years: "2013", names: ["Christoph Huber", "Daniela Heimerl", "Aaron Geyer"]),
    BoardMemberPeriod(years: "2013–2014", names: ["Marie-Luise Dumler", "Julian Schott", "Tanja Hußnätter"]),
    BoardMemberPeriod(years: "2014", names: ["Micha Dicenta", "Julian Schott", "Tanja Hußnätter"]),
    BoardMemberPeriod(years: "2014–2016", names: ["Swana Kopton", "Melanie Müller", "Tanja Hußnätter"]),
    BoardMemberPeriod(years: "2016", names: ["Ronja Shabazi Manesh", "Alexander Blatterspiel", "Berna Torun"]),
    BoardMemberPeriod(years: "2016–2017", names: ["Svenja Perret", "Jessica Wagner", "Amar Lojo"]),
    BoardMemberPeriod(years: "2017", names: ["Simone Alice Zapf", "Florian Köcheler", "Amar Lojo"]),
    BoardMemberPeriod(years: "2017–2019", names: ["Patricia Roth", "Martha Riviere", "Carina Weinmann"]),
    BoardMemberPeriod(years: "2019–2021", names: ["Julian Treutler", "Hannah Thim", "Peer Pospischil"]),
    BoardMemberPeriod(years: "2021–2022", names: ["Fabian Rieth", "Kara Anders", "Damian Riedmann"]),
    BoardMemberPeriod(years: "2022–2023", names: ["Tim Gerwens", "Carina Junkers", "Linus Bothe"]),
    BoardMemberPeriod(years: "2023", names: ["Lukas Dolenc", "Barbara Beer", "Michael Scheichl"]),
    BoardMemberPeriod(years: "2023–2024", names: ["Nicolas Anzinger", "Maresa Nagler", "Leon Klugherz"]),
    BoardMemberPeriod(years: "2024–2026", names: ["Franziska Mannheim", "Dominik Kocsordi", "Giuseppe Bonello"]),
    BoardMemberPeriod(years: "2026–heute", names: ["Dominik Kocsordi", "Benjamin Mustafic", "Lena Sophia Richter"])
]

let memberFirstNames: [String] = [
    "Dominik", "Franziska", "Lorenz", "Alexander", "Alyssa", "Amelie",
    "Annika", "Barbara", "Benjamin", "Charleen", "Christopher", "Cornelius",
    "Danny", "Eileen", "Elena", "Emine", "Fabio", "Florian", "Fred",
    "Jasmin", "Judith", "Jule", "Julia", "Julian", "Katharina", "Kathrin",
    "Katrin", "Kavishan", "Kilian", "Lara", "Laura", "Layla", "Lea", "Lena",
    "Leonie", "Letizia", "Lisa", "Luca", "Lukas", "Maik", "Maresa", "Marlene",
    "Maxhendry", "Michael", "Ahmed", "Naomi", "Nathanael", "Nicolas", "Sandra",
    "Saskia", "Saya", "Sebastian", "Selina", "Sophie", "Tim", "Tom", "Veronica",
    "Yaroslav", "Giuseppe", "Antonio", "Chiara", "Anna", "Manuel", "Josef",
    "Leonard", "Noah", "Sarah", "Antonia", "Moritz", "Gero", "Ben", "Anastasia",
    "Daria", "Jan-Adrian", "Kevin", "Michelle", "Erik", "Robin", "Zoe"
]

// MARK: - Design System
private let goldPrimary = Color(red: 1.0, green: 0.84, blue: 0.4)
private let goldAccent  = Color(red: 0.85, green: 0.65, blue: 0.13)
private let goldSubtle  = Color(red: 1.0, green: 0.92, blue: 0.7).opacity(0.3)
private let darkBG      = Color(red: 0.05, green: 0.05, blue: 0.07)

// MARK: - Phasen (intro.m4a, 42 s)
enum IntroPhase: Equatable {
    case splash       // 0–2 s   "25 / Fachschaft Business School"
    case fastForward  // 2–10 s  Schnelldurchlauf aller Vorstände
    case boardsGrid   // 10–30 s Goldblitz + alle Vorstände sichtbar
    case members      // 30–36 s "Danke an euch …" + 79 Vornamen
    case heart        // 36–38 s Liquid Glass Herz
    case logoReveal   // 38–42 s Logo + 25 Jahre
}

// MARK: - Haupt-View
struct IntroView: View {
    private let totalDuration: Double = 42.0

    // Phasen-Marker
    private let splashEnd: Double = 2.0
    private let fastForwardEnd: Double = 10.0
    private let boardsGridEnd: Double = 30.0
    private let membersEnd: Double = 36.0
    private let heartEnd: Double = 38.0

    @State private var time: Double = 0
    @State private var hasStarted: Bool = false

    private let frameTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()

    private var phase: IntroPhase {
        if time < splashEnd { return .splash }
        if time < fastForwardEnd { return .fastForward }
        if time < boardsGridEnd { return .boardsGrid }
        if time < membersEnd { return .members }
        if time < heartEnd { return .heart }
        return .logoReveal
    }

    /// Im Schnelldurchlauf: welche Karte ist gerade fokussiert?
    private var fastForwardIndex: Int {
        let elapsed = time - splashEnd
        let duration = fastForwardEnd - splashEnd
        let count = allBoardMembers.count
        let perCard = duration / Double(count)
        return min(count - 1, max(0, Int(elapsed / perCard)))
    }

    /// Goldblitz exakt bei 10 s
    private var dropFlash: Double {
        let dt = time - fastForwardEnd
        guard dt >= 0, dt < 1.0 else { return 0 }
        return max(0, 1.0 - dt / 1.0)
    }

    var body: some View {
        ZStack {
            darkBG.ignoresSafeArea()

            MeshBackground(time: time)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            // Vignette
            RadialGradient(
                colors: [.clear, .clear, .black.opacity(0.55)],
                center: .center,
                startRadius: 400,
                endRadius: 1400
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            phaseContent
                .animation(.easeInOut(duration: 0.55), value: phase)

            // Goldblitz Overlay
            goldPrimary
                .opacity(dropFlash * 0.55)
                .blendMode(.plusLighter)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(darkBG.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear {
            guard !hasStarted else { return }
            hasStarted = true
            MusicService.shared.playIntro()
        }
        .onDisappear {
            MusicService.shared.stopIntro()
        }
        .onReceive(frameTimer) { _ in
            time = MusicService.shared.introCurrentTime()
        }
    }

    @ViewBuilder
    private var phaseContent: some View {
        switch phase {
        case .splash:
            SplashView(time: time)
                .transition(.opacity)

        case .fastForward:
            FastForwardView(
                time: time,
                phaseStart: splashEnd,
                currentIndex: fastForwardIndex,
                totalCount: allBoardMembers.count
            )
            .transition(.opacity)

        case .boardsGrid:
            BoardsGridView(
                time: time,
                phaseStart: fastForwardEnd,
                phaseEnd: boardsGridEnd
            )
            .transition(.opacity)

        case .members:
            MembersView(
                time: time,
                phaseStart: boardsGridEnd,
                phaseEnd: membersEnd
            )
            .transition(.opacity)

        case .heart:
            HeartTransitionView(time: time, phaseStart: membersEnd)
                .transition(.opacity)

        case .logoReveal:
            LogoRevealView(
                time: time,
                phaseStart: heartEnd,
                totalDuration: totalDuration
            )
            .transition(.opacity)
        }
    }
}

// MARK: - Splash (0–2 s)
struct SplashView: View {
    let time: Double

    private var bigOpacity: Double { min(1.0, time / 0.7) }
    private var bigScale: Double { 0.9 + min(1.0, time / 1.0) * 0.1 }
    private var subOpacity: Double { max(0.0, min(1.0, (time - 0.7) / 0.7)) }
    private var subOffset: CGFloat { CGFloat(14 * (1 - subOpacity)) }
    private var shimmer: Double {
        ((time - 0.4).truncatingRemainder(dividingBy: 2.0)) / 2.0
    }

    var body: some View {
        VStack(spacing: 18) {
            ZStack {
                Text("25")
                    .font(.system(size: 230, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [goldPrimary, goldAccent],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .shadow(color: goldAccent.opacity(0.55), radius: 32)

                // Glas-Lichtreflex
                Text("25")
                    .font(.system(size: 230, weight: .bold, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: max(0, shimmer - 0.18)),
                                .init(color: .white.opacity(0.85), location: shimmer),
                                .init(color: .clear, location: min(1, shimmer + 0.18))
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .blendMode(.plusLighter)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .opacity(bigOpacity)
            .scaleEffect(bigScale)

            Text("Fachschaft Business School")
                .font(.system(size: 30, weight: .light, design: .rounded))
                .tracking(6)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .opacity(subOpacity)
                .offset(y: subOffset)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 60)
    }
}

// MARK: - FastForward (2–10 s): Schnelldurchlauf eine Karte pro Slot
struct FastForwardView: View {
    let time: Double
    let phaseStart: Double
    let currentIndex: Int
    let totalCount: Int

    private var elapsed: Double { max(0, time - phaseStart) }
    private var titleOpacity: Double { min(1, elapsed / 0.5) }
    private var titleOffset: CGFloat { CGFloat((1 - titleOpacity) * -8) }

    private var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex + 1) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("DANKE")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .tracking(14)
                    .foregroundStyle(goldPrimary)
                Text("an alle Vorstände der vergangenen 25 Jahre")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .opacity(titleOpacity)
            .offset(y: titleOffset)
            .padding(.top, 28)

            Spacer()

            // Fokussierte Karte wechselt rapide
            if currentIndex >= 0 && currentIndex < allBoardMembers.count {
                FeaturedBoardCard(period: allBoardMembers[currentIndex])
                    .id(currentIndex)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.88))
                            .combined(with: .offset(y: 12)),
                        removal: .opacity.combined(with: .scale(scale: 1.04))
                    ))
            }

            Spacer()

            // Progress-Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(goldSubtle.opacity(0.25))
                        .frame(height: 3)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [goldPrimary, goldAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 3)
                        .animation(.easeOut(duration: 0.25), value: progress)
                }
            }
            .frame(height: 3)
            .padding(.horizontal, 120)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.22), value: currentIndex)
    }
}

// Große Karte für den Schnelldurchlauf
struct FeaturedBoardCard: View {
    let period: BoardMemberPeriod

    var body: some View {
        VStack(spacing: 18) {
            Text(period.years)
                .font(.system(size: 24, weight: .semibold, design: .monospaced))
                .tracking(4)
                .foregroundStyle(goldPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, goldDeep.opacity(0.7), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(width: 200, height: 1)

            VStack(spacing: 10) {
                ForEach(period.names, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 56)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(goldSubtle, lineWidth: 1)
                )
                .shadow(color: goldAccent.opacity(0.3), radius: 28)
        )
        .padding(.horizontal, 80)
    }

    private var goldDeep: Color { goldAccent }
}

// MARK: - BoardsGrid (10–30 s): alle 19 sichtbar
struct BoardsGridView: View {
    let time: Double
    let phaseStart: Double
    let phaseEnd: Double

    private var elapsed: Double { max(0, time - phaseStart) }
    private var buildupProgress: Double {
        let buildupStart: Double = 16.0  // 26s absolut = 16s im Phasen-Offset
        return max(0, min(1, (elapsed - buildupStart) / 4.0))
    }

    // Scan-Linie wandert während 10–26s langsam durch das Grid
    private var scanProgress: Double {
        let scanDuration = 16.0
        return min(1.0, max(0, elapsed / scanDuration))
    }

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("DANKE")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .tracking(14)
                    .foregroundStyle(goldPrimary)
                Text("an alle Vorstände der vergangenen 25 Jahre")
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            .padding(.top, 26)

            ZStack(alignment: .top) {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(allBoardMembers.enumerated()), id: \.element.id) { i, period in
                        let appearTime = Double(i) * 0.04
                        let isVisible = elapsed >= appearTime
                        let isCurrent = i == allBoardMembers.count - 1
                        BoardCard(
                            period: period,
                            isVisible: isVisible,
                            isCurrent: isCurrent,
                            floatPhase: time + Double(i) * 0.4
                        )
                    }
                }
                .padding(.horizontal, 36)

                // Scan-Linie als sanftes Highlight von oben nach unten
                LinearGradient(
                    colors: [.clear, goldPrimary.opacity(0.18), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 220)
                .offset(y: CGFloat(-110 + scanProgress * 900))
                .blendMode(.plusLighter)
                .allowsHitTesting(false)
            }
            .scaleEffect(1.0 - buildupProgress * 0.06)
            .opacity(1.0 - buildupProgress * 0.45)
            .blur(radius: buildupProgress * 4)

            Spacer(minLength: 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Board Card
struct BoardCard: View {
    let period: BoardMemberPeriod
    let isVisible: Bool
    let isCurrent: Bool
    let floatPhase: Double

    private var floatOffset: CGFloat {
        CGFloat(sin(floatPhase * 0.5) * 2.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(period.years)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(isCurrent ? goldPrimary : goldPrimary.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            VStack(alignment: .leading, spacing: 3) {
                ForEach(period.names, id: \.self) { name in
                    Text(name)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            isCurrent ? goldPrimary.opacity(0.9) : goldSubtle,
                            lineWidth: isCurrent ? 1.4 : 0.8
                        )
                )
                .shadow(
                    color: isCurrent ? goldAccent.opacity(0.45) : goldAccent.opacity(0.12),
                    radius: isCurrent ? 22 : 10
                )
        )
        .opacity(isVisible ? 1 : 0)
        .blur(radius: isVisible ? 0 : 6)
        .scaleEffect(isVisible ? 1.0 : 0.88)
        .offset(y: isVisible ? floatOffset : 20)
        .animation(.spring(response: 0.55, dampingFraction: 0.78), value: isVisible)
    }
}

// MARK: - Members (30–36 s)
struct MembersView: View {
    let time: Double
    let phaseStart: Double
    let phaseEnd: Double

    private var elapsed: Double { max(0, time - phaseStart) }
    private var fadeOut: Double {
        let fadeStart: Double = (phaseEnd - phaseStart) - 0.9
        return max(0, min(1, (elapsed - fadeStart) / 0.9))
    }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 8) {
                Text("DANKE")
                    .font(.system(size: 26, weight: .semibold, design: .rounded))
                    .tracking(14)
                    .foregroundStyle(goldPrimary)
                    .opacity(min(1, elapsed / 0.5))

                Text("an euch, die sich jeden Tag dafür engagieren")
                    .font(.system(size: 22, weight: .light, design: .rounded))
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .opacity(max(0, min(1, (elapsed - 0.3) / 0.6)))
                    .offset(y: (1 - max(0, min(1, (elapsed - 0.3) / 0.6))) * -8)
            }
            .padding(.top, 28)

            FlowLayout(spacing: 8) {
                ForEach(Array(memberFirstNames.enumerated()), id: \.offset) { i, name in
                    NamePill(
                        name: name,
                        isVisible: elapsed - 0.9 > Double(i) * 0.025
                    )
                }
            }
            .padding(.horizontal, 48)
        }
        .multilineTextAlignment(.center)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(1.0 - fadeOut)
        .scaleEffect(1.0 - fadeOut * 0.04)
    }
}

// MARK: - Glass Name Pill
struct NamePill: View {
    let name: String
    let isVisible: Bool

    var body: some View {
        Text(name)
            .font(.system(size: 17, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.95))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(goldSubtle, lineWidth: 0.7)
                    )
                    .shadow(color: goldAccent.opacity(0.18), radius: 8)
            )
            .opacity(isVisible ? 1 : 0)
            .blur(radius: isVisible ? 0 : 6)
            .scaleEffect(isVisible ? 1 : 0.7)
            .animation(.spring(response: 0.42, dampingFraction: 0.72), value: isVisible)
    }
}

// MARK: - Heart Transition (36–38 s)
struct HeartTransitionView: View {
    let time: Double
    let phaseStart: Double

    private var elapsed: Double { max(0, time - phaseStart) }
    private var appearProgress: Double {
        min(1, elapsed / 0.7)
    }

    /// Lub-dub Herzschlag (zwei Pulse pro ≈ 0,9 s)
    private var heartbeatScale: Double {
        let cycle = 0.9
        let t = elapsed.truncatingRemainder(dividingBy: cycle)
        var beat: Double = 0
        if t < 0.12 {
            beat = sin(t / 0.12 * .pi)
        } else if t > 0.18 && t < 0.30 {
            beat = sin((t - 0.18) / 0.12 * .pi) * 0.65
        }
        return 1.0 + beat * 0.08
    }

    var body: some View {
        ZStack {
            // Sanfter Goldschein
            Circle()
                .fill(
                    RadialGradient(
                        colors: [goldPrimary.opacity(0.45), .clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 380
                    )
                )
                .frame(width: 780, height: 780)
                .blur(radius: 30)
                .opacity(appearProgress)
                .scaleEffect(heartbeatScale)

            LiquidGlassHeart()
                .scaleEffect(0.7 + appearProgress * 0.3)
                .scaleEffect(heartbeatScale)
                .opacity(appearProgress)
        }
    }
}

// MARK: - Liquid Glass Herz
struct LiquidGlassHeart: View {
    var body: some View {
        ZStack {
            // Glas-Korpus (Material durch Herz maskiert)
            Color.clear
                .background(.ultraThinMaterial)
                .mask(
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                )

            // Gold-Schimmer innen
            LinearGradient(
                colors: [
                    goldPrimary.opacity(0.55),
                    goldAccent.opacity(0.35),
                    goldAccent.opacity(0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .mask(
                Image(systemName: "heart.fill")
                    .resizable()
                    .scaledToFit()
            )

            // Glanzlicht oben
            Ellipse()
                .fill(.white.opacity(0.35))
                .frame(width: 80, height: 30)
                .blur(radius: 8)
                .offset(x: -40, y: -70)
                .mask(
                    Image(systemName: "heart.fill")
                        .resizable()
                        .scaledToFit()
                )

            // Gold-Outline
            Image(systemName: "heart")
                .resizable()
                .scaledToFit()
                .foregroundStyle(
                    LinearGradient(
                        colors: [goldPrimary, goldAccent],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .frame(width: 280, height: 280)
        .shadow(color: goldAccent.opacity(0.55), radius: 30)
    }
}

// MARK: - FlowLayout (zentriert)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = computeRows(maxWidth: maxWidth, subviews: subviews)
        let totalHeight = rows.reduce(into: CGFloat(0)) { acc, row in
            acc += row.height
        } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let totalRowWidth = row.items.reduce(into: CGFloat(0)) { acc, item in
                acc += item.size.width
            } + CGFloat(max(0, row.items.count - 1)) * spacing
            var x = bounds.minX + (bounds.width - totalRowWidth) / 2
            for item in row.items {
                subviews[item.index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(item.size)
                )
                x += item.size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct RowItem { let index: Int; let size: CGSize }
    private struct Row { var items: [RowItem]; var height: CGFloat }

    private func computeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentItems: [RowItem] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0
        for (i, sub) in subviews.enumerated() {
            let size = sub.sizeThatFits(.unspecified)
            let needed = currentItems.isEmpty ? size.width : currentWidth + spacing + size.width
            if needed > maxWidth && !currentItems.isEmpty {
                rows.append(Row(items: currentItems, height: currentHeight))
                currentItems = []
                currentWidth = 0
                currentHeight = 0
            }
            if !currentItems.isEmpty { currentWidth += spacing }
            currentItems.append(RowItem(index: i, size: size))
            currentWidth += size.width
            currentHeight = max(currentHeight, size.height)
        }
        if !currentItems.isEmpty {
            rows.append(Row(items: currentItems, height: currentHeight))
        }
        return rows
    }
}

// MARK: - Logo Reveal (38–42 s)
struct LogoRevealView: View {
    let time: Double
    let phaseStart: Double
    let totalDuration: Double

    private var elapsed: Double { max(0, time - phaseStart) }
    private var logoOpacity: Double { min(1, elapsed / 1.0) }
    private var logoScale: Double {
        if elapsed < 1.0 { return 0.85 + elapsed * 0.15 }
        return 1.0
    }
    private var anchorOpacity: Double { max(0, min(1, (elapsed - 0.8) / 0.8)) }

    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [goldPrimary.opacity(0.55), .clear],
                            center: .center,
                            startRadius: 50,
                            endRadius: 380
                        )
                    )
                    .frame(width: 760, height: 760)
                    .blur(radius: 35)
                    .opacity(logoOpacity)

                Image("logo_white")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 360)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .shadow(color: goldAccent.opacity(0.5), radius: 24)
            }

            VStack(spacing: 12) {
                Text("25 JAHRE")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .tracking(14)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [goldPrimary, goldAccent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                HStack(spacing: 18) {
                    Text("2001")
                    Rectangle()
                        .fill(goldSubtle)
                        .frame(width: 26, height: 1.5)
                    Text("2026")
                }
                .font(.system(size: 20, weight: .light, design: .monospaced))
                .tracking(8)
                .foregroundStyle(.white.opacity(0.75))
            }
            .opacity(anchorOpacity)
            .scaleEffect(0.96 + anchorOpacity * 0.04)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 60)
    }
}

// MARK: - Animated Mesh Background
struct MeshBackground: View {
    let time: Double

    var body: some View {
        ZStack {
            AngularGradient(
                colors: [
                    goldAccent.opacity(0.10),
                    .clear,
                    .clear,
                    goldAccent.opacity(0.06),
                    .clear,
                    .clear,
                    goldAccent.opacity(0.10),
                    .clear
                ],
                center: .center,
                angle: .degrees(time * 10)
            )
            .blur(radius: 80)

            ForEach(0..<3, id: \.self) { i in
                let phase = time * 0.18 + Double(i) * 2.0
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [goldAccent.opacity(0.14), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 380
                        )
                    )
                    .frame(width: 760, height: 760)
                    .blur(radius: 40)
                    .offset(
                        x: CGFloat(sin(phase) * 320),
                        y: CGFloat(cos(phase * 0.7) * 220)
                    )
            }
        }
    }
}

#Preview {
    IntroView()
}
