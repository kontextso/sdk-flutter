import Flutter
import Foundation

final class OMSDKPlugin: NSObject, FlutterPlugin {
    private let omService: OMManaging

    init(omService: OMManaging = OMManager.shared) {
        self.omService = omService
        super.init()
    }

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: OMConstants.channelName,
            binaryMessenger: registrar.messenger()
        )
        let plugin = OMSDKPlugin()
        registrar.addMethodCallDelegate(plugin, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "activate":
            result(omService.activate())
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
