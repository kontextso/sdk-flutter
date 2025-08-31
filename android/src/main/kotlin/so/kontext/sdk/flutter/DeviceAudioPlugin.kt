package so.kontext.sdk.flutter

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.math.max
import kotlin.math.roundToInt

class DeviceAudioPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kontext_flutter_sdk/device_audio")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getAudioInfo" -> result.success(readAudioInfo())
            else -> result.notImplemented()
        }
    }

    private fun readAudioInfo(): Map<String, Any?> {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

        val maxVol = am.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
        val minVol = if (Build.VERSION.SDK_INT >= 28) am.getStreamMinVolume(AudioManager.STREAM_MUSIC) else 0
        val curVol = am.getStreamVolume(AudioManager.STREAM_MUSIC)
        val denom = max(1, maxVol - minVol)
        val norm = ((curVol - minVol).toDouble() / denom).coerceIn(0.0, 1.0)
        val volume = (norm * 100.0).roundToInt().coerceIn(0, 100)

        val muted = try {
            if (Build.VERSION.SDK_INT >= 23) {
                am.isStreamMute(AudioManager.STREAM_MUSIC) || volume == 0
            } else {
                volume == 0
            }
        } catch (_: Throwable) {
            volume == 0
        }

        val outputs = if (Build.VERSION.SDK_INT >= 23) {
            am.getDevices(AudioManager.GET_DEVICES_OUTPUTS)
        } else {
            emptyArray()
        }

        val kinds = buildSet<String> {
            outputs.forEach { d ->
                add(
                    when (d.type) {
                        AudioDeviceInfo.TYPE_WIRED_HEADPHONES,
                        AudioDeviceInfo.TYPE_WIRED_HEADSET,
                        AudioDeviceInfo.TYPE_LINE_ANALOG,
                        AudioDeviceInfo.TYPE_LINE_DIGITAL -> "wired"

                        AudioDeviceInfo.TYPE_BLUETOOTH_A2DP,
                        AudioDeviceInfo.TYPE_BLUETOOTH_SCO -> "bluetooth"

                        AudioDeviceInfo.TYPE_HDMI -> "hdmi"

                        AudioDeviceInfo.TYPE_USB_DEVICE,
                        AudioDeviceInfo.TYPE_USB_HEADSET -> "usb"

                        else -> "other"
                    }
                )
            }
        }

        val plugged = kinds.any { it != "other" }

        return mapOf(
            "volume" to volume,
            "muted" to muted,
            "outputPluggedIn" to plugged,
            "outputType" to kinds.toList()
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
