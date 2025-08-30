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
    this.appInfo,
    this.hardware,
    this.os,
    this.screen,
    this.power,
    this.audio,
    this.network,
  });

  static DeviceAppInfo? _instance;
  static Future<DeviceAppInfo>? _loading;

  final AppInfo? appInfo;
  final DeviceHardware? hardware;
  final OperationSystem? os;
  final DeviceScreen? screen;
  final DevicePower? power;
  final DeviceAudio? audio;
  final DeviceNetwork? network;

  Map<String, dynamic> toJson() {
    return {

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

      final dispatcher = PlatformDispatcher.instance;
      final appInfo = await AppInfo.init(iosAppStoreId: iosAppStoreId);
      final hardware = await DeviceHardware.init(dispatcher);
      final os = await OperationSystem.init(dispatcher);
      final screen = await DeviceScreen.init(dispatcher);
      final power = await DevicePower.init(dispatcher);
      final audio = await DeviceAudio.init();
      // final network = await DeviceNetwork.init();


      return _instance = DeviceAppInfo(
        appInfo: appInfo,
        hardware: hardware,
        os: os,
        screen: screen,
        power: power,
        audio: audio,
        // network: network,
      );
    } catch (e, stack) {
      Logger.exception(e, stack);
      return _instance = DeviceAppInfo();
    } finally {
      _loading = null;
    }
  }
}
