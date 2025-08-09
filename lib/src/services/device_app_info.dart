import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kontext_flutter_sdk/src/services/apple_product_names.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';
import 'package:kontext_flutter_sdk/src/utils/extensions.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum DeviceOS { android, ios }

class DeviceAppInfo {
  DeviceAppInfo({
    this.os,
    this.systemVersion,
    this.model,
    this.brand,
    this.appBundleId,
    this.appVersion,
    this.appStoreUrl,
  });

  static DeviceAppInfo? _instance;
  static Future<DeviceAppInfo>? _loading;

  final DeviceOS? os;
  final String? systemVersion;
  final String? model;
  final String? brand;
  final String? appBundleId;
  final String? appVersion;
  final String? appStoreUrl;

  Map<String, dynamic> toJson() {
    return {
      'os': os?.name,
      'systemVersion': systemVersion,
      'model': model,
      'brand': brand,
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
        return _instance = DeviceAppInfo();
      }

      final appInfo = await PackageInfo.fromPlatform();
      final deviceInfo = DeviceInfoPlugin();

      DeviceOS? os;
      String? systemVersion;
      String? model;
      String? brand;

      String? appStoreUrl;
      final appBundleId = appInfo.packageName;
      final appVersion = '${appInfo.version}+${appInfo.buildNumber}';

      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        os = DeviceOS.ios;
        systemVersion = iosInfo.systemVersion;
        model = appleProductNames.getOrNull(iosInfo.utsname.machine) ?? iosInfo.utsname.machine;
        brand = 'Apple';
        if (iosAppStoreId != null) {
          appStoreUrl = 'https://apps.apple.com/app/id$iosAppStoreId';
        }
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        os = DeviceOS.android;
        systemVersion = androidInfo.version.release;
        model = androidInfo.model;
        brand = androidInfo.brand;
        appStoreUrl = 'https://play.google.com/store/apps/details?id=$appBundleId';
      } else {
        return _instance = DeviceAppInfo(
          appBundleId: appBundleId,
          appVersion: appVersion,
        );
      }

      return _instance = DeviceAppInfo(
        os: os,
        systemVersion: systemVersion,
        model: model,
        brand: brand,
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
}
