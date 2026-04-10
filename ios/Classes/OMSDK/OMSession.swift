import Foundation
import WebKit
@preconcurrency import OMSDK_Kontextso

final class OMSession {
    private let session: OMIDKontextsoAdSession
    private let webView: WKWebView
    private let adEvents: OMIDKontextsoAdEvents

    init(session: OMIDKontextsoAdSession, webView: WKWebView) throws {
        self.session = session
        self.webView = webView
        self.adEvents = try OMIDKontextsoAdEvents(adSession: session)
    }

    func start() {
        session.start()
    }

    func retire() {
        webView.evaluateJavaScript(
            "window.postMessage({ type: 'retire-iframe' }, '*');",
            completionHandler: nil
        )
    }

    func finish() {
        session.finish()
    }

    func logError(errorType: String?, message: String?) {
        let omErrorType: OMIDErrorType = errorType == "video" ? .media : .generic
        session.logError(withType: omErrorType, message: message ?? "unknown")
    }
}
