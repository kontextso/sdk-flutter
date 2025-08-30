import Flutter
import UIKit
import Foundation

public class DeviceHardwarePlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/device_hardware",
            binaryMessenger: registrar.messenger()
        )
        let instance = DeviceHardwarePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getBootEpochMs":
            // Apple’s 8FFB.1 explicitly disallows transmitting boot time.
            result(nil)
        case "hasRemovableSdCard":
            result(false)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
