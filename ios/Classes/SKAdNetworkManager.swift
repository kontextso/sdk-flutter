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
    /// Attribution (resolved from the top-level keys, else the fidelity-0 entry):
    ///  - nonce: String                (adImpressionIdentifier)
    ///  - timestamp: String/Int
    ///  - signature: String
    /// Optional keys:
    ///  - sourceApp: String/Int        (sourceAppStoreItemIdentifier; defaults to 0 — "no App Store ID known")
    ///  - campaign: String/Int         (adCampaignIdentifier; defaults to 0)
    ///  - sourceIdentifier: String/Int (SKAdNetwork 4.0, iOS 16.1+)
    ///  - fidelities: Array            (fidelity-0 entry fills missing top-level nonce/timestamp/signature)
    func initImpression(params: [String: Any], completion: @escaping (Any) -> Void) {
        guard #available(iOS 14.5, *) else {
            completeOnMain(completion, false)
            return
        }

        func num(_ any: Any?) -> NSNumber? {
            if let n = any as? NSNumber { return n }
            if let i = any as? Int      { return NSNumber(value: i) }
            if let d = any as? Double {
                guard d == d.rounded() else { return nil }
                return NSNumber(value: Int(d))
            }
            if let s = any as? String, let i = Int(s) { return NSNumber(value: i) }
            return nil
        }

        // Identity
        let version    = params["version"] as? String
        let networkId  = params["network"] as? String
        let itunesItem = num(params["itunesItem"])
        let sourceApp  = num(params["sourceApp"]) ?? NSNumber(value: 0)

        // Optional
        let campaign         = num(params["campaign"])
        let sourceIdentifier = num(params["sourceIdentifier"])

        // Attribution: prefer top-level fields, fall back to the fidelity-0 entry.
        // (No fallback to fidelity-1 — those values are signed with a different formula.)
        let f0 = Self.fidelity0Values(from: params)
        let nonce     = (params["nonce"] as? String)     ?? f0?.nonce
        let timestamp = num(params["timestamp"])         ?? f0?.timestamp
        let signature = (params["signature"] as? String) ?? f0?.signature

        // Validate that required strings are non-empty after trimming whitespace
        func isBlank(_ s: String?) -> Bool {
            return s?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
        }

        var missing: [String] = []
        if isBlank(version)   { missing.append("version") }
        if isBlank(networkId) { missing.append("network") }
        if itunesItem == nil  { missing.append("itunesItem") }
        if isBlank(nonce)     { missing.append("nonce") }
        if timestamp == nil   { missing.append("timestamp") }
        if isBlank(signature) { missing.append("signature") }

        guard missing.isEmpty,
              let version = version,
              let networkId = networkId,
              let itunesItem = itunesItem,
              let nonce = nonce,
              let timestamp = timestamp,
              let signature = signature
        else {
            completeOnMain(completion, FlutterError(
                code: "MISSING_ARGUMENTS",
                message: "Missing required arguments: \(missing.joined(separator: ", "))",
                details: ["provided_keys": Array(params.keys)]
            ))
            return
        }

        let previousImpression = isStarted ? skImpression : nil
        isStarted = false

        // The 16.0 memberwise initializer and the pre-16.0 property setters build
        // the identical impression; sourceIdentifier (SKAN 4.0) is applied only on 16.1+.
        if #available(iOS 16.0, *) {
            let imp = SKAdImpression(
                sourceAppStoreItemIdentifier: sourceApp,
                advertisedAppStoreItemIdentifier: itunesItem,
                adNetworkIdentifier: networkId,
                // Vestigial on SKAN 4.0 (sourceIdentifier replaces it); still populated
                // for API completeness and older postback versions.
                adCampaignIdentifier: campaign ?? NSNumber(value: 0),
                adImpressionIdentifier: nonce,
                timestamp: timestamp,
                signature: signature,
                version: version
            )
            if #available(iOS 16.1, *), let sourceIdentifier = sourceIdentifier {
                imp.sourceIdentifier = sourceIdentifier
            }
            skImpression = imp
        } else {
            let imp = SKAdImpression()
            imp.sourceAppStoreItemIdentifier     = sourceApp
            imp.advertisedAppStoreItemIdentifier = itunesItem
            imp.adNetworkIdentifier              = networkId
            imp.adCampaignIdentifier             = campaign ?? NSNumber(value: 0)
            imp.adImpressionIdentifier           = nonce
            imp.timestamp                        = timestamp
            imp.signature                        = signature
            imp.version                          = version
            skImpression = imp
        }

        // End the previous impression only after the new one is safely stored.
        // Failure here is best-effort — we log it but don't block the caller,
        // since the new impression is already in place and ready to use.
        if let old = previousImpression {
            SKAdNetwork.endImpression(old) { error in
                if let error = error {
                    print("[SKAdNetwork] Warning: failed to end previous impression: \(error)")
                }
            }
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

    /// Resolves nonce/timestamp/signature from the fidelity-0 (view-through) entry.
    /// Returns nil if there is no valid fidelity-0 entry — no fallback to fidelity-1,
    /// whose values are signed with a different formula.
    private static func fidelity0Values(from params: [String: Any]) -> (nonce: String, timestamp: NSNumber, signature: String)? {
        guard let fidelities = params["fidelities"] as? [[String: Any]],
              let f0 = fidelities.first(where: { ($0["fidelity"] as? Int) == 0 }),
              let nonce = f0["nonce"] as? String, !nonce.isEmpty,
              let signature = f0["signature"] as? String, !signature.isEmpty
        else { return nil }

        let timestamp: NSNumber
        if let n = f0["timestamp"] as? NSNumber { timestamp = n }
        else if let s = f0["timestamp"] as? String, let i = Int(s) { timestamp = NSNumber(value: i) }
        else { return nil }

        return (nonce, timestamp, signature)
    }

    private func completeOnMain(_ completion: @escaping (Any) -> Void, _ value: Any) {
        if Thread.isMainThread {
            completion(value)
        } else {
            DispatchQueue.main.async { completion(value) }
        }
    }
}
