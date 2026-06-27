import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/food_item.dart';
import '../../domain/entities/meal_log.dart';
import '../../domain/entities/nutrition_calculator.dart';
import '../../domain/repositories/nutrition_repository.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';

// --- Events ---
abstract class NutritionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadNutritionData extends NutritionEvent {
  final AthleteEntity athlete;
  final DateTime date;
  LoadNutritionData({required this.athlete, required this.date});

  @override
  List<Object?> get props => [athlete, date];
}

class AddMealEntryEvent extends NutritionEvent {
  final String athleteId;
  final DateTime date;
  final MealType type;
  final FoodItem food;
  final double amountInGrams;

  AddMealEntryEvent({
    required this.athleteId,
    required this.date,
    required this.type,
    required this.food,
    required this.amountInGrams,
  });

  @override
  List<Object?> get props => [athleteId, date, type, food, amountInGrams];
}

class UpdateHydrationEvent extends NutritionEvent {
  final String athleteId;
  final DateTime date;
  final double liters;

  UpdateHydrationEvent({required this.athleteId, required this.date, required this.liters});

  @override
  List<Object?> get props => [athleteId, date, liters];
}

class CopyYesterdayMealsEvent extends NutritionEvent {
  final String athleteId;
  final DateTime todayDate;

  CopyYesterdayMealsEvent({required this.athleteId, required this.todayDate});

  @override
  List<Object?> get props => [athleteId, todayDate];
}

// --- State ---
class NutritionState extends Equatable {
  final bool isLoading;
  final String? error;
  final List<FoodItem> foodDatabase;
  final List<MealLog> dailyLogs;
  final double targetTDEE;
  final Map<String, double> targetMacros;
  final DateTime? currentDate;
  final double currentHydration;

  const NutritionState({
    this.isLoading = false,
    this.error,
    this.foodDatabase = const [],
    this.dailyLogs = const [],
    this.targetTDEE = 0.0,
    this.targetMacros = const {},
    this.currentDate,
    this.currentHydration = 0.0,
  });

  NutritionState copyWith({
    bool? isLoading,
    String? error,
    List<FoodItem>? foodDatabase,
    List<MealLog>? dailyLogs,
    double? targetTDEE,
    Map<String, double>? targetMacros,
    DateTime? currentDate,
    double? currentHydration,
  }) {
    return NutritionState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      foodDatabase: foodDatabase ?? this.foodDatabase,
      dailyLogs: dailyLogs ?? this.dailyLogs,
      targetTDEE: targetTDEE ?? this.targetTDEE,
      targetMacros: targetMacros ?? this.targetMacros,
      currentDate: currentDate ?? this.currentDate,
      currentHydration: currentHydration ?? this.currentHydration,
    );
  }

  double get consumedCalories => dailyLogs.fold(0, (sum, log) => sum + log.totalCalories);
  double get consumedProtein => dailyLogs.fold(0, (sum, log) => sum + log.totalProtein);
  double get consumedCarbs => dailyLogs.fold(0, (sum, log) => sum + log.totalCarbs);
  double get consumedFat => dailyLogs.fold(0, (sum, log) => sum + log.totalFat);

  @override
  List<Object?> get props => [
        isLoading,
        error,
        foodDatabase,
        dailyLogs,
        targetTDEE,
        targetMacros,
        currentDate,
        currentHydration,
      ];
}

// --- BLoC ---
class NutritionBloc extends Bloc<NutritionEvent, NutritionState> {
  final NutritionRepository repository;
  final DailyLogRepository dailyLogRepository;

  NutritionBloc({required this.repository, required this.dailyLogRepository}) : super(const NutritionState()) {
    on<LoadNutritionData>(_onLoadNutritionData);
    on<AddMealEntryEvent>(_onAddMealEntry);
    on<UpdateHydrationEvent>(_onUpdateHydration);
    on<CopyYesterdayMealsEvent>(_onCopyYesterdayMeals);
  }

