package so.kontext.sdk.flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

class KontextSdkPlugin : FlutterPlugin {
    private val sound = DeviceSoundPlugin()
    private val appInfo = AppInfoPlugin()
    private val hardware = DeviceHardwarePlugin()
    private val os = OperationSystemPlugin()
    private val power = DevicePowerPlugin()
    private val audio = DeviceAudioPlugin()
    private val network = DeviceNetworkPlugin()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sound.onAttachedToEngine(binding)
        appInfo.onAttachedToEngine(binding)
        hardware.onAttachedToEngine(binding)
        os.onAttachedToEngine(binding)
        power.onAttachedToEngine(binding)
        audio.onAttachedToEngine(binding)
        network.onAttachedToEngine(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        sound.onDetachedFromEngine(binding)
        appInfo.onDetachedFromEngine(binding)
        hardware.onDetachedFromEngine(binding)
        os.onDetachedFromEngine(binding)
        power.onDetachedFromEngine(binding)
        audio.onDetachedFromEngine(binding)
        network.onDetachedFromEngine(binding)
    }
}
