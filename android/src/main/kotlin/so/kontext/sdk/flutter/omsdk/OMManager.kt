package so.kontext.sdk.flutter.omsdk

import android.content.Context
import android.util.Log
import android.webkit.WebView
import com.iab.omid.library.kontextso.Omid
import com.iab.omid.library.kontextso.adsession.AdSession
import com.iab.omid.library.kontextso.adsession.AdSessionConfiguration
import com.iab.omid.library.kontextso.adsession.AdSessionContext
import com.iab.omid.library.kontextso.adsession.CreativeType
import com.iab.omid.library.kontextso.adsession.ImpressionType
import com.iab.omid.library.kontextso.adsession.Owner
import com.iab.omid.library.kontextso.adsession.Partner

internal enum class OMCreativeType(val rawValue: String) {
    DISPLAY("display"),
    VIDEO("video");

    companion object {
        fun fromRawValue(value: String?): OMCreativeType? = values().firstOrNull { it.rawValue == value }
    }
}

internal object OMManager {
    private val partner: Partner? by lazy {
        try {
            Partner.createPartner(OMConstants.partnerName, OMConstants.integrationVersion)
        } catch (exception: IllegalArgumentException) {
            Log.e(OMConstants.logTag, "OM partner creation failed", exception)
            null
        }
    }

    fun activate(context: Context): Boolean {
        if (Omid.isActive()) {
            return true
        }

        return try {
            Omid.activate(context.applicationContext)
            Omid.isActive()
        } catch (exception: IllegalArgumentException) {
            Log.e(OMConstants.logTag, "OM SDK activation failed", exception)
            false
        } catch (exception: IllegalStateException) {
            Log.e(OMConstants.logTag, "OM SDK activation failed", exception)
            false
        }
    }

    fun createSession(
        webView: WebView,
        contentUrl: String?,
        creativeType: OMCreativeType,
    ): OMSession? {
        if (!Omid.isActive()) {
            Log.w(OMConstants.logTag, "OM session creation skipped because the SDK is not active")
            return null
        }

        val partner = partner
        if (partner == null) {
            return null
        }

        return try {
            val context = AdSessionContext.createHtmlAdSessionContext(
                partner,
                webView,
                contentUrl,
                "",
            )
            val (omCreativeType, mediaEventsOwner) = when (creativeType) {
                OMCreativeType.DISPLAY -> CreativeType.HTML_DISPLAY to Owner.NONE
                OMCreativeType.VIDEO -> CreativeType.VIDEO to Owner.JAVASCRIPT
            }
            val configuration = AdSessionConfiguration.createAdSessionConfiguration(
                omCreativeType,
                ImpressionType.BEGIN_TO_RENDER,
                Owner.JAVASCRIPT,
                mediaEventsOwner,
                false,
            )
            val session = AdSession.createAdSession(configuration, context).apply {
                registerAdView(webView)
            }
            OMSession(session = session, webView = webView)
        } catch (exception: IllegalArgumentException) {
            Log.e(OMConstants.logTag, "OM session creation failed", exception)
            null
        } catch (exception: IllegalStateException) {
            Log.e(OMConstants.logTag, "OM session creation failed", exception)
            null
        }
    }
}
