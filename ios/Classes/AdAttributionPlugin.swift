import Flutter
import UIKit

public class AdAttributionPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/ad_attribution",
            binaryMessenger: registrar.messenger()
        )
        let instance = AdAttributionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initImpression":
            guard let args = call.arguments as? [String: Any],
                  let jws = args["jws"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "jws is required", details: nil))
                return
            }
            AdAttributionManager.shared.initImpression(jws: jws) { success in
                result(success)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