  Future<void> _onLoadNutritionData(LoadNutritionData event, Emitter<NutritionState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final foods = await repository.getFoodDatabase();
      final logs = await repository.getMealLogs(event.athlete.id, event.date);

      final dailyLogRes = await dailyLogRepository.getLogByDate(event.athlete.id, event.date.toIso8601String().substring(0, 10));
      double hydration = 0.0;
      dailyLogRes.fold(
        (l) => null,
        (dailyLog) => hydration = dailyLog?.nutrition?.hydrationLiters ?? 0.0,
      );

      // Calculate BMR and TDEE
      final bmr = NutritionCalculator.calculateBMR(
        weightKg: event.athlete.weightKg ?? 70.0,
        heightCm: event.athlete.heightCm ?? 170.0,
        ageYears: event.athlete.age,
        gender: event.athlete.gender,
      );

      final tdee = NutritionCalculator.calculateTDEE(
        bmr: bmr,
        activityLevel: ActivityLevel.veryActive, // Assuming high training volume
      );

      final macros = NutritionCalculator.calculateMacros(tdee);

      emit(state.copyWith(
        isLoading: false,
        foodDatabase: foods,
        dailyLogs: logs,
        targetTDEE: tdee,
        targetMacros: macros,
        currentDate: event.date,
        currentHydration: hydration,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onAddMealEntry(AddMealEntryEvent event, Emitter<NutritionState> emit) async {
    try {
      // Find existing log for the meal type
      int existingIndex = state.dailyLogs.indexWhere((log) => log.mealType == event.type);
      
      MealLog logToUpdate;
      if (existingIndex >= 0) {
        logToUpdate = state.dailyLogs[existingIndex];
      } else {
        logToUpdate = MealLog(
          athleteId: event.athleteId,
          date: event.date,
          mealType: event.type,
        );
      }

      final newEntry = MealEntry(food: event.food, amountInGrams: event.amountInGrams);
      final updatedEntries = List<MealEntry>.from(logToUpdate.entries)..add(newEntry);
      
      logToUpdate = logToUpdate.copyWith(entries: updatedEntries);
      
      await repository.saveMealLog(logToUpdate);

      // Refresh logs
      final newLogs = await repository.getMealLogs(event.athleteId, event.date);
      emit(state.copyWith(dailyLogs: newLogs));
      
      // Update Daily Log meals count
      _syncDailyLog(event.athleteId, event.date, newLogs.length);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateHydration(UpdateHydrationEvent event, Emitter<NutritionState> emit) async {
    try {
      emit(state.copyWith(currentHydration: event.liters));
      final dailyLogRes = await dailyLogRepository.getLogByDate(event.athleteId, event.date.toIso8601String().substring(0, 10));
      dailyLogRes.fold((l) => null, (existing) async {
        DailyLogEntity logToSave = existing ?? DailyLogEntity(
          id: '',
          athleteId: event.athleteId,
          date: event.date.toIso8601String().substring(0, 10),
          createdAt: DateTime.now(),
        );
        NutritionData nut = logToSave.nutrition ?? const NutritionData();
        nut = nut.copyWith(hydrationLiters: event.liters);
        logToSave = logToSave.copyWith(nutrition: nut);
        await dailyLogRepository.saveLog(logToSave);
      });
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onCopyYesterdayMeals(CopyYesterdayMealsEvent event, Emitter<NutritionState> emit) async {
    try {
      final yesterday = event.todayDate.subtract(const Duration(days: 1));
      final yesterdayLogs = await repository.getMealLogs(event.athleteId, yesterday);
      if (yesterdayLogs.isEmpty) return;

      for (var yLog in yesterdayLogs) {
        MealLog newLog = yLog.copyWith(
          id: '',
          date: event.todayDate,
        );
        await repository.saveMealLog(newLog);
      }
      final newLogs = await repository.getMealLogs(event.athleteId, event.todayDate);
      emit(state.copyWith(dailyLogs: newLogs));
      _syncDailyLog(event.athleteId, event.todayDate, newLogs.length);
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _syncDailyLog(String athleteId, DateTime date, int mealsCount) async {
      final dailyLogRes = await dailyLogRepository.getLogByDate(athleteId, date.toIso8601String().substring(0, 10));
      dailyLogRes.fold((l) => null, (existing) async {
        DailyLogEntity logToSave = existing ?? DailyLogEntity(
          id: '',
          athleteId: athleteId,
          date: date.toIso8601String().substring(0, 10),
          createdAt: DateTime.now(),
        );
        NutritionData nut = logToSave.nutrition ?? const NutritionData();
        nut = nut.copyWith(
          breakfast: mealsCount > 0,
          lunch: mealsCount > 1,
          dinner: mealsCount > 2,
          snack: mealsCount > 3,
        );
        logToSave = logToSave.copyWith(nutrition: nut);
        await dailyLogRepository.saveLog(logToSave);
      });
  }
}
