package so.kontext.sdk.flutter

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
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
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import so.kontext.sdk.flutter.omsdk.OMConstants
import so.kontext.sdk.flutter.omsdk.OMCreativeType
import so.kontext.sdk.flutter.omsdk.WebViewOMLifecycle

private const val CHANNEL_PREFIX = "kontext_flutter_sdk/in_app_webview/"
private const val JAVASCRIPT_BRIDGE_NAME = "flutter_inappwebview"
private const val MAX_BYPASS_MAIN_FRAME_LOADS = 100
private const val PLATFORM_READY_SCRIPT = """
    (function() {
      if ((window.top == null || window.top === window) &&
          window.$JAVASCRIPT_BRIDGE_NAME != null &&
          window.$JAVASCRIPT_BRIDGE_NAME._platformReady == null) {
        window.dispatchEvent(new Event('flutterInAppWebViewPlatformReady'));
        window.$JAVASCRIPT_BRIDGE_NAME._platformReady = true;
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
    private val documentStartSupported = WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT)
    private val openMeasurementJavascript = if (documentStartSupported) {
        loadOpenMeasurementJavaScript(context)
    } else {
        null
    }
    private val omLifecycle = WebViewOMLifecycle(
        webView = webView,
        initialContentUrl = initialUrl,
        initialCreativeType = readInitialOmCreativeType(creationParams),
        canUseOpenMeasurement = ::canUseOpenMeasurement,
        logUnsupportedOpenMeasurement = ::logUnsupportedOpenMeasurement,
    )
    private val bypassMainFrameLoads = linkedSetOf<String>()

    private var hasLoadedInitialUrl = false

    private val bridgeScript = """
        (function() {
          if (window.$JAVASCRIPT_BRIDGE_NAME != null) {
            window.$JAVASCRIPT_BRIDGE_NAME.callHandler = function() {
              var _callHandlerID = setTimeout(function(){});
              window.$JAVASCRIPT_BRIDGE_NAME._callHandler(
                arguments[0],
                _callHandlerID,
                JSON.stringify(Array.prototype.slice.call(arguments, 1))
              );
              return new Promise(function(resolve, reject) {
                window.$JAVASCRIPT_BRIDGE_NAME[_callHandlerID] = {resolve: resolve, reject: reject};
              });
            };
          }
          if (window.top != null && window.top !== window && window.$JAVASCRIPT_BRIDGE_NAME == null) {
            window.$JAVASCRIPT_BRIDGE_NAME = {};
            window.$JAVASCRIPT_BRIDGE_NAME.callHandler = function() {
              var _callHandlerID = setTimeout(function(){});
              try {
                window.top.$JAVASCRIPT_BRIDGE_NAME._callHandler(
                  arguments[0],
                  _callHandlerID,
                  JSON.stringify(Array.prototype.slice.call(arguments, 1))
                );
                return new Promise(function(resolve, reject) {
                  window.top.$JAVASCRIPT_BRIDGE_NAME[_callHandlerID] = {resolve: resolve, reject: reject};
                });
              } catch (error) {
                return new Promise(function(resolve, reject) {
                  reject(error);
                });
              }
            };
          }
        })();
    """.trimIndent()

    private val posterStartScript = """
        (function() {
          if (window.__kontextVideoPosterPatched) {
            return;
          }
          window.__kontextVideoPosterPatched = true;

          const transparentPoster = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIW2NkYGBgAAAABAABJzQnCgAAAABJRU5ErkJggg==";
          const css = document.createElement('style');
          css.textContent = "video{background:#000!important;}";
          document.documentElement.appendChild(css);

          const apply = function() {
            document.querySelectorAll('video').forEach(function(video) {
              video.setAttribute('poster', transparentPoster);
              video.setAttribute('playsinline', '');
              video.setAttribute('preload', 'auto');
            });
          };

          apply();
          new MutationObserver(apply).observe(document.documentElement, { childList: true, subtree: true });
        })();
    """.trimIndent()

    init {
        channel.setMethodCallHandler(this)
        configureWebView()
    }

    override fun getView(): View = webView

    override fun dispose() {
        omLifecycle.finish()
        channel.setMethodCallHandler(null)
        webView.removeJavascriptInterface(JAVASCRIPT_BRIDGE_NAME)
        if (!omLifecycle.dispose()) {
            destroyWebViewImmediately()
        }
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
            "loadInitialUrl" -> {
                mainHandler.post {
                    loadInitialUrl()
                    result.success(null)
                }
            }
            "configureOpenMeasurement" -> {
                mainHandler.post {
                    omLifecycle.configure(call.argument("creativeType"))
                    result.success(null)
                }
            }
            "startOpenMeasurementSession" -> {
                mainHandler.post {
                    omLifecycle.requestStart()
                    result.success(null)
                }
            }
            "logOpenMeasurementError" -> {
                mainHandler.post {
                    omLifecycle.logError(
                        errorType = call.argument("errorType"),
                        message = call.argument("message"),
                    )
                    result.success(null)
                }
            }
            "finishOpenMeasurementSession" -> {
                mainHandler.post {
                    omLifecycle.finish()
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun configureWebView() {
        webView.addJavascriptInterface(NativeBridge(), JAVASCRIPT_BRIDGE_NAME)
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
            openMeasurementJavascript?.let(::addDocumentStartScript)
            addDocumentStartScript(bridgeScript)
            // To avoid Android WebView loader for videos, inject JS code with 1x1 transparent pixel.
            addDocumentStartScript(posterStartScript)
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
                        "isForMainFrame" to request.isForMainFrame,
                    ),
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            if (result == "ALLOW") {
                                mainHandler.post {
                                    rememberBypassMainFrameLoad(url)
                                    view.loadUrl(url)
                                }
                            }
                        }

                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                        }

                        override fun notImplemented() {
                            mainHandler.post {
                                rememberBypassMainFrameLoad(url)
                                view.loadUrl(url)
                            }
                        }
                    }
                )
                return true
            }

            override fun onPageStarted(view: WebView, url: String?, favicon: android.graphics.Bitmap?) {
                super.onPageStarted(view, url, favicon)
                omLifecycle.markPageStarted(url)
                if (!documentStartSupported) {
                    // Older WebView versions do not support document-start scripts, so this
                    // fallback injects asynchronously and may still lose the race to early
                    // page scripts that call the bridge before evaluateJavascript completes.
                    injectFallbackStartScripts()
                }
            }

            override fun onPageFinished(view: WebView, url: String?) {
                super.onPageFinished(view, url)
                if (!documentStartSupported) {
                    injectFallbackStartScripts()
                }
                initialUserScripts
                    .filter { it.injectionTime == "AT_DOCUMENT_END" }
                    .forEach { evaluateJavascript(it.source) }
                evaluateJavascript(PLATFORM_READY_SCRIPT)
                omLifecycle.markPageFinished(url)
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

            @Suppress("DEPRECATION")
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
        if (hasLoadedInitialUrl) {
            return
        }
        hasLoadedInitialUrl = true
        omLifecycle.markPageStarted(initialUrl)
        if (!initialUrl.isNullOrBlank()) {
            webView.loadUrl(initialUrl)
        }
    }

    private fun rememberBypassMainFrameLoad(url: String) {
        bypassMainFrameLoads.remove(url)
        bypassMainFrameLoads.add(url)
        while (bypassMainFrameLoads.size > MAX_BYPASS_MAIN_FRAME_LOADS) {
            val iterator = bypassMainFrameLoads.iterator()
            if (!iterator.hasNext()) {
                return
            }
            iterator.next()
            iterator.remove()
        }
    }

    private fun addDocumentStartScript(source: String) {
        WebViewCompat.addDocumentStartJavaScript(
            webView,
            source,
            hashSetOf("*")
        )
    }

    private fun injectFallbackStartScripts() {
        evaluateJavascript(fallbackStartScriptsSource())
    }

    private fun fallbackStartScriptsSource(): String {
        val documentStartUserScripts = initialUserScripts
            .filter { it.injectionTime == "AT_DOCUMENT_START" }
            .joinToString(separator = "\n") { it.source }

        return """
            (function() {
              if (window.$JAVASCRIPT_BRIDGE_NAME != null &&
                  window.$JAVASCRIPT_BRIDGE_NAME._userScriptsAtDocumentStartLoaded === true) {
                return;
              }
              $bridgeScript
              $posterStartScript
              if (window.$JAVASCRIPT_BRIDGE_NAME == null ||
                  window.$JAVASCRIPT_BRIDGE_NAME._userScriptsAtDocumentStartLoaded === true) {
                return;
              }
              window.$JAVASCRIPT_BRIDGE_NAME._userScriptsAtDocumentStartLoaded = true;
              $documentStartUserScripts
            })();
        """.trimIndent()
    }

    private fun canUseOpenMeasurement(): Boolean = documentStartSupported && openMeasurementJavascript != null

    private fun logUnsupportedOpenMeasurement() {
        Log.w(
            OMConstants.logTag,
            if (!documentStartSupported) {
                "DOCUMENT_START_SCRIPT not supported, OM SDK disabled for this WebView"
            } else {
                "OM SDK JavaScript resource could not be loaded, OM SDK disabled for this WebView"
            }
        )
    }

    private fun destroyWebViewImmediately() {
        try {
            (webView.parent as? ViewGroup)?.removeView(webView)
            webView.stopLoading()
            webView.loadUrl("about:blank")
            webView.destroy()
        } catch (exception: Throwable) {
            Log.w(OMConstants.logTag, "Immediate WebView destroy failed", exception)
        }
    }

    private fun evaluateJavascript(source: String) {
        webView.evaluateJavascript(source, null)
    }

    private fun resolveJavaScriptCall(callHandlerId: String?, value: String = "null") {
        if (callHandlerId.isNullOrBlank()) {
            return
        }
        evaluateJavascript(
            """
            (function() {
              if (window.$JAVASCRIPT_BRIDGE_NAME[$callHandlerId] != null) {
                window.$JAVASCRIPT_BRIDGE_NAME[$callHandlerId].resolve($value);
                delete window.$JAVASCRIPT_BRIDGE_NAME[$callHandlerId];
              }
            })();
            """.trimIndent()
        )
    }

    private inner class NativeBridge {
        @JavascriptInterface
        fun _callHandler(handlerName: String?, callHandlerId: String?, args: String?) {
            if (handlerName.isNullOrBlank()) {
                return
            }
            val argsJson = args ?: "[]"

            mainHandler.post {
                channel.invokeMethod(
                    "onJavaScriptHandler",
                    mapOf(
                        "handlerName" to handlerName,
                        "args" to argsJson,
                    ),
                    object : MethodChannel.Result {
                        override fun success(result: Any?) {
                            resolveJavaScriptCall(callHandlerId)
                        }

                        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                            resolveJavaScriptCall(callHandlerId)
                        }

                        override fun notImplemented() {
                            resolveJavaScriptCall(callHandlerId)
                        }
                    }
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

private fun readInitialOmCreativeType(creationParams: Map<String, Any?>?): OMCreativeType? {
    return OMCreativeType.fromRawValue(creationParams?.get("initialOmCreativeType") as? String)
}

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

private fun loadOpenMeasurementJavaScript(context: Context): String? {
    return try {
        context.resources.openRawResource(R.raw.omsdk_v1)
            .bufferedReader(Charsets.UTF_8)
            .use { it.readText() }
    } catch (exception: Exception) {
        Log.e(OMConstants.logTag, "Failed to load OM SDK JavaScript", exception)
        null
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
