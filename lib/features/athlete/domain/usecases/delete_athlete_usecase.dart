import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/athlete/domain/repositories/athlete_repository.dart';

class DeleteAthleteUseCase {
  final AthleteRepository repository;

  DeleteAthleteUseCase({required this.repository});

  Future<Either<Failure, void>> call(String athleteId) {
    return repository.deleteAthlete(athleteId);
  }
}
