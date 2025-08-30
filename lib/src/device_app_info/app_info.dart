import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;

class AppInfo {
  AppInfo._({
    required this.appBundleId,
    required this.appVersion,
    required this.appStoreUrl,
    required this.firstInstallTime,
    required this.lastUpdateTime,
    required this.startTime,
  });

  final String? appBundleId;
  final String? appVersion;
  final String? appStoreUrl;
  final int? firstInstallTime;
  final int? lastUpdateTime;
  final int? startTime;

  static const _ch = MethodChannel('kontext_flutter_sdk/app_info');

  Map<String, dynamic> toJson() => {
    'appBundleId': appBundleId,
    'appVersion': appVersion,
    'appStoreUrl': appStoreUrl,
    'firstInstallTime': firstInstallTime,
    'lastUpdateTime': lastUpdateTime,
    'startTime': startTime,
  };

  static Future<AppInfo> init({String? iosAppStoreId}) async {
    final appInfo = await PackageInfo.fromPlatform();

    String? appStoreUrl;
    final appBundleId = appInfo.packageName;
    final appVersion = '${appInfo.version}+${appInfo.buildNumber}';

    if (Platform.isIOS) {
      if (iosAppStoreId != null) {
        appStoreUrl = 'https://apps.apple.com/app/id$iosAppStoreId';
      }
    } else if (Platform.isAndroid) {
      appStoreUrl = 'https://play.google.com/store/apps/details?id=$appBundleId';
    }

    final installUpdate = await _getInstallAndUpdateTimes();
    final install = installUpdate.firstInstall;
    final lastUpdate = installUpdate.lastUpdate;
    final processStart = await _getProcessStartTime();

    return AppInfo._(
      appBundleId: appBundleId,
      appVersion: appVersion,
      appStoreUrl: appStoreUrl,
      firstInstallTime: install,
      lastUpdateTime: lastUpdate,
      startTime: processStart,
    );
  }

  static Future<({int? firstInstall, int? lastUpdate})> _getInstallAndUpdateTimes() async {
    int? firstInstall, lastUpdate;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final times = await _ch.invokeMapMethod('getInstallUpdateTimes');
        firstInstall = (times?['firstInstall'] as num?)?.toInt();
        lastUpdate  = (times?['lastUpdate']  as num?)?.toInt();
      } catch (e) {
        Logger.error(e.toString());
      }
    }
    return (firstInstall: firstInstall, lastUpdate: lastUpdate);
  }

  static Future<int?> _getProcessStartTime() async {
    int? processStart;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        processStart = await _ch.invokeMethod<int>('getProcessStartEpochMs');
      } catch (e) {
        Logger.error(e.toString());
      }
    }
    return processStart;
  }
}
