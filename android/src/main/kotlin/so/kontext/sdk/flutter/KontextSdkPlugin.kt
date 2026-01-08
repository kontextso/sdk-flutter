package so.kontext.sdk.flutter

import io.flutter.embedding.engine.plugins.FlutterPlugin

class KontextSdkPlugin : FlutterPlugin {
    private val appInfo = AppInfoPlugin()
    private val hardware = DeviceHardwarePlugin()
    private val os = OperationSystemPlugin()
    private val power = DevicePowerPlugin()
    private val audio = DeviceAudioPlugin()
    private val network = DeviceNetworkPlugin()
    private val tcf = TransparencyConsentFramework()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appInfo.onAttachedToEngine(binding)
        hardware.onAttachedToEngine(binding)
        os.onAttachedToEngine(binding)
        power.onAttachedToEngine(binding)
        audio.onAttachedToEngine(binding)
        network.onAttachedToEngine(binding)
        tcf.onAttachedToEngine(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appInfo.onDetachedFromEngine(binding)
        hardware.onDetachedFromEngine(binding)
        os.onDetachedFromEngine(binding)
        power.onDetachedFromEngine(binding)
        audio.onDetachedFromEngine(binding)
        network.onDetachedFromEngine(binding)
        tcf.onDetachedFromEngine(binding)
    }
}
