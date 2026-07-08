import Flutter
import Foundation

public class SKStoreProductPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/sk_store_product",
            binaryMessenger: registrar.messenger()
        )
        let instance = SKStoreProductPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "present":
            guard let params = call.arguments as? [String: Any] else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "arguments must be a map", details: nil))
                return
            }
            DispatchQueue.main.async {
                SKStoreProductManager.shared.present(skan: params) { res in
                    result(res)
                }
            }
        case "dismiss":
            DispatchQueue.main.async {
                SKStoreProductManager.shared.dismiss { success in
                    result(success)
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
