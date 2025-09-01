import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kontext_flutter_sdk/src/device_app_info/app_info.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_audio.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_hardware.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_network.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_power.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/operation_system.dart';
import 'package:kontext_flutter_sdk/src/device_app_info/device_screen.dart';
import 'package:kontext_flutter_sdk/src/services/logger.dart';

class DeviceAppInfo {
  DeviceAppInfo({
    required this.appInfo,
    required this.os,
    required this.hardware,
    required this.power,
    required this.network,
  });

  static DeviceAppInfo? _instance;
  static Future<DeviceAppInfo>? _loading;

  final AppInfo appInfo;
  final OperationSystem os;
  final DeviceHardware hardware;
  final DevicePower power;
  final DeviceNetwork network;

  Map<String, dynamic> toJson({required DeviceScreen screen, required DeviceAudio audio}) {
    return {
      'os': os.toJson(),
      'hardware': hardware.toJson(),
      'screen': screen.toJson(),
      'power': power.toJson(),
      'audio': audio.toJson(),
      'network': network.toJson(),
    };
  }

  Future<Map<String, dynamic>> toJsonFresh() async {
    final screen = DeviceScreen.init();
    final audio = await DeviceAudio.init();
    return toJson(screen: screen, audio: audio);
  }

  factory DeviceAppInfo.empty() => DeviceAppInfo(
        appInfo: AppInfo.empty(),
        hardware: DeviceHardware.empty(),
        os: OperationSystem.empty(),
        power: DevicePower.empty(),
        network: DeviceNetwork.empty(),
      );

  static Future<DeviceAppInfo> init({String? iosAppStoreId}) async {
    if (_instance != null) {
      return Future.value(_instance!);
    }

    return _loading ??= _initInternal(iosAppStoreId: iosAppStoreId);
  }

  static Future<DeviceAppInfo> _initInternal({String? iosAppStoreId}) async {
    final emptyInstance = DeviceAppInfo.empty();

    try {
      if (kIsWeb) {
        return _instance = emptyInstance;
      }

      final dispatcher = PlatformDispatcher.instance;
      final appInfo = await AppInfo.init(iosAppStoreId: iosAppStoreId);
      final hardware = await DeviceHardware.init(dispatcher);
      final os = await OperationSystem.init(dispatcher);
      final power = await DevicePower.init(dispatcher);
      final network = await DeviceNetwork.init();

      return _instance = DeviceAppInfo(
        appInfo: appInfo,
        hardware: hardware,
        os: os,
        power: power,
        network: network,
      );
    } catch (e, stack) {
      Logger.exception(e, stack);
      return _instance = emptyInstance;
    } finally {
      _loading = null;
    }
  }
}
