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
    private var isViewing: Bool = false
    
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
            completeOnMain(completion, false)
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
                self.completeOnMain(completion, true)
            } catch is CancellationError {
                // Task was cancelled by a subsequent initImpression call
                // Still must complete to avoid hanging the Dart future
                self.completeOnMain(completion, FlutterError(
                    code: "CANCELLED",
                    message: "initImpression was superseded by a newer call",
                    details: nil
                ))
            } catch {
                self.completeOnMain(completion, FlutterError(
                    code: "INIT_IMPRESSION_FAILED",
                    message: "Failed to initialize AppImpression: \(error)",
                    details: nil
                ))
            }
        }
    }
    
    /// Places the UIEventAttributionView over the ad in window coordinates.
    /// - Important: x/y/width/height must be in UIKit window coordinate space (points).
    ///   On the Flutter side, obtain these via RenderBox.localToGlobal(Offset.zero)
    ///   and convert to global screen coordinates before passing here.
    /// - Pass zero width/height to remove the attribution view.
    func setAttributionFrame(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, completion: @escaping (Any) -> Void) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.setAttributionFrame(x: x, y: y, width: width, height: height, completion: completion)
            }
            return
        }

        guard #available(iOS 17.4, *) else {
            completeOnMain(completion, false)
            return
        }
        
        guard width > 0, height > 0 else {
            attributionView?.removeFromSuperview()
            attributionView = nil
            hostWindow = nil
            completeOnMain(completion, true)
            return
        }
        
        guard let window = currentKeyWindow() else {
            completeOnMain(completion, FlutterError(code: "NO_KEY_WINDOW", message: "No key window found", details: nil))
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
        completeOnMain(completion, true)
    }
    
    /// - Important: Must be called immediately on tap. Delaying this call
    ///   after layout changes may cause Apple's click validation to fail.
    func handleTap(url: String?, completion: @escaping (Any) -> Void) {
        guard #available(iOS 17.4, *) else {
            completeOnMain(completion, false)
            return
        }

        if let urlString = url, !urlString.isEmpty {
            guard let impression = appImpression else {
                completeOnMain(completion, FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
                return
            }
            guard #available(iOS 18.0, *) else {
                completeOnMain(completion, FlutterError(code: "UNSUPPORTED_IOS_VERSION", message: "Handling reengagement URL requires iOS 18.0 or later", details: nil))
                return
            }
            guard let reengagementURL = URL(string: urlString) else {
                completeOnMain(completion, FlutterError(code: "INVALID_URL", message: "Provided URL is invalid", details: nil))
                return
            }

            Task { @MainActor in
                do {
                    try await impression.handleTap(reengagementURL: reengagementURL)
                    self.completeOnMain(completion, true)
                } catch {
                    self.completeOnMain(completion, FlutterError(code: "HANDLE_TAP_FAILED", message: "Failed to handle tap with URL: \(error)", details: nil))
                }
            }
            return
        }

        guard let impression = appImpression else {
            completeOnMain(completion, FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
            return
        }

        guard attributionViewBox != nil else {
            completeOnMain(completion, FlutterError(
                code: "NO_ATTRIBUTION_VIEW",
                message: "UIEventAttributionView not set. Call setAttributionFrame before handleTap.",
                details: nil
            ))
            return
        }

        Task { @MainActor in
            do {
                try await impression.handleTap()
                self.completeOnMain(completion, true)
            } catch {
                self.completeOnMain(completion, FlutterError(code: "HANDLE_TAP_FAILED", message: "Failed to handle tap: \(error)", details: nil))
            }
        }
    }

    func beginView(completion: @escaping (Any) -> Void) {
        guard #available(iOS 17.4, *) else {
            completeOnMain(completion, false)
            return
        }
        guard let impression = appImpression else {
            completeOnMain(completion, FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
            return
        }

        guard !isViewing else {
            // Already viewing — ignore duplicate call
            completeOnMain(completion, true)
            return
        }

        isViewing = true

        Task { @MainActor in
            do {
                try await impression.beginView()
                self.completeOnMain(completion, true)
            } catch {
                self.isViewing = false
                self.completeOnMain(completion, FlutterError(code: "BEGIN_VIEW_FAILED", message: "Failed to begin view: \(error)", details: nil))
            }
        }
    }

    func endView(completion: @escaping (Any) -> Void) {
        guard #available(iOS 17.4, *) else {
            completeOnMain(completion, false)
            return
        }
        guard let impression = appImpression else {
            completeOnMain(completion, FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
            return
        }

        guard isViewing else {
            // Not currently viewing — ignore unmatched endView
            completeOnMain(completion, true)
            return
        }

        isViewing = false
        Task { @MainActor in
            do {
                try await impression.endView()
                self.completeOnMain(completion, true)
            } catch {
                self.isViewing = true
                self.completeOnMain(completion, FlutterError(code: "END_VIEW_FAILED", message: "Failed to end view: \(error)", details: nil))
            }
        }
    }

    func dispose(completion: @escaping (Any) -> Void) {
        initTask?.cancel()
        initTask = nil

        // Best-effort endView if a view session is still active
        if #available(iOS 17.4, *), isViewing, let impression = appImpression {
            isViewing = false
            Task { @MainActor in
                try? await impression.endView()
            }
        } else {
            isViewing = false
        }

        let uiCleanup = {
            if #available(iOS 17.4, *) {
                self.attributionView?.removeFromSuperview()
                self.attributionView = nil
            }
            self.appImpressionBox = nil
            self.hostWindow = nil
            self.completeOnMain(completion, true)  // add self. here
        }

        if Thread.isMainThread {
            uiCleanup()
        } else {
            DispatchQueue.main.async { uiCleanup() }
        }
    }

    private func completeOnMain(_ completion: @escaping (Any) -> Void, _ value: Any) {
        if Thread.isMainThread {
            completion(value)
        } else {
            DispatchQueue.main.async { completion(value) }
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