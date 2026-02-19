import Flutter
import UIKit

public class AdAttributionKitPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/ad_attribution_kit",
            binaryMessenger: registrar.messenger()
        )
        let instance = AdAttributionKitPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initImpression":
            guard let args = call.arguments as? [String: Any],
                let jws = args["jws"] as? String,
                !jws.isEmpty else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "jws is required and must not be empty", details: nil))
                return
            }
            AdAttributionKitManager.shared.initImpression(jws: jws) { success in
                result(success)
            }
        case "setAttributionFrame":
            guard let args = call.arguments as? [String: Any],
                let width = (args["width"] as? NSNumber)?.doubleValue,
                let height = (args["height"] as? NSNumber)?.doubleValue else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "width and height are required", details: nil))
                return
            }
            let x = (args["x"] as? NSNumber)?.doubleValue ?? 0
            let y = (args["y"] as? NSNumber)?.doubleValue ?? 0
            AdAttributionKitManager.shared.setAttributionFrame(
                x: CGFloat(x),
                y: CGFloat(y),
                width: CGFloat(width),
                height: CGFloat(height)
            ) { success in
                result(success)
            }
        case "handleTap":
            let url = (call.arguments as? [String: Any])?["url"] as? String
            AdAttributionKitManager.shared.handleTap(url: url) { success in
                result(success)
            }
        case "beginView":
            AdAttributionKitManager.shared.beginView { success in
                result(success)
            }
        case "endView":
            AdAttributionKitManager.shared.endView { success in
                result(success)
            }
        case "dispose":
            AdAttributionKitManager.shared.dispose { success in
                result(success)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}