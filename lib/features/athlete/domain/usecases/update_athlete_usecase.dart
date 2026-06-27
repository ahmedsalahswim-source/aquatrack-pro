import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/repositories/athlete_repository.dart';

class UpdateAthleteUseCase {
  final AthleteRepository repository;

  UpdateAthleteUseCase({required this.repository});

  Future<Either<Failure, AthleteEntity>> call(AthleteEntity athlete) {
    return repository.updateAthlete(athlete);
  }
}
