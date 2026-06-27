import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/repositories/athlete_repository.dart';

class WatchAthletesUseCase {
  final AthleteRepository repository;

  WatchAthletesUseCase({required this.repository});

  Stream<Either<Failure, List<AthleteEntity>>> call(String parentId) {
    return repository.watchAthletes(parentId);
  }
}
