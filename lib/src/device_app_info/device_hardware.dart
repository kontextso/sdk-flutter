import 'dart:io' show Platform;
import 'dart:math' as math show min;
import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

enum DeviceType { handset, tablet, desktop, other }

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
  final DeviceType type;
  final int? bootTime;
  final bool? sdCardAvailable;

  static const _ch = MethodChannel('kontext_flutter_sdk/device_hardware');

  Map<String, dynamic> toJson() => {
        if (brand != null) 'brand': brand,
        if (model != null) 'model': model,
        'type': type.name,
        if (bootTime != null) 'bootTime': bootTime,
        if (sdCardAvailable != null) 'sdCardAvailable': sdCardAvailable,
      };

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
    } else if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      deviceType = DeviceType.desktop;
    }

    final bootEpochMs = await _getBootTime();
    final hasSd = await _hasSdCard();

    return DeviceHardware._(
      brand: brand,
      model: model,
      type: deviceType ?? DeviceType.other,
      bootTime: bootEpochMs,
      sdCardAvailable: hasSd,
    );
  }

  static double? _shortestSideDp(PlatformDispatcher dispatcher) {
    try {
      final view = dispatcher.views.first;
      final w = view.physicalSize.width / view.devicePixelRatio;
      final h = view.physicalSize.height / view.devicePixelRatio;
      return math.min(w, h);
    } catch (e) {
      Logger.error('Failed to get screen size: $e');
      return null;
    }
  }

  static Future<int?> _getBootTime() async {
    int? bootEpochMs;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        bootEpochMs = await _ch.invokeMethod<int>('getBootEpochMs');
      } catch (e) {
        Logger.error('Failed to get boot time: $e');
      }
    }
    return bootEpochMs;
  }

  static Future<bool?> _hasSdCard() async {
    bool? hasSd;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        hasSd = await _ch.invokeMethod<bool>('hasRemovableSdCard');
      } catch (e) {
        Logger.error('Failed to check for SD card: $e');
      }
    } else {
      hasSd = false;
    }
    return hasSd;
  }
}
