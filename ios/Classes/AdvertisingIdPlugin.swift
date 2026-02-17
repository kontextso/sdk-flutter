import Flutter
import UIKit
import AdSupport
import AppTrackingTransparency

public class AdvertisingIdPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/advertising_id",
            binaryMessenger: registrar.messenger()
        )
        let instance = AdvertisingIdPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getAdvertisingId":
            result(Self.getAdvertisingId())
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func getAdvertisingId() -> String? {
        let manager = ASIdentifierManager.shared()
        if #available(iOS 14.0, *) {
            return ATTrackingManager.trackingAuthorizationStatus == .authorized
                ? manager.advertisingIdentifier.uuidString
                : nil
        }

        return manager.isAdvertisingTrackingEnabled
            ? manager.advertisingIdentifier.uuidString
            : nil
    }
}
