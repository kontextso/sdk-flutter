import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:kontext_flutter_sdk/src/services/http_client.dart';

/// Log levels for the logger.
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
    instance._logLocal(LogLevel.debug, message);
    instance._logRemote(LogLevel.debug, message);
  }

  static void info(String message) {
    final instance = Logger();
    instance._logLocal(LogLevel.info, message);
    instance._logRemote(LogLevel.info, message);
  }

  static void log(String message) {
    final instance = Logger();
    instance._logLocal(LogLevel.log, message);
    instance._logRemote(LogLevel.log, message);
  }

  static void warn(String message) {
    final instance = Logger();
    instance._logLocal(LogLevel.warn, message);
    instance._logRemote(LogLevel.warn, message);
  }

  static void error(String message) {
    final instance = Logger();
    instance._logLocal(LogLevel.error, message);
    instance._logRemote(LogLevel.error, message);
  }

  static void exception(Object exception, [StackTrace? stack]) {
    final instance = Logger();
    instance._logLocal(LogLevel.error, 'Exception: ${exception.toString()}', error: exception, stackTrace: stack);
    instance._logRemote(LogLevel.error, exception.toString());
    instance._logException(exception, stack: stack);
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

  void _logLocal(LogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
    if (!shouldLog(level, localLevel)) {
      return;
    }

    developer.log(
      message,
      name: 'Kontext',
      level: level.developerLogLevel,
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> _logRemote(LogLevel level, String message) async {
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

  Future<void> _logException(Object exception, {StackTrace? stack}) async {
    try {
      await _client.post('/error', body: {
        'error': exception.toString(),
        'stack': stack?.toString() ?? '',
        'additionalData': remoteConfig ?? {},
      });
    } catch (e) {
      if (kDebugMode) {
        developer.log(
          'Failed to log exception to remote: $e',
          name: 'Kontext',
          level: 1000,
        );
      }
    }
  }
}
