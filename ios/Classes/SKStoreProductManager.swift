import Foundation
import StoreKit
import Flutter
import UIKit

final class SKStoreProductManager: NSObject, SKStoreProductViewControllerDelegate {
    private override init() {}
    static let shared = SKStoreProductManager()
    
    private weak var presentedViewController: SKStoreProductViewController?
    
    func present(skan: [String: Any], completion: @escaping (Any) -> Void) {
        guard let itunesItem = skan["itunesItem"] as? String,
              let itemId = Int(itunesItem) else {
            completion(FlutterError(code: "INVALID_ARGUMENTS", message: "itunesItem must be a valid integer string", details: nil))
            return
        }

        var params: [String: Any] = [
            SKStoreProductParameterITunesItemIdentifier: NSNumber(value: itemId)
        ]
        Self.applySkanParams(skan, into: &params)
        
        let viewController = SKStoreProductViewController()
        viewController.delegate = self
        viewController.loadProduct(withParameters: params) { [weak self] loaded, error in
            DispatchQueue.main.async {
                guard let self = self else {
                    completion(FlutterError(code: "MANAGER_DEALLOCATED", message: "Manager was deallocated", details: nil))
                    return
                }
                guard loaded else {
                    let errorMessage = error?.localizedDescription ?? "Failed to load product"
                    completion(FlutterError(code: "LOAD_FAILED", message: errorMessage, details: nil))
                    return
                }
                
                self.dismiss { [weak self] _ in
                    guard let self = self else { return }
                    guard let top = self.topViewController() else {
                        completion(FlutterError(code: "NO_TOP_VIEW_CONTROLLER", message: "No top view controller found", details: nil))
                        return
                    }
                    
                    top.present(viewController, animated: true) { [weak self] in
                        self?.presentedViewController = viewController
                        completion(true)
                    }
                }
            }
        }
    }

    // MARK: - SKAN

    /// Picks nonce/timestamp/signature from the fidelity-1 entry only.
    /// Returns nil if no fidelity-1 entry exists — no fallback to top-level fields
    /// since those are fidelity-0 values signed with a different formula.
    private static func fidelity1Values(from skan: [String: Any]) -> (nonce: String, timestamp: String, signature: String)? {
        guard let fidelities = skan["fidelities"] as? [[String: Any]],
              let f1 = fidelities.first(where: { ($0["fidelity"] as? Int) == 1 }),
              let nonce     = f1["nonce"]     as? String, !nonce.isEmpty,
              let timestamp = f1["timestamp"] as? String, !timestamp.isEmpty,
              let signature = f1["signature"] as? String, !signature.isEmpty
        else { return nil }
        return (nonce, timestamp, signature)
    }

    /// Appends all required SKAN install-validation keys to the SKStoreProduct params dict.
    private static func applySkanParams(_ skan: [String: Any], into params: inout [String: Any]) {
        guard
            let version   = skan["version"]   as? String, !version.isEmpty,
            let network   = skan["network"]   as? String, !network.isEmpty,
            let sourceApp = skan["sourceApp"] as? String,
            let f1        = fidelity1Values(from: skan)
        else { return }

        let sourceAppInt = Int(sourceApp) ?? 0
        let campaignInt  = (skan["campaign"] as? String).flatMap { Int($0) } ?? 0
        let timestampInt = Int(f1.timestamp) ?? 0

        params[SKStoreProductParameterAdNetworkVersion]                  = version
        params[SKStoreProductParameterAdNetworkIdentifier]               = network
        params[SKStoreProductParameterAdNetworkSourceAppStoreIdentifier] = NSNumber(value: sourceAppInt)
        params[SKStoreProductParameterAdNetworkCampaignIdentifier]       = NSNumber(value: campaignInt)
        params[SKStoreProductParameterAdNetworkTimestamp]                = NSNumber(value: timestampInt)
        params[SKStoreProductParameterAdNetworkNonce]                    = f1.nonce
        params[SKStoreProductParameterAdNetworkAttributionSignature]     = f1.signature

        if let sourceIdentifier = skan["sourceIdentifier"] as? String,
           let sourceIdentifierInt = Int(sourceIdentifier) {
            params[SKStoreProductParameterAdNetworkSourceIdentifier] = NSNumber(value: sourceIdentifierInt)
        }
    }
    
    func dismiss(completion: @escaping (Bool) -> Void) {
        let run: () -> Void = { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let viewController = self.presentedViewController {
                viewController.dismiss(animated: true) { [weak self] in
                    self?.presentedViewController = nil
                    completion(true)
                }
                return
            }
            
            if let top = self.topViewController(),
               let storeViewController = top.presentedViewController as? SKStoreProductViewController {
                storeViewController.dismiss(animated: true) { [weak self] in
                    self?.presentedViewController = nil
                    completion(true)
                }
                return
            }
            
            completion(false)
        }
        
        if Thread.isMainThread {
            run()
        } else {
            DispatchQueue.main.async(execute: run)
        }
    }
    
    private func topViewController(base: UIViewController? = nil) -> UIViewController? {
        let seed: UIViewController? = base ?? {
            if #available(iOS 13.0, *) {
                let scene = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .first { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }
                return scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
            } else {
                return UIApplication.shared.keyWindow?.rootViewController
            }
        }()
        
        guard let seed = seed else { return nil }
        
        if let nav = seed as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = seed as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = seed.presentedViewController {
            return topViewController(base: presented)
        }
        return seed
    }

    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true) { [weak self] in
            self?.presentedViewController = nil
        }
    }
}
