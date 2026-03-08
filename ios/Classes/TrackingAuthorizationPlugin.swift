import Flutter
import UIKit
import AppTrackingTransparency

public class TrackingAuthorizationPlugin: NSObject, FlutterPlugin {
    private var observer: NSObjectProtocol?
    private static let notSupportedStatus = 4

    deinit {
        removeObserver()
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "kontext_flutter_sdk/tracking_authorization",
            binaryMessenger: registrar.messenger()
        )
        let instance = TrackingAuthorizationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getTrackingAuthorizationStatus":
            getTrackingAuthorizationStatus(result: result)
        case "requestTrackingAuthorization":
            requestTrackingAuthorization(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getTrackingAuthorizationStatus(result: @escaping FlutterResult) {
        if #available(iOS 14, *) {
            result(Int(ATTrackingManager.trackingAuthorizationStatus.rawValue))
        } else {
            result(Self.notSupportedStatus)
        }
    }

    private func requestTrackingAuthorization(result: @escaping FlutterResult) {
        if #available(iOS 14, *) {
            requestTrackingAuthorizationWhenActive(result: result)
        } else {
            result(Self.notSupportedStatus)
        }
    }

    @available(iOS 14, *)
    private func requestTrackingAuthorizationWhenActive(result: @escaping FlutterResult) {
        if UIApplication.shared.applicationState != .active {
            addObserver(result: result)
            return
        }

        removeObserver()
        ATTrackingManager.requestTrackingAuthorization { [weak self] status in
            if status == .denied && ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
                self?.addObserver(result: result)
                return
            }

            self?.removeObserver()
            result(Int(status.rawValue))
        }
    }

    private func addObserver(result: @escaping FlutterResult) {
        removeObserver()
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.requestTrackingAuthorization(result: result)
        }
    }

    private func removeObserver() {
        if let observer = observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }
}
