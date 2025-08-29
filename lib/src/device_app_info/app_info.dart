import 'dart:io' show Platform;
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
  final bool? startTime;

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

    return AppInfo._(
      appBundleId: appBundleId,
      appVersion: appVersion,
      appStoreUrl: appStoreUrl,
      firstInstallTime: null, // TODO:
      lastUpdateTime: null, // TODO:
      startTime: null, // TODO:
    );
  }
}
