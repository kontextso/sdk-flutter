import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:device_info_plus/device_info_plus.dart' show DeviceInfoPlugin;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

enum DeviceOS { android, ios, unknown }

class OperationSystem {
  OperationSystem._({
    required this.name,
    required this.version,
    required this.locale,
    required this.timezone,
  });

  final String name;
  final String version;
  final String locale;
  final String timezone;

  static const _ch = MethodChannel('kontext_flutter_sdk/operation_system');

  factory OperationSystem.empty() => OperationSystem._(
        name: '',
        version: '',
        locale: '',
        timezone: '',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'version': version,
        'locale': locale,
        'timezone': timezone,
      };

  static Future<OperationSystem> init(PlatformDispatcher dispatcher) async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      DeviceOS? os;
      String? systemVersion;

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        os = DeviceOS.ios;
        systemVersion = iosInfo.systemVersion;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        os = DeviceOS.android;
        systemVersion = androidInfo.version.release;
      }

      final locale = _currentLocale(dispatcher);
      final timezone = await _getTimezone();

      return OperationSystem._(
        name: os?.name ?? '',
        version: systemVersion ?? '',
        locale: locale ?? '',
        timezone: timezone ?? '',
      );
    }  catch (e) {
      Logger.error('Failed to get OS info: $e');
      return OperationSystem.empty();
    }
  }

  static String? _currentLocale(PlatformDispatcher dispatcher) {
    try {
      final locale = dispatcher.locale;
      final countryCode = locale.countryCode;
      return [locale.languageCode, countryCode?.toUpperCase()].whereType<String>().join('-');
    } catch (e) {
      Logger.error('Failed to get locale: $e');
    }
    return null;
  }

  static Future<String?> _getTimezone() async {
    try {
      return await _ch.invokeMethod<String>('getTimezone');
    } catch (e) {
      Logger.error('Failed to get timezone: $e');
    }
    return null;
  }
}
