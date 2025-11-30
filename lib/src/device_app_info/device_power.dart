import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

enum BatteryState { charging, full, unplugged, unknown }

class DevicePower {
  DevicePower._({
    required this.batteryLevel,
    required this.batteryState,
    required this.lowPowerMode,
  });

  final double? batteryLevel;
  final BatteryState? batteryState;
  final bool? lowPowerMode;

  static const _ch = MethodChannel('kontext_flutter_sdk/device_power');

  factory DevicePower.empty() => DevicePower._(
        batteryLevel: null,
        batteryState: null,
        lowPowerMode: null,
      );

  Map<String, dynamic> toJson() => {
        if (batteryLevel != null) 'batteryLevel': batteryLevel,
        if (batteryState != null) 'batteryState': batteryState!.name,
        if (lowPowerMode != null) 'lowPowerMode': lowPowerMode,
      };

  static Future<DevicePower> init(PlatformDispatcher dispatcher) async {
    final empty = DevicePower.empty();
    if (kIsWeb) {
      return empty;
    }

    try {
      final m = await _ch.invokeMapMethod<String, dynamic>('getPowerInfo');
      final batteryLevel = (m?['level'] as num?)?.toDouble();
      final batteryState = _parse(m?['state'] as String?);
      final lowPowerMode = m?['lowPower'] as bool?;

      return DevicePower._(
        batteryLevel: batteryLevel,
        batteryState: batteryState,
        lowPowerMode: lowPowerMode,
      );
    } catch (e) {
      Logger.error('Failed to get power info: $e');
      return empty;
    }
  }

  static BatteryState? _parse(String? state) {
    return switch (state) {
      'charging' => BatteryState.charging,
      'full' => BatteryState.full,
      'unplugged' => BatteryState.unplugged,
      _ => BatteryState.unknown
    };
  }
}
