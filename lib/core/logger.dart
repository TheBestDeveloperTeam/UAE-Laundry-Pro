import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class LogEntry {
  final DateTime timestamp;
  final String level;
  final String tag;
  final String message;
  final String? error;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.error,
  });

  String formatted() {
    final timeStr = "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}.${timestamp.millisecond.toString().padLeft(3, '0')}";
    final errStr = error != null ? " | Error: $error" : "";
    return "[$timeStr] [$level] [$tag] $message$errStr";
  }
}

/// Centralized logger for LaundryPro UAE Desktop client.
/// Provides leveled logging, structured tags, and a live in-memory circular buffer for UI extraction.
class AppLogger {
  AppLogger._();

  static final ValueNotifier<List<LogEntry>> logBuffer = ValueNotifier<List<LogEntry>>([]);
  static const int _maxBufferSize = 300;

  static void _appendToBuffer(String level, String tag, String message, Object? error) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      error: error?.toString(),
    );
    final updated = List<LogEntry>.from(logBuffer.value)..add(entry);
    if (updated.length > _maxBufferSize) {
      updated.removeAt(0);
    }
    logBuffer.value = updated;
  }

  static void debug(String message, {String tag = 'App', Object? error, StackTrace? stackTrace}) {
    _appendToBuffer('DEBUG', tag, message, error);
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
    _appendToBuffer('INFO', tag, message, null);
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
    _appendToBuffer('WARN', tag, message, error);
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
    _appendToBuffer('ERROR', tag, message, error);
    developer.log(
      '❌ $message',
      name: 'LaundryPro.$tag',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
