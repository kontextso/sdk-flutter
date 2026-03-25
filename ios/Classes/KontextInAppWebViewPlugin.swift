import Flutter
import Foundation
import WebKit

private let kontextInAppWebViewType = "kontext_flutter_sdk/in_app_webview"
private let kontextInAppWebViewChannelPrefix = "kontext_flutter_sdk/in_app_webview/"
private let kontextNativeBridgeName = "__kontextNativeBridge"
private let kontextConsoleBridgeName = "__kontextConsoleBridge"
private let kontextPlatformReadyScript = """
(function() {
  if ((window.top == null || window.top === window) &&
      window.flutter_inappwebview != null &&
      window.flutter_inappwebview._platformReady == null) {
    window.dispatchEvent(new Event('flutterInAppWebViewPlatformReady'));
    window.flutter_inappwebview._platformReady = true;
  }
})();
"""

final class KontextInAppWebViewPlugin: NSObject {
    static func register(with registrar: FlutterPluginRegistrar) {
        let factory = KontextInAppWebViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: kontextInAppWebViewType)
    }
}

final class KontextInAppWebViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        let creationParams = args as? [String: Any]
        return KontextInAppWebViewPlatformView(
            frame: frame,
            viewId: viewId,
            messenger: messenger,
            creationParams: creationParams
        )
    }
}

