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
        case "setAttributionFrame":
            guard let args = call.arguments as? [String: Any],
                  let x = (args["x"] as? NSNumber)?.doubleValue,
                  let y = (args["y"] as? NSNumber)?.doubleValue,
                  let width = (args["width"] as? NSNumber)?.doubleValue,
                  let height = (args["height"] as? NSNumber)?.doubleValue else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "x, y, width, height are required", details: nil))
                return
            }
            DispatchQueue.main.async {
                AdAttributionManager.shared.setAttributionFrame(
                    x: CGFloat(x),
                    y: CGFloat(y),
                    width: CGFloat(width),
                    height: CGFloat(height)
                ) { success in
                    result(success)
                }
            }
        case "handleTap":
            let url = (call.arguments as? [String: Any])?["url"] as? String
            AdAttributionManager.shared.handleTap(url: url) { success in
                result(success)
            }
        case "beginView":
            AdAttributionManager.shared.beginView { success in
                result(success)
            }
        case "endView":
            AdAttributionManager.shared.endView { success in
                result(success)
            }
        case "dispose":
            AdAttributionManager.shared.dispose { success in
                result(success)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
