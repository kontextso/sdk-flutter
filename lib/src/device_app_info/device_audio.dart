import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';

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

  factory DeviceAudio.empty() => DeviceAudio._(
        volume: null,
        muted: null,
        outputPluggedIn: null,
        outputType: null,
      );

  Map<String, dynamic> toJson() => {
        if (volume != null) 'volume': volume,
        if (muted != null) 'muted': muted,
        if (outputPluggedIn != null) 'outputPluggedIn': outputPluggedIn,
        if (outputType != null) 'outputType': outputType!.map((e) => e.name).toList(),
      };

  static Future<DeviceAudio> init() async {
    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('getAudioInfo');
      final volume = (m?['volume'] as num?)?.round();
      final muted = m?['muted'] as bool?;
      final outputPluggedIn = m?['outputPluggedIn'] as bool?;
      final outputType = _parseTypes(m?['outputType'] as List<dynamic>?);

      return DeviceAudio._(
        volume: volume,
        muted: muted,
        outputPluggedIn: outputPluggedIn,
        outputType: outputType,
      );
    } catch (e) {
      Logger.error('Error fetching device audio info: $e');
      return DeviceAudio.empty();
    }
  }

  static List<AudioOutputType>? _parseTypes(List<dynamic>? types) {
    if (types == null) {
      return null;
    }
    return types.map((type) {
      return AudioOutputType.values.firstWhereOrElse((t) => t.name == type) ?? AudioOutputType.other;
    }).toList();
  }
}
