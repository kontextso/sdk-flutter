package so.kontext.sdk.flutter.omsdk

import android.util.Log
import android.view.ViewGroup
import android.webkit.WebView
import com.iab.omid.library.megabrainco.adsession.AdSession
import com.iab.omid.library.megabrainco.adsession.ErrorType

internal class OMSession(
    private val session: AdSession,
    private val webView: WebView,
) {
    fun start() {
        session.start()
    }

    fun retire() {
        try {
            webView.evaluateJavascript("window.postMessage({ type: 'retire-iframe' }, '*');", null)
        } catch (exception: Throwable) {
            Log.w(OMConstants.logTag, "OM retire message failed", exception)
        }
    }

    fun finish() {
        session.finish()
    }

    fun logError(errorType: String?, message: String?) {
        val omErrorType = if (errorType == "video") ErrorType.VIDEO else ErrorType.GENERIC
        try {
            session.error(omErrorType, message ?: "unknown")
        } catch (exception: IllegalStateException) {
            Log.e(OMConstants.logTag, "OM error logging failed", exception)
        }
    }

    fun retainedWebView(): OMRetainedWebView = OMRetainedWebView(webView)
}

internal class OMRetainedWebView(
    private val webView: WebView,
) {
    fun destroy() {
        try {
            (webView.parent as? ViewGroup)?.removeView(webView)
            webView.stopLoading()
            webView.loadUrl("about:blank")
            webView.destroy()
        } catch (exception: Throwable) {
            Log.w(OMConstants.logTag, "Deferred WebView destroy failed", exception)
        }
    }
}
