import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

class DailyLogEntity extends Equatable {
  final String id;
  final String athleteId;
  final String date;
  final int? restingHR;
  final double? sleepHours;
  final SleepQuality? sleepQuality;
  final int? wellnessScore;
  final NutritionData? nutrition;
  final TrainingData? training;
  final int? stressScore;
  final double? acwr;
  final DateTime createdAt;

  const DailyLogEntity({
    required this.id,
    required this.athleteId,
    required this.date,
    this.restingHR,
    this.sleepHours,
    this.sleepQuality,
    this.wellnessScore,
    this.nutrition,
    this.training,
    this.stressScore,
    this.acwr,
    required this.createdAt,
  });

  bool get isComplete =>
      restingHR != null &&
      sleepHours != null &&
      sleepQuality != null &&
      wellnessScore != null &&
      nutrition != null &&
      training != null;

  DailyLogEntity copyWith({
    String? id,
    String? athleteId,
    String? date,
    int? restingHR,
    double? sleepHours,
    SleepQuality? sleepQuality,
    int? wellnessScore,
    NutritionData? nutrition,
    TrainingData? training,
    int? stressScore,
    double? acwr,
    DateTime? createdAt,
  }) {
    return DailyLogEntity(
      id: id ?? this.id,
      athleteId: athleteId ?? this.athleteId,
      date: date ?? this.date,
      restingHR: restingHR ?? this.restingHR,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      wellnessScore: wellnessScore ?? this.wellnessScore,
      nutrition: nutrition ?? this.nutrition,
      training: training ?? this.training,
      stressScore: stressScore ?? this.stressScore,
      acwr: acwr ?? this.acwr,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        athleteId,
        date,
        restingHR,
        sleepHours,
        sleepQuality,
        wellnessScore,
        nutrition,
        training,
        stressScore,
        acwr,
        createdAt,
      ];
}

class NutritionData extends Equatable {
  final bool breakfast;
  final bool lunch;
  final bool dinner;
  final bool snack;
  final double hydrationLiters;
  final bool proteinSufficient;

  const NutritionData({
    this.breakfast = false,
    this.lunch = false,
    this.dinner = false,
    this.snack = false,
    this.hydrationLiters = 0,
    this.proteinSufficient = false,
  });

  int get mealsCount => [breakfast, lunch, dinner, snack].where((m) => m).length;
  double get mealsPercentage => (mealsCount / 4) * 100;

  NutritionData copyWith({
    bool? breakfast,
    bool? lunch,
    bool? dinner,
    bool? snack,
    double? hydrationLiters,
    bool? proteinSufficient,
  }) {
    return NutritionData(
      breakfast: breakfast ?? this.breakfast,
      lunch: lunch ?? this.lunch,
      dinner: dinner ?? this.dinner,
      snack: snack ?? this.snack,
      hydrationLiters: hydrationLiters ?? this.hydrationLiters,
      proteinSufficient: proteinSufficient ?? this.proteinSufficient,
    );
  }

  @override
  List<Object?> get props => [breakfast, lunch, dinner, snack, hydrationLiters, proteinSufficient];
}

class TrainingData extends Equatable {
  final bool trained;
  final int? durationMinutes;
  final TrainingType? type;
  final int? rpe;
  final int? distanceMeters;

  const TrainingData({
    this.trained = false,
    this.durationMinutes,
    this.type,
    this.rpe,
    this.distanceMeters,
  });

  TrainingData copyWith({
    bool? trained,
    int? durationMinutes,
    TrainingType? type,
    int? rpe,
    int? distanceMeters,
    bool clearDuration = false,
    bool clearType = false,
    bool clearRpe = false,
    bool clearDistance = false,
  }) {
    return TrainingData(
      trained: trained ?? this.trained,
      durationMinutes: clearDuration ? null : (durationMinutes ?? this.durationMinutes),
      type: clearType ? null : (type ?? this.type),
      rpe: clearRpe ? null : (rpe ?? this.rpe),
      distanceMeters: clearDistance ? null : (distanceMeters ?? this.distanceMeters),
    );
  }

  int? get trainingLoad {
    if (trained && durationMinutes != null && rpe != null) {
      return durationMinutes! * rpe!;
    }
    return null;
  }

  @override
  List<Object?> get props => [trained, durationMinutes, type, rpe, distanceMeters];
}
