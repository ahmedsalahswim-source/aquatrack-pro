import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/core/utils/helpers.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';

part 'daily_log_event.dart';
part 'daily_log_state.dart';

class DailyLogBloc extends Bloc<DailyLogEvent, DailyLogState> {
  final DailyLogRepository repository;

  DailyLogBloc({required this.repository})
      : super(const DailyLogState(
          currentStep: 0,
          athleteId: '',
          athleteName: '',
          athleteAge: 10,
        )) {
    on<InitLogEvent>(_onInit);
    on<NextStepEvent>(_onNextStep);
    on<PreviousStepEvent>(_onPreviousStep);
    on<UpdateRHRStep>(_onUpdateRHR);
    on<UpdateSleepStep>(_onUpdateSleep);
    on<UpdateWellnessStep>(_onUpdateWellness);
    on<UpdateNutritionStep>(_onUpdateNutrition);
    on<UpdateTrainingStep>(_onUpdateTraining);
    on<SaveLogEvent>(_onSave);
    on<CheckExistingLogEvent>(_onCheckExisting);
    on<ResetLogEvent>(_onReset);
  }

  void _onReset(ResetLogEvent event, Emitter<DailyLogState> emit) {
    emit(DailyLogState(
      currentStep: 0,
      athleteId: '',
      athleteName: '',
      athleteAge: 10,
    ));
  }

  void _onInit(InitLogEvent event, Emitter<DailyLogState> emit) {
    emit(state.copyWith(
      athleteId: event.athleteId,
      athleteName: event.athleteName,
      athleteAge: event.athleteAge,
      baselineHR: event.baselineHR,
      currentStep: 0,
      restingHR: null,
      sleepHours: null,
      sleepQuality: null,
      wellnessScore: null,
      nutrition: const NutritionData(),
      training: const TrainingData(),
      stressScore: null,
      isExistingLog: false,
      existingLogId: null,
      error: null,
    ));
  }

  void _onNextStep(NextStepEvent event, Emitter<DailyLogState> emit) {
    if (state.currentStep < 4) {
      emit(state.copyWith(currentStep: state.currentStep + 1, error: null));
    }
  }

  void _onPreviousStep(PreviousStepEvent event, Emitter<DailyLogState> emit) {
    if (state.currentStep > 0) {
      emit(state.copyWith(currentStep: state.currentStep - 1, error: null));
    }
  }

  void _onUpdateRHR(UpdateRHRStep event, Emitter<DailyLogState> emit) {
    emit(state.copyWith(restingHR: event.value));
  }

  void _onUpdateSleep(UpdateSleepStep event, Emitter<DailyLogState> emit) {
    emit(state.copyWith(sleepHours: event.hours, sleepQuality: event.quality));
  }

  void _onUpdateWellness(UpdateWellnessStep event, Emitter<DailyLogState> emit) {
    emit(state.copyWith(wellnessScore: event.score));
  }

  void _onUpdateNutrition(UpdateNutritionStep event, Emitter<DailyLogState> emit) {
    emit(state.copyWith(nutrition: event.data));
  }

  void _onUpdateTraining(UpdateTrainingStep event, Emitter<DailyLogState> emit) {
    emit(state.copyWith(training: event.data));
  }

  Future<void> _onCheckExisting(
      CheckExistingLogEvent event, Emitter<DailyLogState> emit) async {
    final today = DateHelpers.formatDate(DateTime.now());
    final result = await repository.getLogByDate(event.athleteId, today);
    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (log) {
        if (log != null) {
          emit(state.copyWith(
            isExistingLog: true,
            existingLogId: log.id,
            restingHR: log.restingHR,
            sleepHours: log.sleepHours,
            sleepQuality: log.sleepQuality,
            wellnessScore: log.wellnessScore,
            nutrition: log.nutrition ?? const NutritionData(),
            training: log.training ?? const TrainingData(),
            stressScore: log.stressScore,
            acwr: log.acwr,
          ));
        } else {
          emit(state.copyWith(
            isExistingLog: false,
            existingLogId: null,
          ));
        }
      },
    );
  }

  Future<void> _onSave(SaveLogEvent event, Emitter<DailyLogState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final today = DateHelpers.formatDate(DateTime.now());

    final stressScore = _calculateStressScore();
    double? acwr;
    final rangeResult = await repository.getLogsInRange(state.athleteId, 28);
    rangeResult.fold(
      (_) {},
      (logs) {
        if (logs.length >= 7) {
          final acute = logs
              .take(7)
              .map((l) => (l.training?.trainingLoad ?? 0).toDouble())
              .where((v) => v > 0)
              .toList();
          List<double>? chronic;
          if (logs.length > 7) {
            chronic = logs
                .skip(7)
                .take(21)
                .map((l) => (l.training?.trainingLoad ?? 0).toDouble())
                .where((v) => v > 0)
                .toList();
          }
          acwr = AcwrCalculator.calculate(acuteLoads: acute, chronicLoads: chronic);
        }
      },
    );

    final log = DailyLogEntity(
      id: state.existingLogId ?? const Uuid().v4(),
      athleteId: state.athleteId,
      date: today,
      restingHR: state.restingHR,
      sleepHours: state.sleepHours,
      sleepQuality: state.sleepQuality,
      wellnessScore: state.wellnessScore,
      nutrition: state.nutrition,
      training: state.training,
      stressScore: stressScore,
      acwr: acwr,
      createdAt: DateTime.now(),
    );
    final result = await repository.saveLog(log);
    result.fold(
      (failure) => emit(state.copyWith(isSaving: false, error: failure.message)),
      (saved) {
        emit(state.copyWith(
          isSaving: false,
          isSaved: true,
          currentStep: 0,
        ));
      },
    );
  }

  int? _calculateStressScore() {
    final sleepHours = state.sleepHours;
    final restingHR = state.restingHR;
    final rpe = state.training?.rpe;
    final wellnessScore = state.wellnessScore;
    if (sleepHours == null && restingHR == null && rpe == null && wellnessScore == null) {
      return null;
    }
    return StressCalculator.calculate(
      sleepHours: sleepHours,
      recommendedSleep: DateHelpers.sleepRecommendationByAge(state.athleteAge).$1,
      restingHR: restingHR,
      baselineHR: state.baselineHR,
      rpe: rpe,
      wellnessScore: wellnessScore,
    );
  }

}
