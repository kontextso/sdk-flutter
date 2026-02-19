import Flutter
import StoreKit
import UIKit

public class SKAdNetworkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/sk_ad_network",
            binaryMessenger: registrar.messenger()
        )
        let instance = SKAdNetworkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initImpression":
            guard let params = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "arguments must be a map", details: nil))
                return
            }
            SKAdNetworkManager.shared.initImpression(params: params) { success in
                result(success)
            }
        case "startImpression":
            SKAdNetworkManager.shared.startImpression { success in
                result(success)
            }
        case "endImpression":
            SKAdNetworkManager.shared.endImpression { success in
                result(success)
            }
        case "dispose":
            SKAdNetworkManager.shared.dispose { success in
                result(success)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}