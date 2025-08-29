enum AudioOutputType { wired, hdmi, bluetooth, usb, unknown }

class DeviceAudio {
  DeviceAudio._({
    required this.volume,
    required this.muted,
    required this.outputPluggedIn,
    required this.outputType,
  });

  final double? volume;
  final bool? muted;
  final bool? outputPluggedIn;
  final List<AudioOutputType>? outputType;

  static Future<DeviceAudio> init() async {
    return DeviceAudio._(
      volume: null, // TODO
      muted: null, // TODO
      outputPluggedIn: null, // TODO
      outputType: null, // TODO
    );
  }
}
