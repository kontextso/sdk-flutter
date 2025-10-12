import Flutter
import Foundation
import UIKit
import AdAttributionKit

final class AdAttributionManager {
    static let shared = AdAttributionManager()
    
    private var appImpressionBox: Any?
    private var attributionViewBox: Any?
    private weak var hostWindow: UIWindow?
    
    @available(iOS 17.4, *)
    private var appImpression: AppImpression? {
        get { appImpressionBox as? AppImpression }
        set { appImpressionBox = newValue }
    }
    
    @available(iOS 17.4, *)
    private var attributionView: UIEventAttributionView? {
        get { attributionViewBox as? UIEventAttributionView }
        set { attributionViewBox = newValue }
    }
    
    func initImpression(jws: String, completion: @escaping (Any) -> Void) {
        guard #available(iOS 17.4, *) else {
            completion(false)
            return
        }
        Task { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            do {
                let imp = try await AppImpression(compactJWS: jws)
                self.appImpression = imp
                completion(true)
            } catch {
                completion(FlutterError(code: "INIT_IMPRESSION_FAILED", message: "Failed to initialize AppImpression: \(error)", details: nil))
            }
        }
    }
    
    /// Places the UIEventAttributionView in window coordinates over the ad.
    func setAttributionFrame(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, completion: @escaping (Any) -> Void) {
        guard #available(iOS 17.4, *) else {
            completion(false)
            return
        }
        
        guard width > 0, height > 0 else {
            if let view = attributionView {
                view.removeFromSuperview()
                attributionView = nil
            }
            hostWindow = nil
            completion(false)
            return
        }
        
        guard let window = currentKeyWindow() else {
            completion(FlutterError(code: "NO_KEY_WINDOW", message: "No key window found", details: nil))
            return
        }
        
        if attributionView == nil {
            let view = UIEventAttributionView()
            // Ensure the view does not interfere with normal user interaction
            view.isUserInteractionEnabled = false
            window.addSubview(view)
            attributionView = view
        }
        
        attributionView?.frame = CGRect(x: x, y: y, width: width, height: height)
        hostWindow = window
        completion(true)
    }
    
    func handleTap(url: String?, completion: @escaping (Any) -> Void) {
        guard #available(iOS 18.0, *) else {
            completion(false)
            return
        }
        guard let impression = appImpression else {
            completion(FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
            return
        }
        
        Task { [weak self] in
            guard let self = self else {
                completion(false)
                return
            }
            do {
                if let urlString = url, let reengagementURL = URL(string: urlString) {
                    try await impression.handleTap(reengagementURL: reengagementURL)
                } else {
                    try await impression.handleTap()
                }
                completion(true)
            } catch {
                completion(FlutterError(code: "HANDLE_TAP_FAILED", message: "Failed to handle tap: \(error)", details: nil))
            }
        }
    }
    
    private func currentKeyWindow() -> UIWindow? {
        // Scan scenes by activation, prefer .foregroundActive, then .foregroundInactive
        if #available(iOS 13.0, *) {
            let scenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
            
            func pickWindow(in scene: UIWindowScene) -> UIWindow? {
                // Key window first
                if let key = scene.windows.first(where: { $0.isKeyWindow }) {
                    return key
                }
                // Then visible window, normal-level window
                return scene.windows.first(where: { !$0.isHidden && $0.windowLevel == .normal })
            }
            
            
            if let scene = scenes.first(where: { $0.activationState == .foregroundActive}),
               let window = pickWindow(in: scene) {
                return window
            }
            
            if let scene = scenes.first(where: { $0.activationState == .foregroundInactive}),
               let window = pickWindow(in: scene) {
                return window
            }
        } else {
            if let window = UIApplication.shared.keyWindow {
                return window
            }
        }
        
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { !$0.isHidden && $0.windowLevel == .normal })
        }
        
        return nil
    }
}
