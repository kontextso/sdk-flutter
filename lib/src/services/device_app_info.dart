import 'dart:io' show Platform;
import 'dart:math' as math show min;
import 'dart:ui' show PlatformDispatcher, Brightness;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:kontext_flutter_sdk/src/services/apple_product_names.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum DeviceOS { android, ios }

enum DeviceType { handset, tablet, desktop }

class DeviceAppInfo {
  DeviceAppInfo({
    this.os,
    this.systemVersion,
    this.model,
    this.brand,
    this.deviceType,
    this.appBundleId,
    this.appVersion,
    this.appStoreUrl,
    this.locale,
    this.screenWidth,
    this.screenHeight,
    this.isDarkMode,
  });

  static DeviceAppInfo? _instance;
  static Future<DeviceAppInfo>? _loading;

  final DeviceOS? os;
  final String? systemVersion;
  final String? model;
  final String? brand;
  final DeviceType? deviceType;
  final String? appBundleId;
  final String? appVersion;
  final String? appStoreUrl;

  final String? locale;
  final int? screenWidth;
  final int? screenHeight;
  final bool? isDarkMode;

  Map<String, dynamic> toJson() {
    return {
      'os': os?.name,
      'systemVersion': systemVersion,
      'model': model,
      'brand': brand,
      'deviceType': deviceType?.name,
      'appBundleId': appBundleId,
      'appVersion': appVersion,
      'appStoreUrl': appStoreUrl,
      'locale': locale,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'isDarkMode': isDarkMode,
    };
  }

  static DeviceAppInfo? get instance {
    final i = _instance;
    if (i == null) {
      Logger.error('DeviceAppInfo.init() must be awaited before use.');
    }

    return i;
  }

  static Future<DeviceAppInfo> init({String? iosAppStoreId}) async {
    if (_instance != null) {
      return Future.value(_instance!);
    }

    return _loading ??= _initInternal(iosAppStoreId: iosAppStoreId);
  }

  static Future<DeviceAppInfo> _initInternal({String? iosAppStoreId}) async {
    try {
      if (kIsWeb) {
        return _instance = DeviceAppInfo(deviceType: DeviceType.desktop);
      }

      final appInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      DeviceOS? os;
      String? systemVersion;
      String? model;
      String? brand;
      DeviceType? deviceType;

      String? appStoreUrl;
      final appBundleId = appInfo.packageName;
      final appVersion = '${appInfo.version}+${appInfo.buildNumber}';

      final dispatcher = PlatformDispatcher.instance;;

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        os = DeviceOS.ios;
        systemVersion = iosInfo.systemVersion;
        final machine = iosInfo.utsname.machine;
        model = appleProductNames.getOrNull(machine) ?? machine;
        brand = 'Apple';
        deviceType = machine.toLowerCase().contains('ipad') ? DeviceType.tablet : DeviceType.handset;
        if (iosAppStoreId != null) {
          appStoreUrl = 'https://apps.apple.com/app/id$iosAppStoreId';
        }
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        os = DeviceOS.android;
        systemVersion = androidInfo.version.release;
        model = androidInfo.model;
        brand = androidInfo.brand;

        final shortestSide = _shortestSideDp(dispatcher);
        deviceType = shortestSide != null && shortestSide >= 600 ? DeviceType.tablet : DeviceType.handset;

        appStoreUrl = 'https://play.google.com/store/apps/details?id=$appBundleId';
      } else {
        return _instance = DeviceAppInfo(
          appBundleId: appBundleId,
          appVersion: appVersion,
          deviceType: DeviceType.desktop,
        );
      }

      final locale = _currentLocale(dispatcher);
      final screenSize = _screenSize(dispatcher);
      final isDarkMode = _isDarkMode(dispatcher);

      return _instance = DeviceAppInfo(
        os: os,
        systemVersion: systemVersion,
        model: model,
        brand: brand,
        deviceType: deviceType,
        appBundleId: appBundleId,
        appVersion: appVersion,
        appStoreUrl: appStoreUrl,
        locale: locale,
        screenWidth: screenSize.width?.round(),
        screenHeight: screenSize.height?.round(),
        isDarkMode: isDarkMode,
      );
    } catch (e, stack) {
      Logger.exception(e, stack);
      return _instance = DeviceAppInfo();
    } finally {
      _loading = null;
    }
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

  static String? _currentLocale(PlatformDispatcher dispatcher) {
    try {
      final locale = dispatcher.locale;
      final countryCode = locale.countryCode;
      return [locale.languageCode, countryCode?.toUpperCase()].whereType<String>().join('-');
    } catch (_) {
      return null;
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
