import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/services/hive_cache_service.dart';
import 'package:aquatrack_pro/features/daily_log/data/datasources/daily_log_remote_datasource.dart';
import 'package:aquatrack_pro/features/daily_log/data/models/daily_log_model.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

class DailyLogRepositoryImpl implements DailyLogRepository {
  final DailyLogRemoteDataSource remoteDataSource;

  DailyLogRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<DailyLogEntity>>> watchLogs(String athleteId) {
    return remoteDataSource.watchLogs(athleteId).map(
      (models) => Right<Failure, List<DailyLogEntity>>(models),
    );
  }

  @override
  Future<Either<Failure, DailyLogEntity?>> getLogByDate(
    String athleteId, String date) async {
    try {
      final log = await remoteDataSource.getLogByDate(athleteId, date);
      if (log != null) {
        final cacheData = log.toFirestore();
        cacheData['id'] = log.id;
        HiveCacheService.cacheSingleLog(athleteId, date, cacheData);
      }
      return Right(log);
    } catch (e) {
      final cached = HiveCacheService.getCachedLogByDate(athleteId, date);
      if (cached != null) {
        return Right(DailyLogModel(
          id: cached['id'] as String,
          athleteId: cached['athleteId'] as String,
          date: cached['date'] as String,
          restingHR: cached['restingHR'] as int?,
          sleepHours: (cached['sleepHours'] as num?)?.toDouble(),
          sleepQuality: cached['sleepQuality'] != null
              ? _parseSleepQuality(cached['sleepQuality'] as String)
              : null,
          wellnessScore: cached['wellnessScore'] as int?,
          nutrition: cached['nutrition'] != null ? _parseNutrition(cached['nutrition'] as Map<String, dynamic>) : null,
          training: cached['training'] != null ? _parseTraining(cached['training'] as Map<String, dynamic>) : null,
          stressScore: cached['stressScore'] as int?,
          acwr: (cached['acwr'] as num?)?.toDouble(),
          createdAt: DateTime.parse(cached['createdAt'] as String),
        ));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyLogEntity>> saveLog(DailyLogEntity log) async {
    try {
      final model = DailyLogModel(
        id: log.id,
        athleteId: log.athleteId,
        date: log.date,
        restingHR: log.restingHR,
        sleepHours: log.sleepHours,
        sleepQuality: log.sleepQuality,
        wellnessScore: log.wellnessScore,
        nutrition: log.nutrition,
        training: log.training,
        stressScore: log.stressScore,
        acwr: log.acwr,
        createdAt: log.createdAt,
      );
      final result = await remoteDataSource.saveLog(model);
      final cacheData = model.toFirestore();
      cacheData['id'] = model.id;
      HiveCacheService.cacheSingleLog(log.athleteId, log.date, cacheData);
      await HiveCacheService.clearLogCache(log.athleteId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyLogEntity>>> getLogsInRange(
    String athleteId, int days) async {
    try {
      final logs = await remoteDataSource.getLogsInRange(athleteId, days);
      final jsonList = logs.map((m) {
        final data = m.toFirestore();
        data['id'] = m.id;
        return data;
      }).toList();
      await HiveCacheService.cacheLogs(athleteId, jsonList);
      return Right(logs);
    } catch (e) {
      final cached = HiveCacheService.getCachedLogs(athleteId);
      if (cached != null) {
        final logs = cached.map((json) => DailyLogModel(
          id: json['id'] as String,
          athleteId: json['athleteId'] as String,
          date: json['date'] as String,
          restingHR: json['restingHR'] as int?,
          sleepHours: (json['sleepHours'] as num?)?.toDouble(),
          sleepQuality: json['sleepQuality'] != null
              ? _parseSleepQuality(json['sleepQuality'] as String)
              : null,
          wellnessScore: json['wellnessScore'] as int?,
          nutrition: json['nutrition'] != null ? _parseNutrition(json['nutrition'] as Map<String, dynamic>) : null,
          training: json['training'] != null ? _parseTraining(json['training'] as Map<String, dynamic>) : null,
          stressScore: json['stressScore'] as int?,
          acwr: (json['acwr'] as num?)?.toDouble(),
          createdAt: DateTime.parse(json['createdAt'] as String),
        ) as DailyLogEntity).toList();
        return Right(logs);
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  SleepQuality _parseSleepQuality(String value) {
    return SleepQuality.values.firstWhere(
      (e) => e.name == value,
      orElse: () => SleepQuality.good,
    );
  }

  NutritionData _parseNutrition(Map<String, dynamic> data) {
    return NutritionData(
      breakfast: data['breakfast'] as bool? ?? false,
      lunch: data['lunch'] as bool? ?? false,
      dinner: data['dinner'] as bool? ?? false,
      snack: data['snack'] as bool? ?? false,
      hydrationLiters: (data['hydrationLiters'] as num?)?.toDouble() ?? 0,
      proteinSufficient: data['proteinSufficient'] as bool? ?? false,
    );
  }

  TrainingData _parseTraining(Map<String, dynamic> data) {
    return TrainingData(
      trained: data['trained'] as bool? ?? false,
      durationMinutes: data['durationMinutes'] as int?,
      type: data['type'] != null
          ? TrainingType.values.firstWhere((e) => e.name == data['type'])
          : null,
      rpe: data['rpe'] as int?,
      distanceMeters: data['distanceMeters'] as int?,
    );
  }
}
