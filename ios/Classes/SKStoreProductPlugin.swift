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
            guard let args = call.arguments as? [String: Any],
            let appStoreId = args["appStoreId"] as? String else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "appStoreId is required", details: nil))
                return
            }
            DispatchQueue.main.async {
                SKStoreProductManager.shared.present(appStoreId: appStoreId) { success in
                    result(success)
                }
            }
        case "dismiss":
            DispatchQueue.main.async {
                let success = SKStoreProductManager.shared.dismiss()
                result(success)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
