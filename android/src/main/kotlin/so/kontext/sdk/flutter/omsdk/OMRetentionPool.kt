package so.kontext.sdk.flutter.omsdk

import android.os.Handler
import android.os.Looper
import java.util.UUID

internal object OMRetentionPool {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val retainedWebViews = mutableMapOf<String, OMRetainedWebView>()

    fun retain(webView: OMRetainedWebView) {
        val id = UUID.randomUUID().toString()
        retainedWebViews[id] = webView
        mainHandler.postDelayed(
            {
                retainedWebViews.remove(id)?.destroy()
            },
            OMConstants.retentionIntervalMillis,
        )
    }
}
