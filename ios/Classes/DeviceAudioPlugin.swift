import Flutter
import AVFoundation

public class DeviceAudioPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/device_audio",
            binaryMessenger: registrar.messenger()
        )
        let instance = DeviceAudioPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAudioInfo":
            result(readAudioInfo())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func readAudioInfo() -> [String: Any] {
        let session = AVAudioSession.sharedInstance()

        let vol01 = session.outputVolume
        var volume = Int((vol01 * 100.0).rounded())
        volume = min(100, max(0, volume))

        // NOTE: this is "volume == 0", not the iOS silent switch.
        let muted = vol01 <= 0.0001

        var kinds = [String]()
        for port in session.currentRoute.outputs {
            switch port.portType {
            case .headphones, .lineOut:
                kinds.append("wired")
            case .bluetoothA2DP, .bluetoothHFP, .bluetoothLE:
                kinds.append("bluetooth")
            case .HDMI:
                kinds.append("hdmi")
            case .usbAudio:
                kinds.append("usb")
            default:
                kinds.append("other")
            }
        }

        let plugged = kinds.contains { $0 != "other" }

        return [
            "volume": volume,
            "muted": muted,
            "outputPluggedIn": plugged,
            "outputType": kinds
        ]
    }
}
