package so.kontext.sdk.flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

class KontextSdkPlugin : FlutterPlugin {
    private val sound = DeviceSoundPlugin()
    private val appInfo = AppInfoPlugin()
    private val hardware = DeviceHardwarePlugin()
    private val os = OperationSystemPlugin()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sound.onAttachedToEngine(binding)
        appInfo.onAttachedToEngine(binding)
        hardware.onAttachedToEngine(binding)
        os.onAttachedToEngine(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sound.onDetachedFromEngine(binding)
        appInfo.onDetachedFromEngine(binding)
        hardware.onDetachedFromEngine(binding)
        os.onDetachedFromEngine(binding)
    }
}
