package so.kontext.sdk.flutter

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.telephony.TelephonyManager
import android.webkit.WebSettings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DeviceNetworkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kontext_flutter_sdk/device_network")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getNetworkInfo" -> result.success(readNetworkInfo())
            else -> result.notImplemented()
        }
    }

    private fun readNetworkInfo(): Map<String, Any?> {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

        val userAgent = try {
            WebSettings.getDefaultUserAgent(context)
        } catch (_: Throwable) {
            System.getProperty("http.agent")
        }

        val type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val net = cm.activeNetwork
            val caps = cm.getNetworkCapabilities(net)
            when {
                caps == null -> "other"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                else -> "other"
            }
        } else {
            @Suppress("DEPRECATION")
            cm.activeNetworkInfo?.let { info ->
                @Suppress("DEPRECATION")
                when (info.type) {
                    ConnectivityManager.TYPE_WIFI -> "wifi"
                    ConnectivityManager.TYPE_MOBILE -> "cellular"
                    ConnectivityManager.TYPE_ETHERNET -> "ethernet"
                    else -> "other"
                }
            } ?: "other"
        }

        val (detail, carrier) = readCellularDetailAndCarrier(type == "cellular")

        return mapOf(
            "userAgent" to userAgent,
            "type" to type,
            "detail" to detail,
            "carrier" to carrier
        )
    }

    private fun readCellularDetailAndCarrier(isCellular: Boolean): Pair<String, String?> {
        if (!isCellular) return "other" to null

        var carrier: String? = null
        var detail = "unknown"

        try {
            val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

            carrier = try {
                val cid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    tm.simCarrierIdName?.toString()
                } else null
                (cid ?: tm.networkOperatorName)?.trim()?.takeIf { it.isNotEmpty() }
            } catch (_: SecurityException) {
                null
            }

            val tech = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    tm.dataNetworkType
                } else {
                    @Suppress("DEPRECATION")
                    tm.networkType
                }
            } catch (_: SecurityException) {
                TelephonyManager.NETWORK_TYPE_UNKNOWN
            }

            detail = when (tech) {
                // 5G
                TelephonyManager.NETWORK_TYPE_NR -> "nr"

                // 4G
                TelephonyManager.NETWORK_TYPE_LTE, 19 -> "lte"

                // HSPA
                TelephonyManager.NETWORK_TYPE_HSDPA,
                TelephonyManager.NETWORK_TYPE_HSUPA,
                TelephonyManager.NETWORK_TYPE_HSPA,
                TelephonyManager.NETWORK_TYPE_HSPAP -> "hspa"

                // 3G
                TelephonyManager.NETWORK_TYPE_UMTS,
                TelephonyManager.NETWORK_TYPE_EVDO_0,
                TelephonyManager.NETWORK_TYPE_EVDO_A,
                TelephonyManager.NETWORK_TYPE_EVDO_B,
                TelephonyManager.NETWORK_TYPE_EHRPD,
                TelephonyManager.NETWORK_TYPE_TD_SCDMA -> "3g"

                // 2G
                TelephonyManager.NETWORK_TYPE_EDGE -> "edge"
                TelephonyManager.NETWORK_TYPE_GPRS -> "gprs"
                TelephonyManager.NETWORK_TYPE_GSM,
                TelephonyManager.NETWORK_TYPE_CDMA,
                TelephonyManager.NETWORK_TYPE_1xRTT,
                TelephonyManager.NETWORK_TYPE_IDEN -> "2g"

                // Other
                TelephonyManager.NETWORK_TYPE_IWLAN -> "other"
                TelephonyManager.NETWORK_TYPE_UNKNOWN -> "other"
                else -> "other"
            }
        } catch (_: Throwable) { }

        return detail to carrier
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
