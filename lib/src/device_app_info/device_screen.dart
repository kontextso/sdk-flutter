import 'dart:ui' show PlatformDispatcher, Brightness, FlutterView, Size;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

enum ScreenOrientation { portrait, landscape }

class DeviceScreen {
  DeviceScreen._({
    required this.width,
    required this.height,
    required this.dpr,
    required this.orientation,
    required this.darkMode,
  });

  final double width;
  final double height;
  final double dpr;
  final ScreenOrientation orientation;
  final bool darkMode;

  factory DeviceScreen.empty() => DeviceScreen._(
        width: 0,
        height: 0,
        dpr: 0,
        orientation: ScreenOrientation.portrait,
        darkMode: false,
      );

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'dpr': dpr,
        'orientation': orientation.name,
        'darkMode': darkMode,
      };

  static Future<DeviceScreen> init(PlatformDispatcher dispatcher) async {
    final view = _primaryView(dispatcher);
    final physical = view?.physicalSize;
    final dpr = view?.devicePixelRatio;
    final orientation = _getOrientation(physical);
    final isDarkMode = _isDarkMode(dispatcher);

    return DeviceScreen._(
      width: physical?.width ?? 0,
      height: physical?.height ?? 0,
      dpr: dpr ?? 0,
      orientation: orientation ?? ScreenOrientation.portrait,
      darkMode: isDarkMode ?? false,
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
