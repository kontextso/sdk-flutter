import 'dart:io' show Platform;
import 'dart:math' as math show min;

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
    this.appBundleId,
    this.appVersion,
    this.appStoreUrl,
    this.deviceType,
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

        final shortestSide = _shortestSideDp();
        deviceType = shortestSide != null && shortestSide >= 600 ? DeviceType.tablet : DeviceType.handset;

        appStoreUrl = 'https://play.google.com/store/apps/details?id=$appBundleId';
      } else {
        return _instance = DeviceAppInfo(
          appBundleId: appBundleId,
          appVersion: appVersion,
          deviceType: DeviceType.desktop,
        );
      }

      return _instance = DeviceAppInfo(
        os: os,
        systemVersion: systemVersion,
        model: model,
        brand: brand,
        deviceType: deviceType,
        appBundleId: appBundleId,
        appVersion: appVersion,
        appStoreUrl: appStoreUrl,
      );
    } catch (e, stack) {
      Logger.exception(e, stack);
      return _instance = DeviceAppInfo();
    } finally {
      _loading = null;
    }
  }

  static double? _shortestSideDp() {
    try {
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final w = view.physicalSize.width / view.devicePixelRatio;
      final h = view.physicalSize.height / view.devicePixelRatio;
      return math.min(w, h);
    } catch (_) {
      return null;
    }
  }
}
