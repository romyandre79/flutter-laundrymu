import 'package:flutter/foundation.dart';
import 'package:kreatif_laundry_app/data/database/database_helper.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  Future<void> log(String type, String message) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('logs', {
        'type': type,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging to database: $e');
    }
    debugPrint('[$type] $message');
  }

  Future<void> logRequest(String endpoint, dynamic data) async {
    await log('REQUEST', '$endpoint: $data');
  }

  Future<void> logResponse(String name, dynamic data, {Object? error}) async {
    if (error != null) {
      await log('ERROR', '$name: $error');
    } else {
      await log('RESPONSE', '$name: $data');
    }
  }

  Future<List<Map<String, dynamic>>> getLogs({int limit = 100}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('logs', orderBy: 'created_at DESC', limit: limit);
  }

  Future<void> clearLogs() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('logs');
  }

  Future<String> getLogPath() async {
    return await DatabaseHelper.instance.getDbPath();
  }
}
