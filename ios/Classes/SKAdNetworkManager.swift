import Flutter
import Foundation
import StoreKit

final class SKAdNetworkManager {
    static let shared = SKAdNetworkManager()
    private init() {}

    private var skImpressionBox: Any?
    private var isStarted: Bool = false

    @available(iOS 14.5, *)
    private var skImpression: SKAdImpression? {
        get { skImpressionBox as? SKAdImpression }
        set { skImpressionBox = newValue }
    }

    /// Required keys:
    ///  - version: String
    ///  - network: String              (adNetworkIdentifier)
    ///  - itunesItem: String/Int       (advertisedAppStoreItemIdentifier)
    ///  - sourceApp: String/Int        (sourceAppStoreItemIdentifier, 0 if no App Store ID)
    /// Optional keys:
    ///  - sourceIdentifier: String/Int (SKAdNetwork 4.0, iOS 16.1+)
    ///  - campaign: String/Int         (adCampaignIdentifier)
    ///  - fidelities: Array  (iOS 16.1+; each entry may contain nonce, timestamp, signature)
    ///  - nonce: String                (adImpressionIdentifier; required if no fidelities)
    ///  - timestamp: String/Int        (required if no fidelities)
    ///  - signature: String            (required if no fidelities)
    func initImpression(params: [String: Any], completion: @escaping (Any) -> Void) {
        guard #available(iOS 14.5, *) else {
            completeOnMain(completion, false)
            return
        }

        func num(_ any: Any?) -> NSNumber? {
            if let n = any as? NSNumber { return n }
            if let i = any as? Int      { return NSNumber(value: i) }
            if let d = any as? Double   { return NSNumber(value: d) }
            if let s = any as? String, let i = Int(s) { return NSNumber(value: i) }
            return nil
        }

        // Required
        let version    = params["version"] as? String
        let networkId  = params["network"] as? String
        let itunesItem = num(params["itunesItem"])
        let sourceApp  = num(params["sourceApp"]) ?? NSNumber(value: 0)

        // Optional
        let campaign         = num(params["campaign"])
        let sourceIdentifier = num(params["sourceIdentifier"])
        let nonce            = params["nonce"] as? String
        let timestamp        = num(params["timestamp"])
        let signature        = params["signature"] as? String
        let fidelities       = params["fidelities"] as? [[String: Any]]

