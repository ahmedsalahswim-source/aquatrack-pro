part of 'daily_log_bloc.dart';

class DailyLogState extends Equatable {
  final int currentStep;
  final String athleteId;
  final String athleteName;
  final int athleteAge;
  final int? baselineHR;

  final int? restingHR;
  final double? sleepHours;
  final SleepQuality? sleepQuality;
  final int? wellnessScore;
  final NutritionData? nutrition;
  final TrainingData? training;
  final int? stressScore;
  final double? acwr;

  final bool isExistingLog;
  final String? existingLogId;
  final bool isSaving;
  final bool isSaved;
  final String? error;

  const DailyLogState({
    required this.currentStep,
    required this.athleteId,
    required this.athleteName,
    this.athleteAge = 10,
    this.baselineHR,
    this.restingHR,
    this.sleepHours,
    this.sleepQuality,
    this.wellnessScore,
    this.nutrition,
    this.training,
    this.stressScore,
    this.acwr,
    this.isExistingLog = false,
    this.existingLogId,
    this.isSaving = false,
    this.isSaved = false,
    this.error,
  });

  DailyLogState copyWith({
    int? currentStep,
    String? athleteId,
    String? athleteName,
    int? athleteAge,
    int? baselineHR,
    int? restingHR,
    double? sleepHours,
    SleepQuality? sleepQuality,
    int? wellnessScore,
    NutritionData? nutrition,
    TrainingData? training,
    int? stressScore,
    double? acwr,
    bool? isExistingLog,
    String? existingLogId,
    bool? isSaving,
    bool? isSaved,
    String? error,
    bool clearStress = false,
    bool clearAcwr = false,
  }) {
    return DailyLogState(
      currentStep: currentStep ?? this.currentStep,
      athleteId: athleteId ?? this.athleteId,
      athleteName: athleteName ?? this.athleteName,
      athleteAge: athleteAge ?? this.athleteAge,
      baselineHR: baselineHR ?? this.baselineHR,
      restingHR: restingHR ?? this.restingHR,
      sleepHours: sleepHours ?? this.sleepHours,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      wellnessScore: wellnessScore ?? this.wellnessScore,
      nutrition: nutrition ?? this.nutrition,
      training: training ?? this.training,
      stressScore: clearStress ? null : (stressScore ?? this.stressScore),
      acwr: clearAcwr ? null : (acwr ?? this.acwr),
      isExistingLog: isExistingLog ?? this.isExistingLog,
      existingLogId: existingLogId ?? this.existingLogId,
      isSaving: isSaving ?? this.isSaving,
      isSaved: isSaved ?? this.isSaved,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    currentStep, athleteId, athleteName, athleteAge,
    restingHR, sleepHours, sleepQuality, wellnessScore,
    nutrition, training, stressScore, acwr,
    isExistingLog, existingLogId, isSaving, isSaved, error,
  ];
}
