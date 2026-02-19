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
            if let d = any as? Double {
                guard d == d.rounded() else { return nil }
                return NSNumber(value: Int(d))
            }
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

        let hasFidelities: Bool = {
            if #available(iOS 16.1, *) {
                return !(fidelities?.isEmpty ?? true)
            }
            return false
        }()

        // Validate that required strings are non-empty after trimming whitespace
        func isBlank(_ s: String?) -> Bool {
            return s?.trimmingCharacters(in: .whitespaces).isEmpty ?? true
        }

        var missing: [String] = []
        if isBlank(version)   { missing.append("version") }
        if isBlank(networkId) { missing.append("network") }
        if itunesItem == nil  { missing.append("itunesItem") }
        if !hasFidelities {
            if isBlank(nonce)     { missing.append("nonce") }
            if timestamp == nil   { missing.append("timestamp") }
            if isBlank(signature) { missing.append("signature") }
        }

        // When fidelities were provided but ignored due to OS version,
        // include a clear hint in the error so the caller understands why the
        // top-level nonce/timestamp/signature are still being required.
        guard missing.isEmpty else {
            let hint: String? = (fidelities != nil && !hasFidelities)
                ? "Note: fidelities array was provided but is only supported on iOS 16.1+. " +
                "Top-level nonce/timestamp/signature are required on this OS version."
                : nil

            completeOnMain(completion, FlutterError(
                code: "MISSING_ARGUMENTS",
                message: "Missing required arguments: \(missing.joined(separator: ", "))" +
                        (hint.map { " \($0)" } ?? ""),
                details: ["provided_keys": Array(params.keys)]
            ))
            return
        }

        let previousImpression = isStarted ? skImpression : nil
        isStarted = false

        // Collapsed the iOS 16.1 and iOS 16.0 branches into one, since they
        // called the identical memberwise initializer. The 4.0-specific extras
        // (sourceIdentifier, fidelities) are applied conditionally inside the same branch,
        // making the version boundaries explicit and removing the duplicated init call.
        if #available(iOS 16.0, *) {
            let imp = SKAdImpression(
                sourceAppStoreItemIdentifier: sourceApp,
                advertisedAppStoreItemIdentifier: itunesItem!,
                adNetworkIdentifier: networkId!,
                // Comment clarifying that on SKAN 4.0 this field is vestigial, 
                // sourceIdentifier replaces it. We still populate it for API completeness
                // and backwards compatibility with older postback versions.
                adCampaignIdentifier: campaign ?? NSNumber(value: 0),
                adImpressionIdentifier: nonce ?? "",
                timestamp: timestamp ?? NSNumber(value: 0),
                signature: signature ?? "",
                version: version!
            )

            if #available(iOS 16.1, *) {
                // SKAN 4.0: hierarchical source identifier replaces adCampaignIdentifier
                if let sourceIdentifier = sourceIdentifier {
                    imp.sourceIdentifier = sourceIdentifier
                }
                // SKAN 2.2 fidelity-type: 0 = view-through, 1 = StoreKit-rendered
                if hasFidelities, let fidelities = fidelities {
                    parseFidelities(fidelities, into: imp)
                }
            }

            skImpression = imp

        } else {
            // iOS 14.5–15.x: memberwise initializer not available, use property-based init
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

    /// Fills nonce/timestamp/signature on the impression from fidelity entries,
    /// only if those fields weren't already set at the top level.    
    @available(iOS 16.1, *)
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