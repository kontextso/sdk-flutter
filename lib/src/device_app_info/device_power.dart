import 'dart:ui' show PlatformDispatcher;

enum BatteryState { charging, full, unplugged, unknown }

class DevicePower {
  DevicePower._({
    required this.batteryLevel,
    required this.batteryState,
    required this.lowerPowerMode,
  });

  final double? batteryLevel;
  final BatteryState? batteryState;
  final bool? lowerPowerMode;

  static Future<DevicePower> init(PlatformDispatcher dispatcher) async {
    return DevicePower._(
      batteryLevel: null, // TODO
      batteryState: null, // TODO
      lowerPowerMode: null, // TODO
    );
  }
}
