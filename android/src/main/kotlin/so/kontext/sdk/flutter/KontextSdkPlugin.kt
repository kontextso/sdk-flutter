package so.kontext.sdk.flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

class KontextSdkPlugin : FlutterPlugin {
    private val advertisingId = AdvertisingIdPlugin()
    private val appInfo = AppInfoPlugin()
    private val audio = DeviceAudioPlugin()
    private val hardware = DeviceHardwarePlugin()
    private val network = DeviceNetworkPlugin()
    private val os = OperationSystemPlugin()
    private val power = DevicePowerPlugin()
    private val tcf = TransparencyConsentFramework()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        advertisingId.onAttachedToEngine(binding)
        appInfo.onAttachedToEngine(binding)
        audio.onAttachedToEngine(binding)
        hardware.onAttachedToEngine(binding)
        network.onAttachedToEngine(binding)
        os.onAttachedToEngine(binding)
        power.onAttachedToEngine(binding)
        tcf.onAttachedToEngine(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        advertisingId.onDetachedFromEngine(binding)
        appInfo.onDetachedFromEngine(binding)
        audio.onDetachedFromEngine(binding)
        hardware.onDetachedFromEngine(binding)
        network.onDetachedFromEngine(binding)
        os.onDetachedFromEngine(binding)
        power.onDetachedFromEngine(binding)
        tcf.onDetachedFromEngine(binding)
    }
}
