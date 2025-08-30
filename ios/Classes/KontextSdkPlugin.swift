import Flutter

public class KontextSdkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        DeviceSoundPlugin.register(with: registrar)
        AppInfoPlugin.register(with: registrar)
        DeviceHardwarePlugin.register(with: registrar)
        OperationSystemPlugin.register(with: registrar)
    }
}
