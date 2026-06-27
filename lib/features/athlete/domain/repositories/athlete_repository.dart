import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';

abstract class AthleteRepository {
  Stream<Either<Failure, List<AthleteEntity>>> watchAthletes(String parentId);
  Future<Either<Failure, AthleteEntity>> getAthlete(String athleteId);
  Future<Either<Failure, AthleteEntity>> addAthlete(AthleteEntity athlete);
  Future<Either<Failure, AthleteEntity>> updateAthlete(AthleteEntity athlete);
  Future<Either<Failure, void>> deleteAthlete(String athleteId);
}
