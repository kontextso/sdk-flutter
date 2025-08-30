import 'dart:ui' show PlatformDispatcher, Brightness, FlutterView, Size;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

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
    final view = _primaryView(dispatcher);
    final physical = view?.physicalSize;
    final dpr = view?.devicePixelRatio;
    final orientation = _getOrientation(physical);
    final isDarkMode = _isDarkMode(dispatcher);

    return DeviceScreen._(
      width: physical?.width,
      height: physical?.height,
      dpr: dpr,
      orientation: orientation,
      darkMode: isDarkMode,
    );
  }

  static FlutterView? _primaryView(PlatformDispatcher dispatcher) {
    try {
      return dispatcher.views.isNotEmpty ? dispatcher.views.first : null;
    } catch (e) {
      Logger.error('Failed to get primary FlutterView: $e');
    }
    return null;
  }

  static ScreenOrientation? _getOrientation(Size? physical) {
    if (physical == null) {
      return null;
    }

    final w = physical.width;
    final h = physical.height;
    if (w <= 0 || h <= 0) {
      return ScreenOrientation.unknown;
    }
    if (w == h) {
      return ScreenOrientation.unknown;
    }
    return w > h ? ScreenOrientation.landscape : ScreenOrientation.portrait;
  }

  static bool? _isDarkMode(PlatformDispatcher dispatcher) {
    try {
      final brightness = dispatcher.platformBrightness;
      return brightness == Brightness.dark;
    } catch (e) {
      Logger.error('Failed to get platform brightness: $e');
    }
    return null;
  }
}
