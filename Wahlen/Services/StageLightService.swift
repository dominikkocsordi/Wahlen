import Foundation
import ORSSerial

actor StageLightService {

    static let shared = StageLightService()

    private let serialPortPath = "/dev/cu.usbserial-0001"
    private let baudRate: NSNumber = 115200

    private var serialPort: ORSSerialPort?

    init() {
        setupSerialPort()
    }

    private func setupSerialPort() {
        self.serialPort = ORSSerialPort(path: serialPortPath)
        self.serialPort?.baudRate = baudRate
        self.serialPort?.dtr = false
        self.serialPort?.rts = false
        self.serialPort?.open()
        
        if serialPort?.isOpen == true {
            print("🟢 StageLight via USB-C verbunden!")
        } else {
            print("🔴 Fehler: StageLight Port zu.")
        }
    }

    // MARK: - Die neuen, blitzschnellen Befehle

    func setSandTone() async { await sendCommand("0") }
    
    func votingOpenedEffect() async { await sendCommand("1") }
    
    func votingClosedEffect() async { await sendCommand("2") }
    
    func resultsRevealedEffect() async { await sendCommand("3") }
    
    // Du kannst weitere Befehle hinzufügen ("4", "5", etc.)
    func auszaehlungAmbient() async { await sendCommand("6") }
    
    func winnerCelebrationEffect() async { await sendCommand("8") }

    // MARK: - USB-C Datenübertragung

    private func sendCommand(_ command: String) async {
        guard let port = serialPort, port.isOpen else {
            print("⚠️ Port zu. Versuche Reconnect...")
            setupSerialPort()
            return
        }

        // Wir schicken nur noch 1 Byte. Keine Latenz, kein Parsing-Overhead!
        if let data = command.data(using: .utf8) {
            port.send(data)
            print("⚡️ StageLight Kommando gesendet: \(command)")
        }
    }
}
