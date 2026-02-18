import Flutter
import Foundation
import UIKit
import AdAttributionKit

final class AdAttributionKitManager {
    static let shared = AdAttributionKitManager()
    private init() {}
    
    private var appImpressionBox: Any?
    private var attributionViewBox: Any?
    private weak var hostWindow: UIWindow?
    private var initTask: Task<Void, Never>?
    
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

        if appImpression != nil {
            print("[AdAttributionKit] Warning: replacing existing impression")
        }

        initTask?.cancel()
        initTask = Task { @MainActor in
            do {
                let imp = try await AppImpression(compactJWS: jws)
                self.appImpression = imp
                completion(true)
            } catch is CancellationError {
                // Task was cancelled by a subsequent initImpression call — do nothing
            } catch {
                completion(FlutterError(
                    code: "INIT_IMPRESSION_FAILED",
                    message: "Failed to initialize AppImpression: \(error)",
                    details: nil
                ))
            }
        }
    }
    
    /// Places the UIEventAttributionView in window coordinates over the ad.
    func setAttributionFrame(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, completion: @escaping (Any) -> Void) {
        assert(Thread.isMainThread, "setAttributionFrame must be called on the main thread")

        guard #available(iOS 17.4, *) else {
            completion(false)
            return
        }
        
        guard width > 0, height > 0 else {
            attributionView?.removeFromSuperview()
            attributionView = nil
            hostWindow = nil
            completion(true)
            return
        }
        
        guard let window = currentKeyWindow() else {
            completion(FlutterError(code: "NO_KEY_WINDOW", message: "No key window found", details: nil))
            return
        }
        
        if attributionView == nil {
            let view = UIEventAttributionView()
            view.isUserInteractionEnabled = false
            window.addSubview(view)
            attributionView = view
        } else if attributionView?.window == nil {
            // View exists but was detached — re-add it
            window.addSubview(attributionView!)
        } else if attributionView?.window !== window {
            // Window changed — move to new window
            attributionView?.removeFromSuperview()
            window.addSubview(attributionView!)
        }

        attributionView?.frame = CGRect(x: x, y: y, width: width, height: height)
        hostWindow = window
        completion(true)
    }
    
    func handleTap(url: String?, completion: @escaping (Any) -> Void) {
        guard #available(iOS 17.4, *) else {
            completion(false)
            return
        }

        if let urlString = url, !urlString.isEmpty {
            guard let impression = appImpression else {
                completion(FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
                return
            }
            guard #available(iOS 18.0, *) else {
                completion(FlutterError(code: "UNSUPPORTED_IOS_VERSION", message: "Handling reengagement URL requires iOS 18.0 or later", details: nil))
                return
            }
            guard let reengagementURL = URL(string: urlString) else {
                completion(FlutterError(code: "INVALID_URL", message: "Provided URL is invalid", details: nil))
                return
            }

            Task { @MainActor in
                do {
                    try await impression.handleTap(reengagementURL: reengagementURL)
                    completion(true)
                } catch {
                    completion(FlutterError(code: "HANDLE_TAP_FAILED", message: "Failed to handle tap with URL: \(error)", details: nil))
                }
            }
            return
        }

        guard let impression = appImpression else {
            completion(FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
            return
        }

        Task { @MainActor in
            do {
                try await impression.handleTap()
                completion(true)
            } catch {
                completion(FlutterError(code: "HANDLE_TAP_FAILED", message: "Failed to handle tap: \(error)", details: nil))
            }
        }
    }

    func beginView(completion: @escaping (Any) -> Void) {
        guard #available(iOS 17.4, *) else {
            completion(false)
            return
        }
        guard let impression = appImpression else {
            completion(FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
            return
        }

        Task { @MainActor in
            do {
                try await impression.beginView()
                completion(true)
            } catch {
                completion(FlutterError(code: "BEGIN_VIEW_FAILED", message: "Failed to begin view: \(error)", details: nil))
            }
        }
    }

    func endView(completion: @escaping (Any) -> Void) {
        guard #available(iOS 17.4, *) else {
            completion(false)
            return
        }
        guard let impression = appImpression else {
            completion(FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
            return
        }

        Task { @MainActor in
            do {
                try await impression.endView()
                completion(true)
            } catch {
                completion(FlutterError(code: "END_VIEW_FAILED", message: "Failed to end view: \(error)", details: nil))
            }
        }
    }

    func dispose(completion: @escaping (Any) -> Void) {
        initTask?.cancel()
        initTask = nil

        let uiCleanup = {
            if #available(iOS 17.4, *) {
                self.attributionView?.removeFromSuperview()
                self.attributionView = nil
            }
            self.appImpressionBox = nil
            self.hostWindow = nil
            completion(true)
        }

        if Thread.isMainThread {
            uiCleanup()
        } else {
            DispatchQueue.main.async { uiCleanup() }
        }
    }
    
    private func currentKeyWindow() -> UIWindow? {
        guard #available(iOS 13.0, *) else {
            return UIApplication.shared.keyWindow
        }

        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        func pickWindow(in scene: UIWindowScene) -> UIWindow? {
            if let key = scene.windows.first(where: { $0.isKeyWindow }) {
                return key
            }
            return scene.windows.first(where: { !$0.isHidden && $0.windowLevel == .normal })
        }

        if let scene = scenes.first(where: { $0.activationState == .foregroundActive }),
        let window = pickWindow(in: scene) {
            return window
        }

        if let scene = scenes.first(where: { $0.activationState == .foregroundInactive }),
        let window = pickWindow(in: scene) {
            return window
        }

        // Final fallback — any visible normal-level window across all scenes
        return scenes
            .flatMap { $0.windows }
            .first(where: { !$0.isHidden && $0.windowLevel == .normal })
    }
}