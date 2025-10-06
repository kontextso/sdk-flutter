import Flutter

public class KontextSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        AppInfoPlugin.register(with: registrar)
        DeviceHardwarePlugin.register(with: registrar)
        OperationSystemPlugin.register(with: registrar)
        DevicePowerPlugin.register(with: registrar)
        DeviceAudioPlugin.register(with: registrar)
        DeviceNetworkPlugin.register(with: registrar)
        TransparencyConsentFrameworkPlugin.register(with: registrar)
        SKOverlayPlugin.register(with: registrar)
        SKStoreProductPlugin.register(with: registrar)
    }
}
