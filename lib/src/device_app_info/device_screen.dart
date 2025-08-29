import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/foundation.dart' show Brightness;

enum ScreenOrientation { portrait, landscape, unknown }

class DeviceScreen {
  DeviceScreen._({
    required this.width,
    required this.height,
    required this.dpr,
    required this.orientation,
    required this.darkMode,
  });

  final double? width;
  final double? height;
  final double? dpr;
  final ScreenOrientation? orientation;
  final bool? darkMode;

  static Future<DeviceScreen> init(PlatformDispatcher dispatcher) async {
    final screenSize = _screenSize(dispatcher);
    final isDarkMode = _isDarkMode(dispatcher);

    return DeviceScreen._(
      width: screenSize.width,
      height: screenSize.height,
      dpr: null,
      // TODO:
      orientation: null,
      // TODO:
      darkMode: isDarkMode,
    );
  }

  static ({double? width, double? height}) _screenSize(PlatformDispatcher dispatcher) {
    try {
      final physical = dispatcher.views.first.physicalSize;
      final w = physical.width;
      final h = physical.height;
      return (width: w, height: h);
    } catch (_) {
      return (width: null, height: null);
    }
  }

  static bool? _isDarkMode(PlatformDispatcher dispatcher) {
    try {
      final brightness = dispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } catch (_) {
      return null;
    }
  }
}
