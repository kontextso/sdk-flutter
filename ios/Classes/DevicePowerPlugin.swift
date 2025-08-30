import Flutter
import UIKit

public class DevicePowerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/device_power",
            binaryMessenger: registrar.messenger()
        )
        let instance = DevicePowerPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPowerInfo":
            result(readPowerInfo())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func onMain<T>(_ work: @escaping () -> T) -> T {
        if Thread.isMainThread {
            return work()
        } else {
            var result: T?
            let semaphore = DispatchSemaphore(value: 0)
            DispatchQueue.main.async {
                result = work()
                semaphore.signal()
            }
            semaphore.wait()
            return result!
        }
    }

    private func readPowerInfo() -> Any {
        onMain {
            let device = UIDevice.current
            let prev = device.isBatteryMonitoringEnabled
            device.isBatteryMonitoringEnabled = true
            defer { device.isBatteryMonitoringEnabled = prev }

            var levelPct: Int?
            let raw = device.batteryLevel
            if raw >= 0.0 {
                var pct = Int((raw * 100.0).rounded())
                pct = min(max(pct, 0), 100)
                levelPct = pct
            }

            let stateStr: String = {
                switch device.batteryState {
                case .charging: return "charging"
                case .full: return "full"
                case .unplugged: return "unplugged"
                case .unknown: return "unknown"
                @unknown default: return "unknown"
                }
            }()

            let lowPower = ProcessInfo.processInfo.isLowPowerModeEnabled

            return [
                "level": levelPct as Any,
                "state": stateStr,
                "lowPower": lowPower
            ]
        }
    }
}
