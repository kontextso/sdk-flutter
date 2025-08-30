package so.kontext.sdk.flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

class KontextSdkPlugin : FlutterPlugin {
    private val sound = DeviceSoundPlugin()
    private val appInfo = AppInfoPlugin()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sound.onAttachedToEngine(binding)
        appInfo.onAttachedToEngine(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sound.onDetachedFromEngine(binding)
        appInfo.onDetachedFromEngine(binding)
    }
}
