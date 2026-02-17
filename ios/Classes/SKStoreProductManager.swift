import Foundation
import StoreKit
import Flutter
import UIKit

final class SKStoreProductManager: NSObject, SKStoreProductViewControllerDelegate {
    static let shared = SKStoreProductManager()
    
    private weak var presentedViewController: SKStoreProductViewController?
    
    func present(appStoreId: String, completion: @escaping (Any) -> Void) {
        guard let itemId = Int(appStoreId) else {
            completion(FlutterError(code: "INVALID_ARGUMENTS", message: "appStoreId must be a valid integer string", details: nil))
            return
        }
        let params: [String : Any] = [
            SKStoreProductParameterITunesItemIdentifier: NSNumber(value: itemId)
        ]
        
        let viewController = SKStoreProductViewController()
        viewController.delegate = self
        viewController.loadProduct(withParameters: params) { [weak self] loaded, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard loaded else {
                    completion(FlutterError(code: "LOAD_FAILED", message: "Failed to load product", details: nil))
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
}
