/// Error Logging Service for AD4x4 Mobile App
/// 
/// Captures and stores all app errors for debugging on devices where
/// console access is not available (Android/iOS production builds).
/// 
/// Features:
/// - Automatic error capture with Flutter error handlers
/// - Persistent storage using SharedPreferences
/// - Maximum 100 error logs (auto-cleanup)
/// - Timestamp and stack trace recording
/// - Export functionality for sharing logs
/// - Clear all logs functionality
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single error log entry
class ErrorLogEntry {
  final String timestamp;
  final String message;
  final String? stackTrace;
  final String type; // 'flutter_error', 'exception', 'network', 'custom'
  final String? context; // Screen/feature where error occurred

  ErrorLogEntry({
    required this.timestamp,
    required this.message,
    this.stackTrace,
    required this.type,
    this.context,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'message': message,
        'stackTrace': stackTrace,
        'type': type,
        'context': context,
      };

  factory ErrorLogEntry.fromJson(Map<String, dynamic> json) => ErrorLogEntry(
        timestamp: json['timestamp'] as String,
        message: json['message'] as String,
        stackTrace: json['stackTrace'] as String?,
        type: json['type'] as String,
        context: json['context'] as String?,
      );

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.writeln('[$timestamp] [$type]');
    if (context != null) buffer.writeln('Context: $context');
    buffer.writeln('Message: $message');
    if (stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(stackTrace);
    }
    return buffer.toString();
  }
}

/// Error Log Service - Singleton pattern
class ErrorLogService {
  static final ErrorLogService _instance = ErrorLogService._internal();
  factory ErrorLogService() => _instance;
  ErrorLogService._internal();

  static const String _kErrorLogsKey = 'error_logs';
  static const int _kMaxLogs = 100;

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  /// Initialize the service (call in main.dart)
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _isInitialized = true;
      if (kDebugMode) {
        debugPrint('✅ [ErrorLogService] Initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ErrorLogService] Initialization failed: $e');
      }
    }
  }

  /// Log an error
  Future<void> logError({
    required String message,
    String? stackTrace,
    String type = 'exception',
    String? context,
  }) async {
    if (!_isInitialized || _prefs == null) {
      // Try to initialize if not already done
      await init();
      if (!_isInitialized) return;
    }

    try {
      final entry = ErrorLogEntry(
        timestamp: DateTime.now().toIso8601String(),
        message: message,
        stackTrace: stackTrace,
        type: type,
        context: context,
      );

      // Get existing logs
      final logs = await getAllLogs();

      // Add new log at the beginning (most recent first)
      logs.insert(0, entry);

      // Keep only last N logs
      if (logs.length > _kMaxLogs) {
        logs.removeRange(_kMaxLogs, logs.length);
      }

      // Save back to storage
      final jsonList = logs.map((e) => jsonEncode(e.toJson())).toList();
      await _prefs!.setStringList(_kErrorLogsKey, jsonList);

      if (kDebugMode) {
        debugPrint('📝 [ErrorLogService] Error logged: $type - $message');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ErrorLogService] Failed to log error: $e');
      }
    }
  }

  /// Get all error logs
  Future<List<ErrorLogEntry>> getAllLogs() async {
    if (!_isInitialized || _prefs == null) return [];

    try {
      final jsonList = _prefs!.getStringList(_kErrorLogsKey) ?? [];
      return jsonList
          .map((jsonStr) {
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              return ErrorLogEntry.fromJson(json);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ [ErrorLogService] Failed to parse log: $e');
              }
              return null;
            }
          })
          .whereType<ErrorLogEntry>()
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ErrorLogService] Failed to get logs: $e');
      }
      return [];
    }
  }

  /// Clear all error logs
  Future<void> clearAllLogs() async {
    if (!_isInitialized || _prefs == null) return;

    try {
      await _prefs!.remove(_kErrorLogsKey);
      if (kDebugMode) {
        debugPrint('🗑️ [ErrorLogService] All logs cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [ErrorLogService] Failed to clear logs: $e');
      }
    }
  }

  /// Export logs as formatted string (for sharing/copying)
  Future<String> exportLogs() async {
    final logs = await getAllLogs();
    if (logs.isEmpty) {
      return 'No error logs available.';
    }

    final buffer = StringBuffer();
    buffer.writeln('AD4x4 Error Logs Export');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Errors: ${logs.length}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    for (var i = 0; i < logs.length; i++) {
      buffer.writeln('Error #${i + 1}');
      buffer.writeln(logs[i].toString());
      buffer.writeln('-' * 60);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Get error count
  Future<int> getErrorCount() async {
    final logs = await getAllLogs();
    return logs.length;
  }

  /// Get recent errors (last N)
  Future<List<ErrorLogEntry>> getRecentLogs(int count) async {
    final logs = await getAllLogs();
    return logs.take(count).toList();
  }

  /// Get errors by type
  Future<List<ErrorLogEntry>> getLogsByType(String type) async {
    final logs = await getAllLogs();
    return logs.where((log) => log.type == type).toList();
  }
}
