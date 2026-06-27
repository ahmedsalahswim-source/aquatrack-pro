import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'food_item.dart';

enum MealType { breakfast, lunch, dinner, snack, preWorkout, postWorkout }

class MealEntry extends Equatable {
  final String id;
  final FoodItem food;
  final double amountInGrams;

  MealEntry({
    String? id,
    required this.food,
    required this.amountInGrams,
  }) : id = id ?? const Uuid().v4();

  double get calories => (food.calories * amountInGrams) / 100.0;
  double get protein => (food.proteinG * amountInGrams) / 100.0;
  double get carbs => (food.carbsG * amountInGrams) / 100.0;
  double get fat => (food.fatG * amountInGrams) / 100.0;

  factory MealEntry.fromJson(Map<String, dynamic> json, FoodItem food) {
    return MealEntry(
      id: json['id'] as String,
      food: food,
      amountInGrams: (json['amount_in_grams'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food_id': food.id,
      'amount_in_grams': amountInGrams,
    };
  }

  @override
  List<Object?> get props => [id, food, amountInGrams];
}

class MealLog extends Equatable {
  final String id;
  final String athleteId;
  final DateTime date;
  final MealType mealType;
  final List<MealEntry> entries;

  MealLog({
    String? id,
    required this.athleteId,
    required this.date,
    required this.mealType,
    this.entries = const [],
  }) : id = id ?? const Uuid().v4();

  double get totalCalories => entries.fold(0, (sum, e) => sum + e.calories);
  double get totalProtein => entries.fold(0, (sum, e) => sum + e.protein);
  double get totalCarbs => entries.fold(0, (sum, e) => sum + e.carbs);
  double get totalFat => entries.fold(0, (sum, e) => sum + e.fat);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'athlete_id': athleteId,
      'date': date.toIso8601String(),
      'meal_type': mealType.name,
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }

  factory MealLog.fromJson(Map<String, dynamic> json, Map<String, FoodItem> foodMap) {
    final entriesList = (json['entries'] as List).map((e) {
      final foodId = e['food_id'] as String;
      final food = foodMap[foodId];
      if (food == null) throw Exception('Food item not found: $foodId');
      return MealEntry.fromJson(e, food);
    }).toList();

    return MealLog(
      id: json['id'] as String,
      athleteId: json['athlete_id'] as String,
      date: DateTime.parse(json['date'] as String),
      mealType: MealType.values.firstWhere((e) => e.name == json['meal_type']),
      entries: entriesList,
    );
  }

  MealLog copyWith({
    String? id,
    String? athleteId,
    DateTime? date,
    MealType? mealType,
    List<MealEntry>? entries,
  }) {
    return MealLog(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      date: date ?? this.date,
      mealType: mealType ?? this.mealType,
      entries: entries ?? this.entries,
    );
  }

  @override
  List<Object?> get props => [id, athleteId, date, mealType, entries];
}
