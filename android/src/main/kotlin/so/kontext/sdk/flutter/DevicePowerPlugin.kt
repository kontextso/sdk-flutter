package so.kontext.sdk.flutter

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DevicePowerPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kontext_flutter_sdk/device_power")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getPowerInfo" -> result.success(readPowerInfo())
            else -> result.notImplemented()
        }
    }

    private fun readPowerInfo(): Map<String, Any?> {
        var levelPct: Int? = null
        var stateStr = "unknown"

        try {
            val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val raw = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            if (raw != Int.MIN_VALUE) {
                levelPct = raw.coerceIn(0, 100)
            }
        } catch (_: Throwable) {
        }

        val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        if (intent != null) {
            if (levelPct == null) {
                val level = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                val scale = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
                if (level >= 0 && scale > 0) {
                    levelPct = ((level.toDouble() * 100.0) / scale.toDouble())
                        .toInt()
                        .coerceIn(0, 100)
                }
            }

            val status = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, 0) != 0

            stateStr = when {
                status == BatteryManager.BATTERY_STATUS_FULL -> "full"
                !plugged -> "unplugged"
                status == BatteryManager.BATTERY_STATUS_CHARGING -> "charging"
                status == BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "charging"
                else -> "unknown"
            }
        }

        val lowPower: Boolean? = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                pm.isPowerSaveMode
            } else {
                null
            }
        } catch (_: Throwable) {
            null
        }

        return mapOf(
            "level" to levelPct,
            "state" to stateStr,
            "lowPower" to lowPower
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
