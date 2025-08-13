package so.kontext.sdk.flutter

import android.content.Context
import android.media.AudioManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DeviceSoundPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "kontext_flutter_sdk/device_sound")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSoundOn" -> {
                try {
                    val am = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val mediaVol = am.getStreamVolume(AudioManager.STREAM_MUSIC)
                    val streamMuted = am.isStreamMute(AudioManager.STREAM_MUSIC)
                    result.success(mediaVol > 0 && !streamMuted)
                } catch (t: Throwable) {
                    // In case of any error, we assume sound is on
                    result.success(true)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
