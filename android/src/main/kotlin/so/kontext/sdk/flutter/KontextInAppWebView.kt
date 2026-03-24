package so.kontext.sdk.flutter

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.webkit.CookieManager
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import androidx.webkit.ScriptHandler
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import org.json.JSONObject

private const val CHANNEL_PREFIX = "kontext_flutter_sdk/in_app_webview/"
private const val BRIDGE_INTERFACE_NAME = "__kontextNativeBridge"
private const val PLATFORM_READY_SCRIPT = """
    (function() {
      if ((window.top == null || window.top === window) &&
          window.flutter_inappwebview != null &&
          window.flutter_inappwebview._platformReady == null) {
        window.dispatchEvent(new Event('flutterInAppWebViewPlatformReady'));
        window.flutter_inappwebview._platformReady = true;
      }
    })();
"""

@SuppressLint("SetJavaScriptEnabled")
internal class KontextInAppWebView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    creationParams: Map<String, Any?>?,
) : PlatformView, MethodChannel.MethodCallHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private val channel = MethodChannel(messenger, "$CHANNEL_PREFIX$viewId")
    private val webView = WebView(context)

    private val initialUrl = readInitialUrl(creationParams)
    private val settings = readSettings(creationParams)
    private val initialUserScripts = readUserScripts(creationParams)

    private val bypassMainFrameLoads = mutableSetOf<String>()
    private val documentStartHandlers = mutableListOf<ScriptHandler>()
    private val documentStartSupported = WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)

    private val bridgeScript = """
        (function() {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            return;
          }
          window.flutter_inappwebview = window.flutter_inappwebview || {};
          window.flutter_inappwebview.callHandler = function(handlerName) {
            var args = Array.prototype.slice.call(arguments, 1);
            window.$BRIDGE_INTERFACE_NAME.postMessage(JSON.stringify({
              handlerName: handlerName,
              args: JSON.stringify(args)
            }));
          };
        })();
    """.trimIndent()

    init {
        channel.setMethodCallHandler(this)
        configureWebView()
        loadInitialUrl()
    }

    override fun getView(): View = webView

    override fun dispose() {
        channel.setMethodCallHandler(null)
        if (documentStartSupported) {
            documentStartHandlers.forEach { it.remove() }
            documentStartHandlers.clear()
        }
        webView.stopLoading()
        webView.removeJavascriptInterface(BRIDGE_INTERFACE_NAME)
        webView.destroy()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "evaluateJavascript" -> {
                val source = call.argument<String>("source")
                if (source == null) {
                    result.success(null)
                    return
                }
                mainHandler.post {
                    webView.evaluateJavascript(source) { value ->
                        result.success(value)
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun configureWebView() {
        webView.addJavascriptInterface(NativeBridge(), BRIDGE_INTERFACE_NAME)
        webView.layoutParams = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
        webView.setBackgroundColor(if (settings.transparentBackground) Color.TRANSPARENT else Color.WHITE)
        webView.isVerticalScrollBarEnabled = settings.verticalScrollBarEnabled
        webView.isHorizontalScrollBarEnabled = settings.horizontalScrollBarEnabled

        val cookieManager = CookieManager.getInstance()
        cookieManager.setAcceptCookie(true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            cookieManager.setAcceptThirdPartyCookies(webView, settings.sharedCookiesEnabled)
        }

        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            mediaPlaybackRequiresUserGesture = settings.mediaPlaybackRequiresUserGesture
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(false)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                mixedContentMode = when (settings.mixedContentMode) {
                    "MIXED_CONTENT_NEVER_ALLOW" -> WebSettings.MIXED_CONTENT_NEVER_ALLOW
                    "MIXED_CONTENT_COMPATIBILITY_MODE" -> WebSettings.MIXED_CONTENT_COMPATIBILITY_MODE
                    else -> WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                }
            }
        }

        if (documentStartSupported) {
            addDocumentStartScript(bridgeScript)
            initialUserScripts
                .filter { it.injectionTime == "AT_DOCUMENT_START" }
                .forEach { addDocumentStartScript(it.source) }
        }

        webView.webChromeClient = object : WebChromeClient() {
            override fun onConsoleMessage(consoleMessage: android.webkit.ConsoleMessage?): Boolean {
                if (consoleMessage != null) {
                    channel.invokeMethod(
                        "onConsoleMessage",
                        mapOf(
                            "message" to consoleMessage.message(),
                            "messageLevel" to consoleLevelName(consoleMessage.messageLevel()),
                        )
                    )
                }
                return super.onConsoleMessage(consoleMessage)
            }
        }

        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView,
                request: WebResourceRequest,
            ): Boolean {
                if (!settings.useShouldOverrideUrlLoading || !request.isForMainFrame) {
                    return false
                }
                val url = request.url?.toString() ?: return true
                if (bypassMainFrameLoads.remove(url)) {
                    return false
                }

                channel.invokeMethod(
                    "shouldOverrideUrlLoading",
                    mapOf(
                        "request" to mapOf("url" to url),
                    ),
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            if (result == "ALLOW") {
                                mainHandler.post {
                                    bypassMainFrameLoads.add(url)
                                    view.loadUrl(url)
                                }
                            }
                        }

                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        }

                        override fun notImplemented() {
                            mainHandler.post {
                                bypassMainFrameLoads.add(url)
                                view.loadUrl(url)
                            }
                        }
                    }
                )
                return true
            }

            override fun onPageStarted(view: WebView, url: String?, favicon: android.graphics.Bitmap?) {
                super.onPageStarted(view, url, favicon)
                if (!documentStartSupported) {
                    injectFallbackStartScripts()
                }
            }

            override fun onPageFinished(view: WebView, url: String?) {
                super.onPageFinished(view, url)
                initialUserScripts
                    .filter { it.injectionTime == "AT_DOCUMENT_END" }
                    .forEach { evaluateJavascript(it.source) }
                evaluateJavascript(PLATFORM_READY_SCRIPT)
            }

            override fun onReceivedError(
                view: WebView,
                request: WebResourceRequest,
                error: WebResourceError,
            ) {
                super.onReceivedError(view, request, error)
                channel.invokeMethod(
                    "onReceivedError",
                    mapOf(
                        "request" to mapOf("url" to request.url?.toString()),
                        "error" to mapOf(
                            "type" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) error.errorCode else null,
                            "description" to error.description?.toString(),
                        ),
                    )
                )
            }

            override fun onReceivedError(
                view: WebView,
                errorCode: Int,
                description: String?,
                failingUrl: String?,
            ) {
                super.onReceivedError(view, errorCode, description, failingUrl)
                channel.invokeMethod(
                    "onReceivedError",
                    mapOf(
                        "request" to mapOf("url" to failingUrl),
                        "error" to mapOf(
                            "type" to errorCode,
                            "description" to description,
                        ),
                    )
                )
            }

            override fun onReceivedHttpError(
                view: WebView,
                request: WebResourceRequest,
                errorResponse: WebResourceResponse,
            ) {
                super.onReceivedHttpError(view, request, errorResponse)
                channel.invokeMethod(
                    "onReceivedHttpError",
                    mapOf(
                        "request" to mapOf("url" to request.url?.toString()),
                        "errorResponse" to mapOf(
                            "statusCode" to errorResponse.statusCode,
                            "reasonPhrase" to errorResponse.reasonPhrase,
                        ),
                    )
                )
            }
        }
    }

    private fun loadInitialUrl() {
        if (!initialUrl.isNullOrBlank()) {
            webView.loadUrl(initialUrl)
        }
    }

    private fun addDocumentStartScript(source: String) {
        val handler = WebViewCompat.addDocumentStartJavaScript(
            webView,
            source,
            hashSetOf("*")
        )
        documentStartHandlers.add(handler)
    }

    private fun injectFallbackStartScripts() {
        evaluateJavascript(bridgeScript)
        initialUserScripts
            .filter { it.injectionTime == "AT_DOCUMENT_START" }
            .forEach { evaluateJavascript(it.source) }
    }

    private fun evaluateJavascript(source: String) {
        webView.evaluateJavascript(source, null)
    }

    private inner class NativeBridge {
        @JavascriptInterface
        fun postMessage(payload: String?) {
            if (payload.isNullOrBlank()) {
                return
            }
            val data = try {
                JSONObject(payload)
            } catch (_: Exception) {
                return
            }
            val handlerName = data.optString("handlerName")
            val argsJson = data.optString("args", "[]")

            mainHandler.post {
                channel.invokeMethod(
                    "onJavaScriptHandler",
                    mapOf(
                        "handlerName" to handlerName,
                        "args" to argsJson,
                    )
                )
            }
        }
    }
}

