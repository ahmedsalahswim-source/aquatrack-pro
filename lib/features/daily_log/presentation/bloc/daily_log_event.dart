part of 'daily_log_bloc.dart';

abstract class DailyLogEvent extends Equatable {
  const DailyLogEvent();
  @override
  List<Object?> get props => [];
}

class InitLogEvent extends DailyLogEvent {
  final String athleteId;
  final String athleteName;
  final int athleteAge;
  final int? baselineHR;
  const InitLogEvent({
    required this.athleteId,
    required this.athleteName,
    this.athleteAge = 10,
    this.baselineHR,
  });
  @override
  List<Object?> get props => [athleteId, athleteName, athleteAge, baselineHR];
}

class NextStepEvent extends DailyLogEvent {
  const NextStepEvent();
}
class PreviousStepEvent extends DailyLogEvent {
  const PreviousStepEvent();
}

class UpdateRHRStep extends DailyLogEvent {
  final int value;
  const UpdateRHRStep({required this.value});
  @override
  List<Object?> get props => [value];
}

class UpdateSleepStep extends DailyLogEvent {
  final double hours;
  final SleepQuality quality;
  const UpdateSleepStep({required this.hours, required this.quality});
  @override
  List<Object?> get props => [hours, quality];
}

class UpdateWellnessStep extends DailyLogEvent {
  final int score;
  const UpdateWellnessStep({required this.score});
  @override
  List<Object?> get props => [score];
}

class UpdateNutritionStep extends DailyLogEvent {
  final NutritionData data;
  const UpdateNutritionStep({required this.data});
  @override
  List<Object?> get props => [data];
}

class UpdateTrainingStep extends DailyLogEvent {
  final TrainingData data;
  const UpdateTrainingStep({required this.data});
  @override
  List<Object?> get props => [data];
}

class SaveLogEvent extends DailyLogEvent {
  const SaveLogEvent();
}

class ResetLogEvent extends DailyLogEvent {
  const ResetLogEvent();
}

class CheckExistingLogEvent extends DailyLogEvent {
  final String athleteId;
  const CheckExistingLogEvent({required this.athleteId});
  @override
  List<Object?> get props => [athleteId];
}
