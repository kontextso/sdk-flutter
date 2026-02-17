import Flutter
import Foundation

public class SKOverlayPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/sk_overlay",
            binaryMessenger: registrar.messenger()
        )
        let instance = SKOverlayPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        SKOverlayManager.shared.attach(channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "present":
            guard let args = call.arguments as? [String: Any],
                  let appStoreId = args["appStoreId"] as? String,
                  let position = args["position"] as? String,
                  let dismissible = args["dismissible"] as? Bool else {
                result(FlutterError(
                    code: "INVALID_ARGUMENTS",
                    message: "Invalid or missing arguments",
                    details: [
                        "provided_type": String(describing: type(of: call.arguments)),
                        "provided_keys": (call.arguments as? [String: Any]).map { Array($0.keys) } ?? []
                    ]
                ))
                return
            }
            DispatchQueue.main.async {
                SKOverlayManager.shared.present(
                    appStoreId: appStoreId,
                    position: position,
                    dismissible: dismissible
                ) { res in
                    result(res)
                }
            }
        case "dismiss":
            DispatchQueue.main.async {
                SKOverlayManager.shared.dismiss { success in
                    result(success)
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
