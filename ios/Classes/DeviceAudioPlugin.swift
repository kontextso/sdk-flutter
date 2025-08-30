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

    // Runs a closure while the audio session is briefly active.
    private func withActivatedSession<T>(_ body: @escaping (AVAudioSession) -> T) -> T {
        let session = AVAudioSession.sharedInstance()

        let run: () -> T = {
            let prevCategory = session.category
            let prevMode = session.mode
            let prevPolicy = session.routeSharingPolicy
            let prevOptions = session.categoryOptions

            var didActivate = false
            do {
                try session.setActive(true, options: [])
                didActivate = true
            } catch {
				// Ignore
			}

            let out = body(session)

            if didActivate {
                _ = try? session.setActive(false, options: [.notifyOthersOnDeactivation])
            }
            _ = try? session.setCategory(
                prevCategory,
                mode: prevMode,
                policy: prevPolicy,
                options: prevOptions
            )

            return out
        }

        if Thread.isMainThread { return run() }
        return DispatchQueue.main.sync(execute: run)
    }

    private func readAudioInfo() -> [String: Any] {
        return withActivatedSession { session in
            let vol01 = session.outputVolume
            var volume = Int((vol01 * 100.0).rounded())
            if volume < 0 { volume = 0 }
            if volume > 100 { volume = 100 }
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
}
