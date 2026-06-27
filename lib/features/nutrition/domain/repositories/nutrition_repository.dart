import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../entities/food_item.dart';
import '../entities/meal_log.dart';

abstract class NutritionRepository {
  Future<List<FoodItem>> getFoodDatabase();
  Future<List<MealLog>> getMealLogs(String athleteId, DateTime date);
  Future<void> saveMealLog(MealLog log);
}

class NutritionRepositoryImpl implements NutritionRepository {
  static const String _boxName = 'nutrition_logs_box';
  List<FoodItem>? _cachedFoodDb;

  NutritionRepositoryImpl();

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  @override
  Future<List<FoodItem>> getFoodDatabase() async {
    if (_cachedFoodDb != null) return _cachedFoodDb!;

    final String response = await rootBundle.loadString('assets/nutrition/food_database.json');
    final Map<String, dynamic> data = json.decode(response);
    final List<dynamic> items = data['items'];
    
    _cachedFoodDb = items.map((json) => FoodItem.fromJson(json)).toList();
    return _cachedFoodDb!;
  }

  @override
  Future<List<MealLog>> getMealLogs(String athleteId, DateTime date) async {
    final box = Hive.box<String>(_boxName);
    final foodList = await getFoodDatabase();
    final foodMap = {for (var f in foodList) f.id: f};

    final List<MealLog> logs = [];
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    for (final key in box.keys) {
      if (key.toString().startsWith('${athleteId}_$dateStr')) {
        final jsonStr = box.get(key);
        if (jsonStr != null) {
          final jsonMap = json.decode(jsonStr);
          logs.add(MealLog.fromJson(jsonMap, foodMap));
        }
      }
    }
    return logs;
  }

  @override
  Future<void> saveMealLog(MealLog log) async {
    final box = Hive.box<String>(_boxName);
    final dateStr = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}';
    final key = '${log.athleteId}_${dateStr}_${log.id}';
    
    await box.put(key, json.encode(log.toJson()));
  }
}
