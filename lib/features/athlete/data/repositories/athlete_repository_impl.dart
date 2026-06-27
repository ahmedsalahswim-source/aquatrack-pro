import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/services/hive_cache_service.dart';
import 'package:aquatrack_pro/features/athlete/data/datasources/athlete_remote_datasource.dart';
import 'package:aquatrack_pro/features/athlete/data/models/athlete_model.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/repositories/athlete_repository.dart';

class AthleteRepositoryImpl implements AthleteRepository {
  final AthleteRemoteDataSource remoteDataSource;

  AthleteRepositoryImpl({required this.remoteDataSource});

  @override
  Stream<Either<Failure, List<AthleteEntity>>> watchAthletes(String parentId) {
    return remoteDataSource.watchAthletes(parentId).map(
      (models) => Right<Failure, List<AthleteEntity>>(models),
    );
  }

  @override
  Future<Either<Failure, AthleteEntity>> getAthlete(String athleteId) async {
    try {
      final athlete = await remoteDataSource.getAthlete(athleteId);
      return Right(athlete);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AthleteEntity>> addAthlete(AthleteEntity athlete) async {
    try {
      final model = AthleteModel(
        id: athlete.id,
        parentId: athlete.parentId,
        name: athlete.name,
        birthDate: athlete.birthDate,
        gender: athlete.gender,
        swimLevel: athlete.swimLevel,
        weightKg: athlete.weightKg,
        heightCm: athlete.heightCm,
        targetWeeklyHours: athlete.targetWeeklyHours,
        restingHRBaseline: athlete.restingHRBaseline,
        sleepBaseline: athlete.sleepBaseline,
        photoUrl: athlete.photoUrl,
        isActive: athlete.isActive,
        createdAt: athlete.createdAt,
      );
      final result = await remoteDataSource.addAthlete(model);
      await HiveCacheService.clearAthleteCache(athlete.parentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AthleteEntity>> updateAthlete(AthleteEntity athlete) async {
    try {
      final model = AthleteModel(
        id: athlete.id,
        parentId: athlete.parentId,
        name: athlete.name,
        birthDate: athlete.birthDate,
        gender: athlete.gender,
        swimLevel: athlete.swimLevel,
        weightKg: athlete.weightKg,
        heightCm: athlete.heightCm,
        targetWeeklyHours: athlete.targetWeeklyHours,
        restingHRBaseline: athlete.restingHRBaseline,
        sleepBaseline: athlete.sleepBaseline,
        photoUrl: athlete.photoUrl,
        isActive: athlete.isActive,
        createdAt: athlete.createdAt,
      );
      final result = await remoteDataSource.updateAthlete(model);
      await HiveCacheService.clearAthleteCache(athlete.parentId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAthlete(String athleteId) async {
    try {
      await remoteDataSource.deleteAthlete(athleteId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
