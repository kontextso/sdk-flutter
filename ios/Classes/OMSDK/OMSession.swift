import Foundation
import WebKit
@preconcurrency import OMSDK_Megabrainco

final class OMSession {
    private let session: OMIDMegabraincoAdSession
    private let webView: WKWebView
    private let adEvents: OMIDMegabraincoAdEvents

    init(session: OMIDMegabraincoAdSession, webView: WKWebView) throws {
        self.session = session
        self.webView = webView
        self.adEvents = try OMIDMegabraincoAdEvents(adSession: session)
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