final class KontextInAppWebViewPlatformView: NSObject, FlutterPlatformView, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    private let channel: FlutterMethodChannel
    private let webView: WKWebView
    private let settings: IOSInAppWebViewSettings
    private let omService: OMManaging
    private var hasLoadedInitialUrl = false
    private var isInitialCookieSeedingComplete: Bool
    private var hasPendingInitialLoad = false
    private let initialUrl: URL?
    private var omCreativeType: OMCreativeType?
    private var hasLoadedPage = false
    private var pendingOpenMeasurementStart = false
    private var activeOMSession: OMSession?
    private var lastContentURL: URL?

    init(
        frame: CGRect,
        viewId: Int64,
        messenger: FlutterBinaryMessenger,
        creationParams: [String: Any]?
    ) {
        self.settings = IOSInAppWebViewSettings(creationParams: creationParams)
        self.omService = OMManager.shared
        if let urlString = ((creationParams?["initialUrlRequest"] as? [String: Any])?["url"] as? String) {
            self.initialUrl = URL(string: urlString)
        } else {
            self.initialUrl = nil
        }
        if let creativeType = creationParams?["initialOmCreativeType"] as? String {
            self.omCreativeType = OMCreativeType(rawValue: creativeType)
        } else {
            self.omCreativeType = nil
        }
        let initialCookiesToSeed: [HTTPCookie]
        if #available(iOS 11.0, *), self.settings.sharedCookiesEnabled {
            initialCookiesToSeed = HTTPCookieStorage.shared.cookies ?? []
        } else {
            initialCookiesToSeed = []
        }
        self.isInitialCookieSeedingComplete = initialCookiesToSeed.isEmpty

        let userContentController = WKUserContentController()
        let bridgeScript = KontextInAppWebViewPlatformView.makeBridgeScript()
        userContentController.addUserScript(
            WKUserScript(
                source: bridgeScript,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )
        if let omsdkJS = KontextInAppWebViewPlatformView.loadOpenMeasurementJavaScript() {
            userContentController.addUserScript(
                WKUserScript(
                    source: omsdkJS,
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: true
                )
            )
        }
        userContentController.addUserScript(
            WKUserScript(
                source: KontextInAppWebViewPlatformView.makeConsoleShimScript(),
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
        )

        let initialUserScripts = (creationParams?["initialUserScripts"] as? [[String: Any]]) ?? []
        for script in initialUserScripts {
            guard let source = script["source"] as? String else { continue }
            let injectionTime: WKUserScriptInjectionTime =
                (script["injectionTime"] as? String) == "AT_DOCUMENT_END" ? .atDocumentEnd : .atDocumentStart
            let forMainFrameOnly = script["forMainFrameOnly"] as? Bool ?? true
            userContentController.addUserScript(
                WKUserScript(
                    source: source,
                    injectionTime: injectionTime,
                    forMainFrameOnly: forMainFrameOnly
                )
            )
        }

        let configuration = WKWebViewConfiguration()
        configuration.userContentController = userContentController
        configuration.allowsInlineMediaPlayback = self.settings.allowsInlineMediaPlayback
        configuration.websiteDataStore = .default()
        if #available(iOS 10.0, *) {
            configuration.mediaTypesRequiringUserActionForPlayback =
                self.settings.mediaPlaybackRequiresUserGesture ? .all : []
        }
        if #available(iOS 14.0, *) {
            configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        } else {
            configuration.preferences.javaScriptEnabled = true
        }

        self.webView = WKWebView(frame: frame, configuration: configuration)
        self.channel = FlutterMethodChannel(
            name: "\(kontextInAppWebViewChannelPrefix)\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        userContentController.add(self, name: kontextNativeBridgeName)
        userContentController.add(self, name: kontextConsoleBridgeName)

        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.isOpaque = !settings.transparentBackground
        webView.backgroundColor = settings.transparentBackground ? .clear : .white
        webView.scrollView.backgroundColor = settings.transparentBackground ? .clear : .white
        webView.scrollView.showsVerticalScrollIndicator = settings.verticalScrollBarEnabled
        webView.scrollView.showsHorizontalScrollIndicator = settings.horizontalScrollBarEnabled

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        if #available(iOS 11.0, *), !initialCookiesToSeed.isEmpty {
            seedInitialCookies(initialCookiesToSeed)
        }
    }

    deinit {
        finishOpenMeasurementSession()
        webView.configuration.userContentController.removeScriptMessageHandler(forName: kontextNativeBridgeName)
        webView.configuration.userContentController.removeScriptMessageHandler(forName: kontextConsoleBridgeName)
        channel.setMethodCallHandler(nil)
    }

    func view() -> UIView {
        webView
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "evaluateJavascript":
            let args = call.arguments as? [String: Any]
            let source = args?["source"] as? String
            webView.evaluateJavaScript(source ?? "") { value, error in
                if let error {
                    result(FlutterError(code: "evaluate_javascript_failed", message: error.localizedDescription, details: nil))
                } else {
                    result(value)
                }
            }
        case "loadInitialUrl":
            loadInitialUrl()
            result(nil)
        case "configureOpenMeasurement":
            let args = call.arguments as? [String: Any]
            if let creativeType = args?["creativeType"] as? String {
                configureOpenMeasurement(creativeType: creativeType)
            } else {
                omCreativeType = nil
            }
            result(nil)
        case "startOpenMeasurementSession":
            startOpenMeasurementSession()
            result(nil)
        case "logOpenMeasurementError":
            let args = call.arguments as? [String: Any]
            logOpenMeasurementError(
                errorType: args?["errorType"] as? String,
                message: args?["message"] as? String
            )
            result(nil)
        case "finishOpenMeasurementSession":
            finishOpenMeasurementSession()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case kontextNativeBridgeName:
            guard let body = message.body as? [String: Any] else { return }
            let callHandlerId = body["_callHandlerID"] as? String
            channel.invokeMethod(
                "onJavaScriptHandler",
                arguments: [
                    "handlerName": body["handlerName"] as? String ?? "",
                    "args": body["args"] as? String ?? "[]",
                ]
            ) { [weak self] _ in
                self?.resolveJavaScriptCall(callHandlerId: callHandlerId)
            }
        case kontextConsoleBridgeName:
            guard let body = message.body as? [String: Any] else { return }
            channel.invokeMethod(
                "onConsoleMessage",
                arguments: [
                    "message": body["message"] as? String ?? "",
                    "messageLevel": body["messageLevel"] as? String ?? "LOG",
                ]
            )
        default:
            break
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard settings.useShouldOverrideUrlLoading else {
            decisionHandler(.allow)
            return
        }

        channel.invokeMethod(
            "shouldOverrideUrlLoading",
            arguments: [
                "isForMainFrame": navigationAction.targetFrame?.isMainFrame ?? false,
                "request": [
                    "url": urlArgument(navigationAction.request.url)
                ]
            ]
        ) { result in
            if let decision = result as? String, decision == "ALLOW" {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        if let response = navigationResponse.response as? HTTPURLResponse, response.statusCode >= 400 {
            channel.invokeMethod(
                "onReceivedHttpError",
                arguments: [
                    "request": [
                        "url": urlArgument(response.url)
                    ],
                    "errorResponse": [
                        "statusCode": response.statusCode,
                        "reasonPhrase": HTTPURLResponse.localizedString(forStatusCode: response.statusCode),
                    ]
                ]
            )
        }
        decisionHandler(.allow)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: Error
    ) {
        sendLoadError(error, failingURL: failingURL(from: error, fallbackURL: webView.url))
    }

    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: Error
    ) {
        sendLoadError(error, failingURL: failingURL(from: error, fallbackURL: webView.url))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        hasLoadedPage = true
        lastContentURL = webView.url ?? initialUrl
        webView.evaluateJavaScript(kontextPlatformReadyScript, completionHandler: nil)
        startOpenMeasurementSessionIfReady()
    }

    private func sendLoadError(_ error: Error, failingURL: URL?) {
        let nsError = error as NSError
        channel.invokeMethod(
            "onReceivedError",
            arguments: [
                "request": [
                    "url": urlArgument(failingURL)
                ],
                "error": [
                    "type": nsError.code,
                    "description": nsError.localizedDescription,
                ]
            ]
        )
    }

    private func failingURL(from error: Error, fallbackURL: URL?) -> URL? {
        let nsError = error as NSError
        if let failingURL = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            return failingURL
        }

        if let failingURLString = nsError.userInfo[NSURLErrorFailingURLStringErrorKey] as? String {
            return URL(string: failingURLString) ?? fallbackURL
        }

        return fallbackURL
    }

    private func resolveJavaScriptCall(callHandlerId: String?) {
        guard let callHandlerId, !callHandlerId.isEmpty else {
            return
        }

        let callHandlerIdLiteral = jsonStringLiteral(callHandlerId)
        webView.evaluateJavaScript(
            """
            (function() {
              if (window.flutter_inappwebview[\(callHandlerIdLiteral)] != null) {
                window.flutter_inappwebview[\(callHandlerIdLiteral)].resolve(null);
                delete window.flutter_inappwebview[\(callHandlerIdLiteral)];
              }
            })();
            """,
            completionHandler: nil
        )
    }

    private func loadInitialUrl() {
        guard isInitialCookieSeedingComplete else {
            hasPendingInitialLoad = true
            return
        }
        guard !hasLoadedInitialUrl else { return }
        hasLoadedInitialUrl = true
        hasLoadedPage = false
        lastContentURL = initialUrl

        guard let initialUrl else { return }
        webView.load(URLRequest(url: initialUrl))
    }

    @available(iOS 11.0, *)
    private func seedInitialCookies(_ cookies: [HTTPCookie]) {
        let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
        var remainingCookies = cookies.count

        for cookie in cookies {
            cookieStore.setCookie(cookie) { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }

                    remainingCookies -= 1
                    if remainingCookies == 0 {
                        self.isInitialCookieSeedingComplete = true
                        if self.hasPendingInitialLoad {
                            self.hasPendingInitialLoad = false
                            self.loadInitialUrl()
                        }
                    }
                }
            }
        }
    }

    private func jsonStringLiteral(_ value: String) -> String {
        let data = try? JSONSerialization.data(withJSONObject: [value])
        let encoded = data.flatMap { String(data: $0, encoding: .utf8) } ?? "[\"\"]"
        return String(encoded.dropFirst().dropLast())
    }

    private static func makeBridgeScript() -> String {
        """
        (function() {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            return;
          }
          window.flutter_inappwebview = window.flutter_inappwebview || {};
          window.flutter_inappwebview.callHandler = function(handlerName) {
            var _callHandlerID = setTimeout(function(){});
            var args = Array.prototype.slice.call(arguments, 1);
            window.webkit.messageHandlers.\(kontextNativeBridgeName).postMessage({
              handlerName: handlerName,
              _callHandlerID: String(_callHandlerID),
              args: JSON.stringify(args)
            });
            return new Promise(function(resolve, reject) {
              window.flutter_inappwebview[_callHandlerID] = {resolve: resolve, reject: reject};
            });
          };
        })();
        """
    }

    private static func makeConsoleShimScript() -> String {
        """
        (function() {
          if (window.__kontextConsoleBridgeReady) {
            return;
          }
          window.__kontextConsoleBridgeReady = true;
          function joinArgs(args) {
            return Array.prototype.slice.call(args).map(function(value) {
              try {
                if (typeof value === 'string') return value;
                return JSON.stringify(value);
              } catch (e) {
                return String(value);
              }
            }).join(' ');
          }
          ['log', 'info', 'warn', 'error', 'debug'].forEach(function(level) {
            var original = console[level];
            console[level] = function() {
              try {
                window.webkit.messageHandlers.\(kontextConsoleBridgeName).postMessage({
                  message: joinArgs(arguments),
                  messageLevel: level === 'warn' ? 'WARNING' : (level === 'error' ? 'ERROR' : (level === 'debug' ? 'DEBUG' : 'LOG'))
                });
              } catch (e) {}
              if (original) {
                return original.apply(console, arguments);
              }
            };
          });
        })();
        """
    }

    private func configureOpenMeasurement(creativeType: String) {
        omCreativeType = OMCreativeType(rawValue: creativeType)
        startOpenMeasurementSessionIfReady()
    }

    private func startOpenMeasurementSession() {
        pendingOpenMeasurementStart = true
        startOpenMeasurementSessionIfReady()
    }

    private func startOpenMeasurementSessionIfReady() {
        guard activeOMSession == nil else {
            return
        }

        guard pendingOpenMeasurementStart else {
            return
        }

        guard let omCreativeType else {
            return
        }

        guard hasLoadedPage else {
            return
        }

        guard omService.activate() else {
            return
        }

        do {
            let session = try omService.createSession(
                webView,
                url: lastContentURL ?? webView.url ?? initialUrl,
                creativeType: omCreativeType
            )
            session.start()
            activeOMSession = session
            pendingOpenMeasurementStart = false
        } catch OMManager.OMError.sdkIsNotActive {
            return
        } catch {
            pendingOpenMeasurementStart = false
        }
    }

    private func logOpenMeasurementError(errorType: String?, message: String?) {
        activeOMSession?.logError(errorType: errorType, message: message)
    }

    private func finishOpenMeasurementSession() {
        pendingOpenMeasurementStart = false

        guard let activeOMSession else {
            return
        }

        self.activeOMSession = nil
        activeOMSession.retire()
        activeOMSession.finish()
        OMRetentionPool.shared.retain(activeOMSession)
    }

    private static func loadOpenMeasurementJavaScript() -> String? {
        let classBundle = Bundle(for: KontextInAppWebViewPlatformView.self)
        let bundleCandidates: [Bundle] = [
            Bundle.main,
            classBundle,
            classBundle.url(forResource: "kontext_flutter_sdk", withExtension: "bundle").flatMap(Bundle.init(url:)),
            Bundle.main.url(forResource: "kontext_flutter_sdk", withExtension: "bundle").flatMap(Bundle.init(url:))
        ].compactMap { $0 }

        for bundle in bundleCandidates {
            guard let url = bundle.url(forResource: "omsdk-v1", withExtension: "js") else {
                continue
            }

            if let source = try? String(contentsOf: url, encoding: .utf8) {
                return source
            }
        }

        return nil
    }

    private func urlArgument(_ url: URL?) -> Any {
        url?.absoluteString ?? NSNull()
    }
}