private data class AndroidInAppWebViewSettings(
    val transparentBackground: Boolean = false,
    val mixedContentMode: String? = null,
    val useShouldOverrideUrlLoading: Boolean = false,
    val mediaPlaybackRequiresUserGesture: Boolean = true,
    val verticalScrollBarEnabled: Boolean = true,
    val horizontalScrollBarEnabled: Boolean = true,
    val sharedCookiesEnabled: Boolean = false,
)

private data class AndroidUserScript(
    val source: String,
    val injectionTime: String,
)

private fun readInitialUrl(creationParams: Map<String, Any?>?): String? {
    val initialRequest = creationParams?.get("initialUrlRequest") as? Map<*, *>
    return initialRequest?.get("url") as? String
}

private fun readSettings(creationParams: Map<String, Any?>?): AndroidInAppWebViewSettings {
    val initialSettings = creationParams?.get("initialSettings") as? Map<*, *>
    return AndroidInAppWebViewSettings(
        transparentBackground = initialSettings?.get("transparentBackground") as? Boolean ?: false,
        mixedContentMode = initialSettings?.get("mixedContentMode") as? String,
        useShouldOverrideUrlLoading = initialSettings?.get("useShouldOverrideUrlLoading") as? Boolean ?: false,
        mediaPlaybackRequiresUserGesture = initialSettings?.get("mediaPlaybackRequiresUserGesture") as? Boolean ?: true,
        verticalScrollBarEnabled = initialSettings?.get("verticalScrollBarEnabled") as? Boolean ?: true,
        horizontalScrollBarEnabled = initialSettings?.get("horizontalScrollBarEnabled") as? Boolean ?: true,
        sharedCookiesEnabled = initialSettings?.get("sharedCookiesEnabled") as? Boolean ?: false,
    )
}

private fun readUserScripts(creationParams: Map<String, Any?>?): List<AndroidUserScript> {
    val rawScripts = creationParams?.get("initialUserScripts") as? List<*> ?: return emptyList()
    return rawScripts.mapNotNull { rawScript ->
        val script = rawScript as? Map<*, *> ?: return@mapNotNull null
        val source = script["source"] as? String ?: return@mapNotNull null
        AndroidUserScript(
            source = source,
            injectionTime = script["injectionTime"] as? String ?: "AT_DOCUMENT_START",
        )
    }
}

private fun consoleLevelName(level: android.webkit.ConsoleMessage.MessageLevel): String {
    return when (level) {
        android.webkit.ConsoleMessage.MessageLevel.ERROR -> "ERROR"
        android.webkit.ConsoleMessage.MessageLevel.WARNING -> "WARNING"
        android.webkit.ConsoleMessage.MessageLevel.DEBUG -> "DEBUG"
        android.webkit.ConsoleMessage.MessageLevel.TIP -> "TIP"
        else -> "LOG"
    }
}
