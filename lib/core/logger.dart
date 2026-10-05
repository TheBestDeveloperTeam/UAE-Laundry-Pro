import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Centralized logger for LaundryPro UAE Desktop client.
/// Provides leveled logging, structured tags, and debug console output.
class AppLogger {
  AppLogger._();

  static void debug(String message, {String tag = 'App', Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'LaundryPro.$tag',
        level: 500,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  static void info(String message, {String tag = 'App'}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: 'LaundryPro.$tag',
        level: 800,
      );
    }
  }

  static void warning(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '⚠️ $message',
      name: 'LaundryPro.$tag',
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void error(
    String message, {
    String tag = 'App',
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      '❌ $message',
      name: 'LaundryPro.$tag',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
