import Foundation
import StoreKit
import Flutter
import UIKit

final class SKOverlayManager: NSObject {
    private override init() {}
    static let shared = SKOverlayManager()

    @available(iOS 16.0, *)
    private var overlay: SKOverlay? {
        get { _overlay as? SKOverlay }
        set { _overlay = newValue }
    }
    private var _overlay: AnyObject?

    private var pendingPresentCompletion: ((Any) -> Void)?
    private var pendingDismissCompletion: ((Bool) -> Void)?
    
    func present(skan: [String: Any], position: String, dismissible: Bool, completion: @escaping (Any) -> Void) {
        runOnMain { [weak self] in
            guard let self = self else { return }
            guard #available(iOS 16.0, *) else {
                completion(
                    FlutterError(
                        code: "UNSUPPORTED_IOS",
                        message: "SKOverlay requires iOS 16.0 or later",
                        details: nil
                    )
                )
                return
            }
            guard self.pendingPresentCompletion == nil,
                  self.pendingDismissCompletion == nil else {
                completion(
                    FlutterError(
                        code: "OPERATION_IN_PROGRESS",
                        message: "SKOverlay operation already in progress",
                        details: nil
                    )
                )
                return
            }
            guard self.activeScene() != nil else {
                completion(FlutterError(code: "NO_ACTIVE_SCENE", message: "No active UIWindowScene found", details: nil))
                return
            }
            
            self.dismiss { [weak self] _ in
                guard let self = self else { return }
                guard let scene = self.activeScene() else {
                    completion(FlutterError(code: "NO_ACTIVE_SCENE", message: "No active UIWindowScene found", details: nil))
                    return
                }

                guard let itunesItem = skan["itunesItem"] as? String, !itunesItem.isEmpty else {
                    completion(FlutterError(code: "INVALID_ARGUMENTS", message: "itunesItem is required", details: nil))
                    return
                }
                
                let pos: SKOverlay.Position = (position.lowercased() == "bottomraised") ? .bottomRaised : .bottom
                let config = SKOverlay.AppConfiguration(appIdentifier: itunesItem, position: pos)
                config.userDismissible = dismissible

                // Wire up fidelity-1 SKAN attribution if available
                guard Self.applyImpression(skan, to: config) else {
                    completion(FlutterError(
                        code: "INVALID_ARGUMENTS",
                        message: "Failed to apply SKAN impression — fidelity-1 data missing or invalid",
                        details: nil
                    ))
                    return
                }

                let overlay = SKOverlay(configuration: config)
                overlay.delegate = self
                
                self.overlay = overlay
                self.pendingPresentCompletion = completion
                overlay.present(in: scene)
            }
        }
    }

    // MARK: - SKAN
    @available(iOS 16.0, *)
    private static func fidelity1Values(from skan: [String: Any]) -> (nonce: String, timestamp: NSNumber, signature: String)? {
        guard let fidelities = skan["fidelities"] as? [[String: Any]],
            let f1 = fidelities.first(where: { ($0["fidelity"] as? Int) == 1 }),
            let nonce     = f1["nonce"]      as? String, !nonce.isEmpty,
            let signature = f1["signature"]  as? String, !signature.isEmpty
        else { return nil }

        let timestamp: NSNumber
        if let n = f1["timestamp"] as? NSNumber { timestamp = n }
        else if let s = f1["timestamp"] as? String, let i = Int(s) { timestamp = NSNumber(value: i) }
        else { return nil }

        return (nonce, timestamp, signature)
    }

    @available(iOS 16.0, *)
    private static func applyImpression(_ skan: [String: Any], to config: SKOverlay.AppConfiguration) -> Bool {
        guard #available(iOS 16.0, *) else { return false }

        guard
            let version   = skan["version"]   as? String, !version.isEmpty,
            let network   = skan["network"]   as? String, !network.isEmpty,
            let itunesItem = skan["itunesItem"] as? String,
            let itemId    = Int(itunesItem),
            let sourceApp = skan["sourceApp"] as? String,
            let f1        = fidelity1Values(from: skan)
        else { return false }

        let sourceAppInt = Int(sourceApp) ?? 0
        let campaignInt  = (skan["campaign"] as? String).flatMap { Int($0) } ?? 0

        let imp = SKAdImpression()
        imp.version                          = version
        imp.adNetworkIdentifier              = network
        imp.advertisedAppStoreItemIdentifier = NSNumber(value: itemId)
        imp.sourceAppStoreItemIdentifier     = NSNumber(value: sourceAppInt)
        imp.adCampaignIdentifier             = NSNumber(value: campaignInt)
        imp.adImpressionIdentifier           = f1.nonce
        imp.timestamp                        = f1.timestamp
        imp.signature                        = f1.signature

        if #available(iOS 16.1, *) {
            if let sourceIdentifier = skan["sourceIdentifier"] as? String,
            let sourceIdentifierInt = Int(sourceIdentifier) {
                imp.sourceIdentifier = NSNumber(value: sourceIdentifierInt)
            }
        }

        config.setAdImpression(imp)
        return true
    }
    
    func dismiss(completion: @escaping (Bool) -> Void) {
        runOnMain { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            guard #available(iOS 16.0, *) else {
                completion(false)
                return
            }
            guard self.pendingDismissCompletion == nil else {
                completion(false)
                return
            }
            guard self.overlay != nil else {
                completion(false)
                return
            }
            guard let scene = self.activeScene() else {
                completion(false)
                return
            }
            
            self.pendingDismissCompletion = completion
            SKOverlay.dismiss(in: scene)
        }
    }
    
    private func runOnMain(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }
    
    @available(iOS 13.0, *)
    private func activeScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
    }
}

@available(iOS 16.0, *)
extension SKOverlayManager: SKOverlayDelegate {
    func storeOverlayDidFailToLoad(_ overlay: SKOverlay, error: Error) {
        runOnMain { [weak self] in
            guard let self = self else { return }
            if let tracked = self.overlay, tracked === overlay {
                self.overlay = nil
            }
            
            let completion = self.pendingPresentCompletion
            self.pendingPresentCompletion = nil
            completion?(
                FlutterError(
                    code: "LOAD_FAILED",
                    message: "Failed to load SKOverlay",
                    details: error.localizedDescription
                )
            )
        }
    }
    
    func storeOverlayDidFinishPresentation(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        runOnMain { [weak self] in
            guard let self = self else { return }
            let completion = self.pendingPresentCompletion
            self.pendingPresentCompletion = nil
            completion?(true)
        }
    }
    
    func storeOverlayDidFinishDismissal(_ overlay: SKOverlay, transitionContext: SKOverlay.TransitionContext) {
        runOnMain { [weak self] in
            guard let self = self else { return }
            if let tracked = self.overlay, tracked === overlay {
                self.overlay = nil
            }
            
            let completion = self.pendingDismissCompletion
            self.pendingDismissCompletion = nil
            completion?(true)
        }
    }
}
