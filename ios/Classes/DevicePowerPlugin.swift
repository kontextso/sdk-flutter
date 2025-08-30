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

    private func readPowerInfo() -> [String: Any] {
        let compute: () -> [String: Any] = {
            let device = UIDevice.current
            let prev = device.isBatteryMonitoringEnabled
            device.isBatteryMonitoringEnabled = true
            defer { device.isBatteryMonitoringEnabled = prev }

            // Battery level: -1.0 means unavailable
            var levelPct: Int?
            let raw = device.batteryLevel
            if raw >= 0.0 {
                var pct = Int((raw * 100.0).rounded())
                if pct < 0 { pct = 0 }
                if pct > 100 { pct = 100 }
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
                "level": (levelPct as Any?) ?? NSNull(),
                "state": stateStr,
                "lowPower": lowPower
            ]
        }

        if Thread.isMainThread { return compute() }
        return DispatchQueue.main.sync(execute: compute)
    }
}
