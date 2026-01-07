import Flutter
import UIKit

public class TransparencyConsentFrameworkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/transparency_consent_framework",
            binaryMessenger: registrar.messenger()
        )
        let instance = TransparencyConsentFrameworkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getTCFData":
            result(Self.getTcfData())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    /// Returns minimal TCF data needed for RTB:
    /// - gdprApplies (0 | 1 | null)
    /// - tcString (String | null)
    private static func getTcfData() -> NSDictionary {
        let defaults = UserDefaults.standard
        let out = NSMutableDictionary()

        if let tcString = defaults.string(forKey: "IABTCF_TCString") {
            out["tcString"] = tcString
        } else {
            out["tcString"] = NSNull()
        }

        if let raw = defaults.object(forKey: "IABTCF_gdprApplies") {
            // Normalize to 0 / 1
            if let n = raw as? NSNumber {
                out["gdprApplies"] = n.intValue
            } else if let b = raw as? Bool {
                out["gdprApplies"] = b ? 1 : 0
            } else if let s = raw as? String, let i = Int(s) {
                out["gdprApplies"] = i
            } else {
                out["gdprApplies"] = NSNull()
            }
        } else {
            out["gdprApplies"] = NSNull()
        }

        return out
    }
}
