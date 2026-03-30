package so.kontext.sdk.flutter.omsdk

import android.os.SystemClock
import android.util.Log
import android.webkit.WebView

internal class WebViewOMLifecycle(
    private val webView: WebView,
    private val initialContentUrl: String?,
    initialCreativeType: OMCreativeType?,
    private val canUseOpenMeasurement: () -> Boolean,
    private val logUnsupportedOpenMeasurement: () -> Unit,
) {
    private var activeOMSession: OMSession? = null
    private var hasDeferredDestroy = false
    private var hasLoadedPage = false
    private var hasLoggedUnsupportedOpenMeasurement = false
    private var lastContentUrl: String? = initialContentUrl
    private var lastOpenMeasurementFinishTimestampMillis: Long? = null
    private var omCreativeType: OMCreativeType? = initialCreativeType
    private var pendingOpenMeasurementStart = false

    init {
        if (omCreativeType != null && !canUseOpenMeasurement()) {
            maybeLogUnsupportedOpenMeasurement()
            omCreativeType = null
        }
    }

    fun configure(creativeTypeRaw: String?) {
        val parsedCreativeType = OMCreativeType.fromRawValue(creativeTypeRaw)
        if (parsedCreativeType != null && !canUseOpenMeasurement()) {
            maybeLogUnsupportedOpenMeasurement()
            omCreativeType = null
            return
        }

        omCreativeType = parsedCreativeType
        startOpenMeasurementSessionIfReady()
    }

    fun markPageStarted(url: String?) {
        hasLoadedPage = false
        lastContentUrl = url ?: initialContentUrl
    }

    fun markPageFinished(url: String?) {
        hasLoadedPage = true
        lastContentUrl = url ?: initialContentUrl
        startOpenMeasurementSessionIfReady()
    }

    fun requestStart() {
        if (!canUseOpenMeasurement()) {
            if (omCreativeType != null) {
                maybeLogUnsupportedOpenMeasurement()
            }
            return
        }

        pendingOpenMeasurementStart = true
        startOpenMeasurementSessionIfReady()
    }

    fun logError(errorType: String?, message: String?) {
        activeOMSession?.logError(errorType = errorType, message = message)
    }

    fun finish() {
        pendingOpenMeasurementStart = false

        val activeOMSession = activeOMSession ?: return
        this.activeOMSession = null
        activeOMSession.retire()
        activeOMSession.finish()
        lastOpenMeasurementFinishTimestampMillis = SystemClock.uptimeMillis()
    }

    fun dispose(): Boolean {
        if (hasDeferredDestroy) {
            return true
        }

        val remainingOpenMeasurementRetentionMillis = remainingOpenMeasurementRetentionMillis()
        if (remainingOpenMeasurementRetentionMillis <= 0L) {
            return false
        }

        hasDeferredDestroy = true
        OMRetentionPool.retain(
            webView = OMRetainedWebView(webView),
            delayMillis = remainingOpenMeasurementRetentionMillis,
        )
        return true
    }

    private fun startOpenMeasurementSessionIfReady() {
        if (activeOMSession != null || hasDeferredDestroy) {
            return
        }

        if (!pendingOpenMeasurementStart) {
            return
        }

        val omCreativeType = omCreativeType ?: return
        if (!hasLoadedPage) {
            return
        }

        if (!canUseOpenMeasurement()) {
            maybeLogUnsupportedOpenMeasurement()
            pendingOpenMeasurementStart = false
            return
        }

        if (!OMManager.activate(webView.context)) {
            return
        }

        val session = OMManager.createSession(
            webView = webView,
            contentUrl = lastContentUrl ?: webView.url?.toString() ?: initialContentUrl,
            creativeType = omCreativeType,
        ) ?: run {
            pendingOpenMeasurementStart = false
            return
        }

        try {
            session.start()
            activeOMSession = session
            lastOpenMeasurementFinishTimestampMillis = null
            pendingOpenMeasurementStart = false
        } catch (exception: IllegalStateException) {
            Log.e(OMConstants.logTag, "OM session start failed", exception)
            pendingOpenMeasurementStart = false
        }
    }

    private fun maybeLogUnsupportedOpenMeasurement() {
        if (hasLoggedUnsupportedOpenMeasurement) {
            return
        }
        hasLoggedUnsupportedOpenMeasurement = true
        logUnsupportedOpenMeasurement()
    }

    private fun remainingOpenMeasurementRetentionMillis(): Long {
        val finishedAt = lastOpenMeasurementFinishTimestampMillis ?: return 0L
        val elapsedMillis = SystemClock.uptimeMillis() - finishedAt
        return (OMConstants.retentionIntervalMillis - elapsedMillis).coerceAtLeast(0L)
    }
}
