import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:hive_flutter/hive_flutter.dart';

class HiveCacheService {
  // TODO(TechDebt): Currently caching data as raw JSON strings. 
  // For better scalability and structural integrity, we should register Hive 
  // TypeAdapters for our domain models instead of serializing to strings.
  static const String _athleteBox = 'athletes';
  static const String _logBox = 'daily_logs';
  static const String _logIndexBox = 'log_indices';

  static Future<void> init() async {
    try {
      if (kIsWeb) {
        Hive.init('hive_data');
      } else {
        await Hive.initFlutter();
      }
      await Hive.openBox<String>(_athleteBox);
      await Hive.openBox<String>(_logBox);
      await Hive.openBox<String>(_logIndexBox);
    } catch (e) {
      debugPrint('[HiveCache] Init error: $e');
    }
  }

  static Future<void> cacheAthletes(String parentId, List<Map<String, dynamic>> athletes) async {
    final box = Hive.box<String>(_athleteBox);
    final data = athletes.map((a) => jsonEncode(a)).toList();
    await box.put(parentId, jsonEncode(data));
  }

  static List<Map<String, dynamic>>? getCachedAthletes(String parentId) {
    final box = Hive.box<String>(_athleteBox);
    final raw = box.get(parentId);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> cacheLogs(String athleteId, List<Map<String, dynamic>> logs) async {
    final box = Hive.box<String>(_logBox);
    final data = logs.map((l) => jsonEncode(l)).toList();
    await box.put(athleteId, jsonEncode(data));
  }

  static List<Map<String, dynamic>>? getCachedLogs(String athleteId) {
    final box = Hive.box<String>(_logBox);
    final raw = box.get(athleteId);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  static Future<void> cacheSingleLog(String athleteId, String date, Map<String, dynamic> log) async {
    final indexBox = Hive.box<String>(_logIndexBox);
    final key = '${athleteId}_$date';
    await indexBox.put(key, jsonEncode(log));
  }

  static Map<String, dynamic>? getCachedLogByDate(String athleteId, String date) {
    final indexBox = Hive.box<String>(_logIndexBox);
    final raw = indexBox.get('${athleteId}_$date');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  static Future<void> clearAthleteCache(String parentId) async {
    final box = Hive.box<String>(_athleteBox);
    await box.delete(parentId);
  }

  static Future<void> clearLogCache(String athleteId) async {
    final box = Hive.box<String>(_logBox);
    await box.delete(athleteId);
  }

  static Future<void> clearAll() async {
    await Hive.box<String>(_athleteBox).clear();
    await Hive.box<String>(_logBox).clear();
    await Hive.box<String>(_logIndexBox).clear();
  }
}
