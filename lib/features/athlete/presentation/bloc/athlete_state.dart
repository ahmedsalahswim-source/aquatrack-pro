part of 'athlete_bloc.dart';

abstract class AthleteState extends Equatable {
  const AthleteState();

  @override
  List<Object?> get props => [];
}

class AthleteInitial extends AthleteState {
  const AthleteInitial();
}

class AthleteLoading extends AthleteState {
  const AthleteLoading();
}

class AthletesLoaded extends AthleteState {
  final List<AthleteEntity> athletes;
  final AthleteEntity? selectedAthlete;

  const AthletesLoaded({
    required this.athletes,
    this.selectedAthlete,
  });

  @override
  List<Object?> get props => [athletes, selectedAthlete];
}

class AthleteActionSuccess extends AthleteState {
  final String message;

  const AthleteActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class AthleteError extends AthleteState {
  final String message;

  const AthleteError(this.message);

  @override
  List<Object?> get props => [message];
}
