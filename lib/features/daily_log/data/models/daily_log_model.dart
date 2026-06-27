import 'package:aquatrack_pro/core/errors/exceptions.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLogModel extends DailyLogEntity {
  const DailyLogModel({
    required super.id,
    required super.athleteId,
    required super.date,
    super.restingHR,
    super.sleepHours,
    super.sleepQuality,
    super.wellnessScore,
    super.nutrition,
    super.training,
    super.stressScore,
    super.acwr,
    required super.createdAt,
  });

  factory DailyLogModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    if (raw is! Map<String, dynamic>) {
      throw ServerException(message: 'Invalid Firestore document structure');
    }
    final data = raw;
    return DailyLogModel(
      id: doc.id,
      athleteId: data['athleteId'] as String? ?? '',
      date: data['date'] as String? ?? '',
      restingHR: data['restingHR'] as int?,
      sleepHours: (data['sleepHours'] as num?)?.toDouble(),
      sleepQuality: data['sleepQuality'] != null
          ? SleepQuality.values.firstWhere((e) => e.name == data['sleepQuality'])
          : null,
      wellnessScore: data['wellnessScore'] as int?,
      nutrition: data['nutrition'] != null
          ? NutritionData(
              breakfast: data['nutrition']['breakfast'] as bool? ?? false,
              lunch: data['nutrition']['lunch'] as bool? ?? false,
              dinner: data['nutrition']['dinner'] as bool? ?? false,
              snack: data['nutrition']['snack'] as bool? ?? false,
              hydrationLiters: (data['nutrition']['hydrationLiters'] as num?)?.toDouble() ?? 0,
              proteinSufficient: data['nutrition']['proteinSufficient'] as bool? ?? false,
            )
          : null,
      training: data['training'] != null
          ? TrainingData(
              trained: data['training']['trained'] as bool? ?? false,
              durationMinutes: data['training']['durationMinutes'] as int?,
              type: data['training']['type'] != null
                  ? TrainingType.values.firstWhere((e) => e.name == data['training']['type'])
                  : null,
              rpe: data['training']['rpe'] as int?,
              distanceMeters: data['training']['distanceMeters'] as int?,
            )
          : null,
      stressScore: data['stressScore'] as int?,
      acwr: (data['acwr'] as num?)?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'athleteId': athleteId,
      'date': date,
      'restingHR': restingHR,
      'sleepHours': sleepHours,
      'sleepQuality': sleepQuality?.name,
      'wellnessScore': wellnessScore,
      'nutrition': nutrition != null
          ? {
              'breakfast': nutrition!.breakfast,
              'lunch': nutrition!.lunch,
              'dinner': nutrition!.dinner,
              'snack': nutrition!.snack,
              'hydrationLiters': nutrition!.hydrationLiters,
              'proteinSufficient': nutrition!.proteinSufficient,
            }
          : null,
      'training': training != null
          ? {
              'trained': training!.trained,
              'durationMinutes': training!.durationMinutes,
              'type': training!.type?.name,
              'rpe': training!.rpe,
              'distanceMeters': training!.distanceMeters,
            }
          : null,
      'stressScore': stressScore,
      'acwr': acwr,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
