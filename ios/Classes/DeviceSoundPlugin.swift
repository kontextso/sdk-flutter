import Flutter
import AVFoundation

public class DeviceSoundPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "kontext_flutter_sdk/device_sound",
      binaryMessenger: registrar.messenger()
    )
    let instance = DeviceSoundPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isSoundOn":
      let volume = AVAudioSession.sharedInstance().outputVolume
      result(volume > 0.0001)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
