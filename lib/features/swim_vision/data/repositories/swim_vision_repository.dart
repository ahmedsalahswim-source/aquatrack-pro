import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:aquatrack_pro/features/swim_vision/domain/entities/swim_analysis_result.dart';

class SwimVisionRepository {
  static const String _boxName = 'swim_vision';
  static const String _historyKey = 'history';
  static const int _maxHistory = 10;

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box(_boxName);
    return await Hive.openBox(_boxName);
  }

  Future<void> saveResult(SwimAnalysisResult result) async {
    try {
      final box = await _getBox();
      final history = _loadHistory(box);
      history.insert(0, result.toJson());
      if (history.length > _maxHistory) {
        history.removeRange(_maxHistory, history.length);
      }
      await box.put(_historyKey, history.map((e) => jsonEncode(e)).toList());
    } catch (e) {
      debugPrint('[SwimVisionRepo] Save error: $e');
    }
  }

  Future<List<SwimAnalysisResult>> getHistory() async {
    try {
      final box = await _getBox();
      final data = _loadHistory(box);
      return data.map((j) => SwimAnalysisResult.fromJson(j)).toList();
    } catch (e) {
      debugPrint('[SwimVisionRepo] Load error: $e');
      return [];
    }
  }

  Future<void> clearHistory() async {
    try {
      final box = await _getBox();
      await box.put(_historyKey, []);
    } catch (e) {
      debugPrint('[SwimVisionRepo] Clear error: $e');
    }
  }

  List<Map<String, dynamic>> _loadHistory(Box box) {
    final raw = box.get(_historyKey, defaultValue: <String>[]);
    if (raw is! List) return [];
    return raw
        .map((e) {
          try {
            final decoded = jsonDecode(e as String);
            return decoded as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }
}
