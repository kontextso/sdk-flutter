import Foundation
import StoreKit
import Flutter
import UIKit

final class SKOverlayManager {
    static let shared = SKOverlayManager()
    
    private weak var channel: FlutterMethodChannel?
    
    func attach(channel: FlutterMethodChannel) {
        self.channel = channel
    }
    
    func present(appStoreId: String, position: String, dismissible: Bool, completion: @escaping (Any) -> Void) {
        // SKOverlay requires iOS 14; scene APIs require iOS 13
        guard #available(iOS 14.0, *), #available(iOS 13.0, *) else { return }
        
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
        else {
            completion(FlutterError(code: "NO_ACTIVE_SCENE", message: "No active UIWindowScene found", details: nil))
            return
        }
        
        dismiss()
        
        let pos: SKOverlay.Position = (position.lowercased() == "bottomraised") ? .bottomRaised : .bottom
        
        let config = SKOverlay.AppConfiguration(
            appIdentifier: appStoreId,
            position: pos
        )
        config.userDismissible = dismissible
        let overlay = SKOverlay(configuration: config)
        overlay.present(in: scene)
        completion(true)
    }
    
    func dismiss() -> Bool {
        guard #available(iOS 14.0, *), #available(iOS 13.0, *) else { return false }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive })
        else { return false }
        
        SKOverlay.dismiss(in: scene)
        return true
    }
}
