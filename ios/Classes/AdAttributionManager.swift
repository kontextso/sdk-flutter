import Flutter
import Foundation
import UIKit
import AdAttributionKit

final class AdAttributionManager {
    static let shared = AdAttributionManager()
    
    private var appImpressionBox: Any?
    
    @available(iOS 17.4, *)
    private var appImpression: AppImpression? {
        get { appImpressionBox as? AppImpression }
        set { appImpressionBox = newValue }
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
}
