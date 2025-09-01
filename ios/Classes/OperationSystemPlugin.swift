import Flutter
import Foundation

public class OperationSystemPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/operation_system",
            binaryMessenger: registrar.messenger()
        )
        let instance = OperationSystemPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getTimezone":
            result(TimeZone.current.identifier)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
