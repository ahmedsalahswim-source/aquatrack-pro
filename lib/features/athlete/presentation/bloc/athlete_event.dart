part of 'athlete_bloc.dart';

abstract class AthleteEvent extends Equatable {
  const AthleteEvent();

  @override
  List<Object?> get props => [];
}

class WatchAthletesEvent extends AthleteEvent {
  final String parentId;

  const WatchAthletesEvent({required this.parentId});

  @override
  List<Object?> get props => [parentId];
}

class AddAthleteEvent extends AthleteEvent {
  final String parentId;
  final String name;
  final DateTime birthDate;
  final Gender gender;
  final SwimLevel swimLevel;
  final double? weightKg;
  final double? heightCm;
  final double targetWeeklyHours;
  final String? photoUrl;

  const AddAthleteEvent({
    required this.parentId,
    required this.name,
    required this.birthDate,
    required this.gender,
    this.swimLevel = SwimLevel.beginner,
    this.weightKg,
    this.heightCm,
    this.targetWeeklyHours = 6,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [parentId, name, birthDate, gender, swimLevel, photoUrl];
}

class UpdateAthleteEvent extends AthleteEvent {
  final AthleteEntity athlete;

  const UpdateAthleteEvent({required this.athlete});

  @override
  List<Object?> get props => [athlete];
}

class DeleteAthleteEvent extends AthleteEvent {
  final String athleteId;
  final String parentId;

  const DeleteAthleteEvent({required this.athleteId, required this.parentId});

  @override
  List<Object?> get props => [athleteId, parentId];
}

class SelectAthleteEvent extends AthleteEvent {
  final AthleteEntity athlete;

  const SelectAthleteEvent({required this.athlete});

  @override
  List<Object?> get props => [athlete];
}