private struct IOSInAppWebViewSettings {
    let transparentBackground: Bool
    let useShouldOverrideUrlLoading: Bool
    let mediaPlaybackRequiresUserGesture: Bool
    let allowsInlineMediaPlayback: Bool
    let verticalScrollBarEnabled: Bool
    let horizontalScrollBarEnabled: Bool
    let sharedCookiesEnabled: Bool

    init(creationParams: [String: Any]?) {
        let initialSettings = creationParams?["initialSettings"] as? [String: Any]
        transparentBackground = initialSettings?["transparentBackground"] as? Bool ?? false
        useShouldOverrideUrlLoading = initialSettings?["useShouldOverrideUrlLoading"] as? Bool ?? false
        mediaPlaybackRequiresUserGesture = initialSettings?["mediaPlaybackRequiresUserGesture"] as? Bool ?? true
        allowsInlineMediaPlayback = initialSettings?["allowsInlineMediaPlayback"] as? Bool ?? false
        verticalScrollBarEnabled = initialSettings?["verticalScrollBarEnabled"] as? Bool ?? true
        horizontalScrollBarEnabled = initialSettings?["horizontalScrollBarEnabled"] as? Bool ?? true
        sharedCookiesEnabled = initialSettings?["sharedCookiesEnabled"] as? Bool ?? false
    }
}
