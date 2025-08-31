import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;

class AppInfo {
  AppInfo._({
    required this.bundleId,
    required this.version,
    required this.storeUrl,
    required this.firstInstallTime,
    required this.lastUpdateTime,
    required this.startTime,
  });

  final String bundleId;
  final String version;
  final String? storeUrl;
  final int firstInstallTime;
  final int lastUpdateTime;
  final int startTime;

  static const _ch = MethodChannel('kontext_flutter_sdk/app_info');

  factory AppInfo.empty() => AppInfo._(
        bundleId: '',
        version: '',
        storeUrl: null,
        firstInstallTime: 0,
        lastUpdateTime: 0,
        startTime: 0,
      );

  Map<String, dynamic> toJson() => {
        'bundleId': bundleId,
        'version': version,
        if (storeUrl != null) 'storeUrl': storeUrl,
        'firstInstallTime': firstInstallTime,
        'lastUpdateTime': lastUpdateTime,
        'startTime': startTime,
      };

  static Future<AppInfo> init({String? iosAppStoreId}) async {
    try {
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
        bundleId: appBundleId,
        version: appVersion,
        storeUrl: appStoreUrl,
        firstInstallTime: install ?? 0,
        lastUpdateTime: lastUpdate ?? 0,
        startTime: processStart ?? 0,
      );
    } catch (e) {
      Logger.error('Failed to get app info: $e');
      return AppInfo.empty();
    }
  }

  static Future<({int? firstInstall, int? lastUpdate})> _getInstallAndUpdateTimes() async {
    int? firstInstall, lastUpdate;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final times = await _ch.invokeMapMethod('getInstallUpdateTimes');
        firstInstall = (times?['firstInstall'] as num?)?.toInt();
        lastUpdate = (times?['lastUpdate'] as num?)?.toInt();
      } catch (e) {
        Logger.error('Failed to get install and update times: $e');
      }
    }
    return (firstInstall: firstInstall, lastUpdate: lastUpdate);
  }

  static Future<int?> _getProcessStartTime() async {
    int? processStart;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        return await _ch.invokeMethod<int>('getProcessStartEpochMs');
      } catch (e) {
        Logger.error('Failed to get process start time: $e');
      }
    }
    return processStart;
  }
}
