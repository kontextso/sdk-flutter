import Flutter
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
            guard let params = call.arguments as? [String: Any], !params.isEmpty else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "params must be a non-empty map", details: nil))
                return
            }
            SKAdNetworkManager.shared.initImpression(params: params) { res in
                result(res)
            }
        case "startImpression":
            SKAdNetworkManager.shared.startImpression { res in
                result(res)
            }
        case "endImpression":
            SKAdNetworkManager.shared.endImpression { res in
                result(res)
            }
        case "dispose":
            SKAdNetworkManager.shared.dispose { res in
                result(res)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}