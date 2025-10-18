import Flutter
import Foundation
import UIKit
import AdAttributionKit
import StoreKit

final class AdAttributionManager {
    static let shared = AdAttributionManager()
    
    private var appImpressionBox: Any?
    private var attributionViewBox: Any?
    private weak var hostWindow: UIWindow?
    private var skImpressionBox: Any?
    
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
    
    @available(iOS 14.5, *)
    private var skImpression: SKAdImpression? {
        get { skImpressionBox as? SKAdImpression }
        set { skImpressionBox = newValue }
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
            completion(true)
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
        if let urlString = url, !urlString.isEmpty {
            guard #available(iOS 18.0, *) else {
                completion(FlutterError(code: "UNSUPPORTED_IOS_VERSION", message: "Handling reengagement URL requires iOS 18.0 or later", details: nil))
                return
            }
            guard let impression = appImpression else {
                completion(FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
                return
            }
            guard let reengagementURL = URL(string: urlString) else {
                completion(FlutterError(code: "INVALID_URL", message: "Provided URL is invalid", details: nil))
                return
            }
            
            Task {
                do {
                    try await impression.handleTap(reengagementURL: reengagementURL)
                    completion(true)
                } catch {
                    completion(FlutterError(code: "HANDLE_TAP_FAILED", message: "Failed to handle tap with URL: \(error)", details: nil))
                }
            }
            return
        }
        
        guard #available(iOS 17.4, *) else {
            completion(false)
            return
        }
        guard let impression = appImpression else {
            completion(FlutterError(code: "NO_IMPRESSION", message: "AppImpression not initialized", details: nil))
            return
        }
        
        Task {
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
        
        Task {
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
        
        Task {
            do {
                try await impression.endView()
                completion(true)
            } catch {
                completion(FlutterError(code: "END_VIEW_FAILED", message: "Failed to end view: \(error)", details: nil))
            }
        }
    }
    
    /// Required keys:
    ///  - advertisedAppStoreItemIdentifier: Int / NSNumber
    ///  - adNetworkIdentifier: String
    ///  - adCampaignIdentifier: Int / NSNumber (0..99)
    ///  - adImpressionIdentifier: String (UUID recommended)
    ///  - timestamp: Double/Int/NSNumber (unix seconds)
    ///  - signature: String
    ///  - version: String (e.g. "4.0", "3.0", "2.2")
    /// Optional:
    ///  - sourceAppStoreItemIdentifier: Int/NSNumber (0 allowed if publisher app has no App Store ID - for testing)
    func skanInitImpression(params: [String: Any], completion: @escaping (Any) -> Void) {
        guard #available(iOS 16.0, *) else {
            completion(false)
            return
        }
        
        func num(_ any: Any?) -> NSNumber? {
            if let n = any as? NSNumber { return n }
            if let i = any as? Int { return NSNumber(value: i) }
            if let d = any as? Double { return NSNumber(value: d) }
            if let s = any as? String, let i = Int(s) { return NSNumber(value: i) }
            return nil
        }
        
        let advertised = num(params["advertisedAppStoreItemIdentifier"])
        let networkId = params["adNetworkIdentifier"] as? String
        let campaign = num(params["adCampaignIdentifier"])
        let impId = params["adImpressionIdentifier"] as? String
        let timestamp = num(params["timestamp"])
        let signature = params["signature"] as? String
        let version = params["version"] as? String
        
        let source = num(params["sourceAppStoreItemIdentifier"]) ?? NSNumber(value: 0)
        
        var missing: [String] = []
        if advertised == nil { missing.append("advertisedAppStoreItemIdentifier") }
        if networkId?.isEmpty != false { missing.append("adNetworkIdentifier") }
        if campaign == nil { missing.append("adCampaignIdentifier") }
        if impId?.isEmpty != false { missing.append("adImpressionIdentifier") }
        if timestamp == nil { missing.append("timestamp") }
        if signature?.isEmpty != false { missing.append("signature") }
        if version?.isEmpty != false { missing.append("version") }
        
        guard missing.isEmpty else {
            completion(FlutterError(code: "MISSING_ARGUMENTS", message: "Missing required arguments: \(missing.joined(separator: ", "))", details: ["provided_keys": Array(params.keys)]))
            return
        }
        
        if #available(iOS 16.0, *) {
            let imp = SKAdImpression(
                sourceAppStoreItemIdentifier: source,
                advertisedAppStoreItemIdentifier: advertised!,
                adNetworkIdentifier: networkId!,
                adCampaignIdentifier: campaign!,
                adImpressionIdentifier: impId!,
                timestamp: timestamp!,
                signature: signature!,
                version: version!
            )
            self.skImpression = imp
            completion(true)
        } else if #available(iOS 14.5, *) {
            let imp = SKAdImpression()
            imp.sourceAppStoreItemIdentifier = source
            imp.advertisedAppStoreItemIdentifier = advertised!
            imp.adNetworkIdentifier = networkId!
            imp.adCampaignIdentifier = campaign!
            imp.adImpressionIdentifier = impId!
            imp.timestamp = timestamp!
            imp.signature = signature!
            imp.version = version!
            self.skImpression = imp
            completion(true)
        } else {
            completion(false)
        }
    }
    
    func skanStartImpression(completion: @escaping (Any) -> Void) {
        guard #available(iOS 14.5, *) else {
            completion(false)
            return
        }
        
        guard let impression = skImpression else {
            completion(FlutterError(code: "NO_IMPRESSION", message: "SKAdImpression not initialized", details: nil))
            return
        }
        
        SKAdNetwork.startImpression(impression) { error in
            if let error = error {
                completion(FlutterError(code: "SKAN_START_IMPRESSION_FAILED", message: "Failed to start SKAdImpression: \(error)", details: nil))
            } else {
                completion(true)
            }
        }
    }
    
    func skanEndImpression(completion: @escaping (Any) -> Void) {
        guard #available(iOS 14.5, *) else {
            completion(false)
            return
        }
        
        guard let impression = skImpression else {
            completion(FlutterError(code: "NO_IMPRESSION", message: "SKAdImpression not initialized", details: nil))
            return
        }
        
        SKAdNetwork.endImpression(impression) { error in
            if let error = error {
                completion(FlutterError(code: "SKAN_END_IMPRESSION_FAILED", message: "Failed to end SKAdImpression: \(error)", details: nil))
            } else {
                completion(true)
            }
        }
    }
    
    func dispose(completion: @escaping (Any) -> Void) {
        appImpressionBox = nil
        hostWindow = nil
        
        let uiCleanup = { [weak self] in
            guard let self = self else { return }
            if #available(iOS 17.4, *) {
                self.attributionView?.removeFromSuperview()
                self.attributionView = nil
            }
            completion(true)
        }
        
        if Thread.isMainThread {
            uiCleanup()
        } else {
            DispatchQueue.main.async { uiCleanup() }
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
