import Foundation

actor StageLightService {

    static let shared = StageLightService()

    private let serialPortPath = "/dev/cu.usbserial-0001"
    private let baudRate: speed_t = 115200

    private var fileDescriptor: Int32 = -1

    init() {
        openPort()
    }

    private func openPort() {
        let fd = open(serialPortPath, O_RDWR | O_NOCTTY | O_NONBLOCK)
        guard fd != -1 else {
            print("🔴 Fehler: StageLight Port zu (\(serialPortPath))")
            return
        }

        var options = termios()
        tcgetattr(fd, &options)

        cfmakeraw(&options)
        cfsetispeed(&options, baudRate)
        cfsetospeed(&options, baudRate)

        options.c_cflag |= tcflag_t(CLOCAL | CREAD)
        options.c_cflag &= ~tcflag_t(HUPCL)

        tcsetattr(fd, TCSANOW, &options)
        fileDescriptor = fd
        print("🟢 StageLight via USB-C verbunden!")
    }

    // MARK: - Befehle

    func setSandTone() async { await sendCommand("0") }

    func votingOpenedEffect() async { await sendCommand("1") }

    func votingClosedEffect() async { await sendCommand("2") }

    func resultsRevealedEffect() async { await sendCommand("3") }

    func auszaehlungAmbient() async { await sendCommand("6") }

    func winnerCelebrationEffect() async { await sendCommand("8") }

    // MARK: - Serielle Übertragung

    private func sendCommand(_ command: String) async {
        if fileDescriptor == -1 {
            print("⚠️ Port zu. Versuche Reconnect...")
            openPort()
            guard fileDescriptor != -1 else { return }
        }

        guard let data = command.data(using: .utf8) else { return }
        let result = data.withUnsafeBytes { ptr in
            write(fileDescriptor, ptr.baseAddress!, data.count)
        }
        if result == -1 {
            print("⚠️ Senden fehlgeschlagen, schließe Port.")
            close(fileDescriptor)
            fileDescriptor = -1
        } else {
            print("⚡️ StageLight Kommando gesendet: \(command)")
        }
    }
}
