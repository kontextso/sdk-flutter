import 'dart:io' show Platform;
import 'dart:math' as math show min;

import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;
import 'dart:ui' show PlatformDispatcher;

enum DeviceType { handset, tablet, desktop, unknown }

class DeviceHardware {
  DeviceHardware._({
    required this.brand,
    required this.model,
    required this.type,
    required this.bootTime,
    required this.sdCardAvailable,
  });

  final String? brand;
  final String? model;
  final DeviceType? type;
  final int? bootTime;
  final bool? sdCardAvailable;

  static Future<DeviceHardware> init(PlatformDispatcher dispatcher) async {
    final deviceInfo = DeviceInfoPlugin();

    String? model;
    String? brand;
    DeviceType? deviceType;

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      final machine = iosInfo.utsname.machine;
      model = machine;
      brand = 'Apple';
      deviceType = machine.toLowerCase().contains('ipad') ? DeviceType.tablet : DeviceType.handset;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      model = androidInfo.model;
      brand = androidInfo.brand;

      final shortestSide = _shortestSideDp(dispatcher);
      deviceType = shortestSide != null && shortestSide >= 600 ? DeviceType.tablet : DeviceType.handset;
    }

    return DeviceHardware._(
      brand: brand,
      model: model,
      type: deviceType ?? DeviceType.unknown,
      bootTime: null, // TODO
      sdCardAvailable: null, // TODO
    );
  }

  static double? _shortestSideDp(PlatformDispatcher dispatcher) {
    try {
      final view = dispatcher.views.first;
      final w = view.physicalSize.width / view.devicePixelRatio;
      final h = view.physicalSize.height / view.devicePixelRatio;
      return math.min(w, h);
    } catch (_) {
      return null;
    }
  }
}
