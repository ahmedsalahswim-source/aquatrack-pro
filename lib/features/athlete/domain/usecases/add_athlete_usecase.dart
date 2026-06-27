import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/repositories/athlete_repository.dart';

class AddAthleteUseCase {
  final AthleteRepository repository;

  AddAthleteUseCase({required this.repository});

  Future<Either<Failure, AthleteEntity>> call({
    required String parentId,
    required String name,
    required DateTime birthDate,
    required Gender gender,
    SwimLevel swimLevel = SwimLevel.beginner,
    double? weightKg,
    double? heightCm,
    double targetWeeklyHours = 6,
    int? restingHRBaseline,
    double? sleepBaseline,
    String? photoUrl,
  }) {
    final athlete = AthleteEntity(
      id: const Uuid().v4(),
      parentId: parentId,
      name: name,
      birthDate: birthDate,
      gender: gender,
      swimLevel: swimLevel,
      weightKg: weightKg,
      heightCm: heightCm,
      targetWeeklyHours: targetWeeklyHours,
      restingHRBaseline: restingHRBaseline,
      sleepBaseline: sleepBaseline,
      photoUrl: photoUrl,
      createdAt: DateTime.now(),
    );
    return repository.addAthlete(athlete);
  }
}
