package so.kontext.sdk.flutter

import android.content.Context
import android.preference.PreferenceManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.engine.plugins.FlutterPlugin

class TransparencyConsentFramework : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(
            binding.binaryMessenger,
            "kontext_flutter_sdk/transparency_consent_framework"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getTCFData" -> {
                result.success(getTcfData())
            }
            else -> result.notImplemented()
        }
    }

    private fun getTcfData(): Map<String, Any?> {
        return try {
            val prefs = PreferenceManager.getDefaultSharedPreferences(context)

            val tcString: String? = prefs.getString("IABTCF_TCString", null)
                ?.let { s -> if (s.isNotEmpty()) s else null }

            val gdprAppliesRaw: Int? =
                if (prefs.contains("IABTCF_gdprApplies")) {
                    try {
                        prefs.getInt("IABTCF_gdprApplies", 0)
                    } catch (_: Throwable) {
                        prefs.getString("IABTCF_gdprApplies", null)?.toIntOrNull()
                    }
                } else {
                    null
                }

            val gdprApplies: Int? = when (gdprAppliesRaw) {
                0 -> 0
                1 -> 1
                else -> null
            }

            mapOf(
                "tcString" to tcString,
                "gdprApplies" to gdprApplies,
            )
        } catch (_: Throwable) {
            mapOf(
                "tcString" to null,
                "gdprApplies" to null,
            )
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

