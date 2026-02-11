import Flutter

public class KontextSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        AdvertisingIdPlugin.register(with: registrar)
        AppInfoPlugin.register(with: registrar)
        DeviceAudioPlugin.register(with: registrar)
        DeviceHardwarePlugin.register(with: registrar)
        DeviceNetworkPlugin.register(with: registrar)
        DevicePowerPlugin.register(with: registrar)
        OperationSystemPlugin.register(with: registrar)
        TrackingAuthorizationPlugin.register(with: registrar)
        TransparencyConsentFrameworkPlugin.register(with: registrar)
    }
}
