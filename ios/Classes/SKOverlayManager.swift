import Foundation
import StoreKit
import Flutter
import UIKit

final class SKOverlayManager: NSObject {
    static let shared = SKOverlayManager()
    
    private weak var channel: FlutterMethodChannel?
    private var overlay: AnyObject?
    private var pendingPresentCompletion: ((Any) -> Void)?
    private var pendingDismissCompletion: ((Bool) -> Void)?
    
    func attach(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    func present(appStoreId: String, position: String, dismissible: Bool, completion: @escaping (Any) -> Void) {
        runOnMain { [weak self] in
            guard let self = self else { return }
            guard #available(iOS 14.0, *) else {
                completion(
                    FlutterError(
                        code: "UNSUPPORTED_IOS",
                        message: "SKOverlay requires iOS 14.0 or later",
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
                
                let pos: SKOverlay.Position = (position.lowercased() == "bottomraised") ? .bottomRaised : .bottom
                let config = SKOverlay.AppConfiguration(appIdentifier: appStoreId, position: pos)
                config.userDismissible = dismissible
                
                let overlay = SKOverlay(configuration: config)
                overlay.delegate = self
                
                self.overlay = overlay
                self.pendingPresentCompletion = completion
                overlay.present(in: scene)
            }
        }
    }
    
    func dismiss(completion: @escaping (Bool) -> Void) {
        runOnMain { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            guard #available(iOS 14.0, *) else {
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

@available(iOS 14.0, *)
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
