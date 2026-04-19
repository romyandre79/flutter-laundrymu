import 'package:flutter/foundation.dart';
import 'package:kreatif_laundrymu_app/data/database/database_helper.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  Future<void> log(String type, String message) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('logs', {
      'type': type,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
    debugPrint('[$type] $message');
  }

  Future<List<Map<String, dynamic>>> getLogs({int limit = 100}) async {
    final db = await DatabaseHelper.instance.database;
    return await db.query('logs', orderBy: 'created_at DESC', limit: limit);
  }

  Future<void> clearLogs() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('logs');
  }
}
