import Foundation
import WebKit
@preconcurrency import OMSDK_Megabrainco

enum OMCreativeType: String {
    case display
    case video
}

protocol OMManaging: AnyObject {
    @discardableResult
    func activate() -> Bool

    func createSession(
        _ webView: WKWebView,
        url: URL?,
        creativeType: OMCreativeType
    ) throws -> OMSession
}

final class OMManager: OMManaging {
    enum OMError: Error {
        case sdkIsNotActive
        case partnerIsNotAvailable
        case sessionCreationFailed(String)
    }

    static let shared = OMManager()

    private init() {}

    private let partner = OMIDMegabraincoPartner(
        name: OMConstants.partnerName,
        versionString: OMConstants.integrationVersion
    )

    @discardableResult
    func activate() -> Bool {
        if isActive {
            return true
        }

        OMIDMegabraincoSDK.shared.activate()
        return isActive
    }

    func createSession(
        _ webView: WKWebView,
        url: URL?,
        creativeType: OMCreativeType
    ) throws -> OMSession {
        guard isActive else {
            throw OMError.sdkIsNotActive
        }

        guard let partner else {
            throw OMError.partnerIsNotAvailable
        }

        do {
            let context = try OMIDMegabraincoAdSessionContext(
                partner: partner,
                webView: webView,
                contentUrl: url?.absoluteString,
                customReferenceIdentifier: nil
            )

            let omCreativeType: OMIDCreativeType
            let impressionOwner: OMIDOwner
            let mediaEventsOwner: OMIDOwner

            switch creativeType {
            case .display:
                omCreativeType = .htmlDisplay
                impressionOwner = .javaScriptOwner
                mediaEventsOwner = .noneOwner
            case .video:
                omCreativeType = .video
                impressionOwner = .javaScriptOwner
                mediaEventsOwner = .javaScriptOwner
            }

            let configuration = try OMIDMegabraincoAdSessionConfiguration(
                creativeType: omCreativeType,
                impressionType: .beginToRender,
                impressionOwner: impressionOwner,
                mediaEventsOwner: mediaEventsOwner,
                isolateVerificationScripts: false
            )

            let session = try OMIDMegabraincoAdSession(
                configuration: configuration,
                adSessionContext: context
            )
            session.mainAdView = webView

            return try OMSession(session: session, webView: webView)
        } catch {
            throw OMError.sessionCreationFailed(error.localizedDescription)
        }
    }
}

private extension OMManager {
    var isActive: Bool {
        OMIDMegabraincoSDK.shared.isActive
    }
}
