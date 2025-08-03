import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';

enum LogLevel {
  debug(0, 500),
  info(1, 800),
  log(2, 800),
  warn(3, 900),
  error(4, 1000),
  silent(5, 0);

  const LogLevel(this.value, this.developerLogLevel);

  final int value;
  final int developerLogLevel;
}

class Logger {
  Logger._internal() : _client = HttpClient();

  static Logger? _instance;

  final HttpClient _client;

  Json? remoteConfig;

  LogLevel localLevel = LogLevel.info;

  LogLevel remoteLevel = LogLevel.error;

  factory Logger() {
    return _instance ??= Logger._internal();
  }

  static void debug(String message) {
    final instance = Logger();
    instance.logLocal(LogLevel.debug, message);
    instance.logRemote(LogLevel.debug, message);
  }

  static void info(String message) {
    final instance = Logger();
    instance.logLocal(LogLevel.info, message);
    instance.logRemote(LogLevel.info, message);
  }

  static void log(String message) {
    final instance = Logger();
    instance.logLocal(LogLevel.log, message);
    instance.logRemote(LogLevel.log, message);
  }

  static void warn(String message) {
    final instance = Logger();
    instance.logLocal(LogLevel.warn, message);
    instance.logRemote(LogLevel.warn, message);
  }

  static void error(String message) {
    final instance = Logger();
    instance.logLocal(LogLevel.error, message);
    instance.logRemote(LogLevel.error, message);
  }

  static void setLocalLogLevel(LogLevel level) {
    final instance = Logger();
    instance.localLevel = level;
  }

  static void setRemoteLogLevel(LogLevel level) {
    final instance = Logger();
    instance.remoteLevel = level;
  }

  static void setRemoteConfig(Json config) {
    final instance = Logger();
    instance.remoteConfig = config;
  }

  bool shouldLog(LogLevel level, LogLevel targetLevel) {
    if (targetLevel == LogLevel.silent) {
      return false;
    }

    return level.value >= targetLevel.value;
  }

  void logLocal(LogLevel level, String message) {
    if (!shouldLog(level, localLevel)) {
      return;
    }

    developer.log(
      message,
      name: 'Kontext',
      level: level.developerLogLevel,
    );
  }

  Future<void> logRemote(LogLevel level, String message) async {
    if (!shouldLog(level, remoteLevel) || remoteConfig == null) {
      return;
    }

    try {
      await _client.post('/log', body: {
        'level': level.name,
        'message': message,
        ...(remoteConfig ?? {}),
      });
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Failed to log to remote: $e',
          name: 'Kontext',
          level: 1000,
        );
      }
    }
  }
}
