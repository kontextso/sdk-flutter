import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

enum AudioOutputType { wired, hdmi, bluetooth, usb, other }

class DeviceAudio {
  DeviceAudio._({
    required this.volume,
    required this.muted,
    required this.outputPluggedIn,
    required this.outputType,
  });

  final int? volume;
  final bool? muted;
  final bool? outputPluggedIn;
  final List<AudioOutputType>? outputType;

  static const _ch = MethodChannel('kontext_flutter_sdk/device_audio');

  Map<String, dynamic> toJson() => {
        if (volume != null) 'volume': volume,
        if (muted != null) 'muted': muted,
        if (outputPluggedIn != null) 'outputPluggedIn': outputPluggedIn,
        if (outputType != null) 'outputType': outputType!.map((e) => e.name).toList(),
      };

  static Future<DeviceAudio> init() async {
    int? volume;
    bool? muted;
    bool? outputPluggedIn;
    List<AudioOutputType>? outputType;

    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('getAudioInfo');
      volume = (m?['volume'] as num?)?.round();
      muted = m?['muted'] as bool?;
      outputPluggedIn = m?['outputPluggedIn'] as bool?;
      outputType = _parseTypes(m?['outputType'] as List<dynamic>?);
    } catch (e) {
      Logger.error('Error fetching device audio info: $e');
    }

    return DeviceAudio._(
      volume: volume,
      muted: muted,
      outputPluggedIn: outputPluggedIn,
      outputType: outputType,
    );
  }

  static List<AudioOutputType>? _parseTypes(List<dynamic>? types) {
    if (types == null) {
      return null;
    }
    return types.map((type) {
      return switch (type) {
        'wired' => AudioOutputType.wired,
        'hdmi' => AudioOutputType.hdmi,
        'bluetooth' => AudioOutputType.bluetooth,
        'usb' => AudioOutputType.usb,
        _ => AudioOutputType.other,
      };
    }).toList();
  }
}
