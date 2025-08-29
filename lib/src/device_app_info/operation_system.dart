import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;

enum DeviceOS { android, ios, unknown }

class OperationSystem {
  OperationSystem._({
    required this.name,
    required this.version,
    required this.locale,
    required this.timezone,
  });

  final String? name;
  final String? version;
  final String? locale;
  final String? timezone;

  static Future<OperationSystem> init(PlatformDispatcher dispatcher) async {
    final deviceInfo = DeviceInfoPlugin();

    DeviceOS? os;
    String? systemVersion;
    final locale = _currentLocale(dispatcher);

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      os = DeviceOS.ios;
      systemVersion = iosInfo.systemVersion;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      os = DeviceOS.android;
      systemVersion = androidInfo.version.release;
    }

    return OperationSystem._(
      name: os?.name,
      version: systemVersion,
      locale: locale,
      timezone: null, // TODO:
    );
  }

  static String? _currentLocale(PlatformDispatcher dispatcher) {
    try {
      final locale = dispatcher.locale;
      final countryCode = locale.countryCode;
      return [locale.languageCode, countryCode?.toUpperCase()].whereType<String>().join('-');
    } catch (_) {
      return null;
    }
  }
}