        // nonce/timestamp/signature are required only when no fidelities provided
        let hasFidelities: Bool = {
            if #available(iOS 16.1, *) {
                return !(fidelities?.isEmpty ?? true)
            }
            return false
        }()

        var missing: [String] = []
        if version?.isEmpty != false   { missing.append("version") }
        if networkId?.isEmpty != false  { missing.append("network") }
        if itunesItem == nil           { missing.append("itunesItem") }
        if !hasFidelities {
            if nonce?.isEmpty != false     { missing.append("nonce") }
            if timestamp == nil            { missing.append("timestamp") }
            if signature?.isEmpty != false { missing.append("signature") }
        }

        guard missing.isEmpty else {
            completeOnMain(completion, FlutterError(
                code: "MISSING_ARGUMENTS",
                message: "Missing required arguments: \(missing.joined(separator: ", "))",
                details: ["provided_keys": Array(params.keys)]
            ))
            return
        }

        // Best-effort end previous impression if still active
        if isStarted, let old = skImpression {
            isStarted = false
            SKAdNetwork.endImpression(old) { _ in }
        }

        if #available(iOS 16.1, *) {
            let imp = SKAdImpression(
                sourceAppStoreItemIdentifier: sourceApp,
                advertisedAppStoreItemIdentifier: itunesItem!,
                adNetworkIdentifier: networkId!,
                adCampaignIdentifier: campaign ?? NSNumber(value: 0),
                adImpressionIdentifier: nonce ?? "",
                timestamp: timestamp ?? NSNumber(value: 0),
                signature: signature ?? "",
                version: version!
            )

            // SKAdNetwork 4.0 — fine-grained source identifier
            if let sourceIdentifier = sourceIdentifier {
                imp.sourceIdentifier = sourceIdentifier
            }

            // Fidelities — view-through (0) vs click-through (1)
            if hasFidelities, let fidelities = fidelities {
                parseFidelities(fidelities, into: imp)
            }

            skImpression = imp

        } else if #available(iOS 16.0, *) {
            // Memberwise initializer available from iOS 16, but no fidelities/sourceIdentifier
            skImpression = SKAdImpression(
                sourceAppStoreItemIdentifier: sourceApp,
                advertisedAppStoreItemIdentifier: itunesItem!,
                adNetworkIdentifier: networkId!,
                adCampaignIdentifier: campaign ?? NSNumber(value: 0),
                adImpressionIdentifier: nonce ?? "",
                timestamp: timestamp ?? NSNumber(value: 0),
                signature: signature ?? "",
                version: version!
            )

        } else {
            // iOS 14.5–15.x: property-based init
            let imp = SKAdImpression()
            imp.sourceAppStoreItemIdentifier     = sourceApp
            imp.advertisedAppStoreItemIdentifier = itunesItem!
            imp.adNetworkIdentifier              = networkId!
            imp.adCampaignIdentifier             = campaign ?? NSNumber(value: 0)
            imp.adImpressionIdentifier           = nonce ?? ""
            imp.timestamp                        = timestamp ?? NSNumber(value: 0)
            imp.signature                        = signature ?? ""
            imp.version                          = version!
            skImpression = imp
        }

        completeOnMain(completion, true)
    }

    func startImpression(completion: @escaping (Any) -> Void) {
        guard #available(iOS 14.5, *) else {
            completeOnMain(completion, false)
            return
        }
        guard let impression = skImpression else {
            completeOnMain(completion, FlutterError(
                code: "NO_IMPRESSION",
                message: "SKAdImpression not initialized",
                details: nil
            ))
            return
        }
        guard !isStarted else {
            // Already started — ignore duplicate call
            completeOnMain(completion, true)
            return
        }

        isStarted = true
        SKAdNetwork.startImpression(impression) { [weak self] error in
            if let error = error {
                self?.isStarted = false
                self?.completeOnMain(completion, FlutterError(
                    code: "SKAN_START_IMPRESSION_FAILED",
                    message: "Failed to start SKAdImpression: \(error)",
                    details: nil
                ))
            } else {
                self?.completeOnMain(completion, true)
            }
        }
    }

    func endImpression(completion: @escaping (Any) -> Void) {
        guard #available(iOS 14.5, *) else {
            completeOnMain(completion, false)
            return
        }
        guard let impression = skImpression else {
            completeOnMain(completion, FlutterError(
                code: "NO_IMPRESSION",
                message: "SKAdImpression not initialized",
                details: nil
            ))
            return
        }
        guard isStarted else {
            // Not started — ignore unmatched endImpression
            completeOnMain(completion, true)
            return
        }

        isStarted = false
        SKAdNetwork.endImpression(impression) { [weak self] error in
            if let error = error {
                self?.isStarted = true // roll back — end failed
                self?.completeOnMain(completion, FlutterError(
                    code: "SKAN_END_IMPRESSION_FAILED",
                    message: "Failed to end SKAdImpression: \(error)",
                    details: nil
                ))
            } else {
                self?.completeOnMain(completion, true)
            }
        }
    }

    func dispose(completion: @escaping (Any) -> Void) {
        // Best-effort end if still active
        if #available(iOS 14.5, *), isStarted, let impression = skImpression {
            isStarted = false
            SKAdNetwork.endImpression(impression) { _ in }
        } else {
            isStarted = false
        }

        skImpressionBox = nil
        completeOnMain(completion, true)
    }

    // MARK: - Private

    /// Fills nonce/timestamp/signature on the impression from fidelity entries,
    /// only if those fields weren't already set at the top level.    
    @available(iOS 14.5, *)
    private func parseFidelities(_ fidelities: [[String: Any]], into imp: SKAdImpression) {
        for f in fidelities {
            if imp.adImpressionIdentifier.isEmpty, let nonce = f["nonce"] as? String {
                imp.adImpressionIdentifier = nonce
            }
            if imp.timestamp == NSNumber(value: 0) {
                if let n = f["timestamp"] as? NSNumber { imp.timestamp = n }
                else if let s = f["timestamp"] as? String, let i = Int(s) { imp.timestamp = NSNumber(value: i) }
            }
            if imp.signature.isEmpty, let sig = f["signature"] as? String {
                imp.signature = sig
            }
        }
    }

    private func completeOnMain(_ completion: @escaping (Any) -> Void, _ value: Any) {
        if Thread.isMainThread {
            completion(value)
        } else {
            DispatchQueue.main.async { completion(value) }
        }
    }
}