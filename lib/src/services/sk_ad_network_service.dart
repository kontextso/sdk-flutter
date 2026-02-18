import 'dart:io';

import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import 'package:kontext_flutter_sdk/src/services/logger.dart' show Logger;

class SKAdNetwork {
  SKAdNetwork._();

  static const MethodChannel _channel = MethodChannel('kontext_flutter_sdk/sk_ad_network');

  static bool _impressionReady = false;

  static Future<bool> initImpression(Map<String, dynamic> params) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod('initImpression', params);
      final success = result == true;
      _impressionReady = success;
      Logger.debug('SKAdNetwork impression initialized: $success');
      return success;
    } on PlatformException catch (e) {
      _impressionReady = false;
      Logger.exception('Native error initializing SKAdNetwork impression: ${e.code} - ${e.message}', StackTrace.current);
      return false;
    } catch (e, stack) {
      _impressionReady = false;
      Logger.exception('Error initializing SKAdNetwork impression: $e', stack);
      return false;
    }
  }

  static Future<void> startImpression() async {
    if (!Platform.isIOS || !_impressionReady) return;

    try {
      final result = await _channel.invokeMethod('startImpression');
      Logger.debug('SKAdNetwork impression started: $result');
    } on PlatformException catch (e) {
      Logger.exception('Native error starting SKAdNetwork impression: ${e.code} - ${e.message}', StackTrace.current);
    } catch (e, stack) {
      Logger.exception('Error starting SKAdNetwork impression: $e', stack);
    }
  }

  static Future<void> endImpression() async {
    if (!Platform.isIOS || !_impressionReady) return;

    try {
      final result = await _channel.invokeMethod('endImpression');
      Logger.debug('SKAdNetwork impression ended: $result');
    } on PlatformException catch (e) {
      Logger.exception('Native error ending SKAdNetwork impression: ${e.code} - ${e.message}', StackTrace.current);
    } catch (e, stack) {
      Logger.exception('Error ending SKAdNetwork impression: $e', stack);
    }
  }

  static Future<void> dispose() async {
    _impressionReady = false;

    if (!Platform.isIOS) return;

    try {
      final result = await _channel.invokeMethod('dispose');
      Logger.debug('SKAdNetwork disposed: $result');
    } on PlatformException catch (e) {
      Logger.exception('Native error disposing SKAdNetwork: ${e.code} - ${e.message}', StackTrace.current);
    } catch (e, stack) {
      Logger.exception('Error disposing SKAdNetwork: $e', stack);
    }
  }
}