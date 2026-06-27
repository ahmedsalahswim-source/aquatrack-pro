import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/add_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/update_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/delete_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/watch_athletes_usecase.dart';

part 'athlete_event.dart';
part 'athlete_state.dart';

class AthleteBloc extends Bloc<AthleteEvent, AthleteState> {
  final AddAthleteUseCase addAthleteUseCase;
  final UpdateAthleteUseCase updateAthleteUseCase;
  final DeleteAthleteUseCase deleteAthleteUseCase;
  final WatchAthletesUseCase watchAthletesUseCase;

  AthleteBloc({
    required this.addAthleteUseCase,
    required this.updateAthleteUseCase,
    required this.deleteAthleteUseCase,
    required this.watchAthletesUseCase,
  }) : super(const AthleteInitial()) {
    on<WatchAthletesEvent>(_onWatchAthletes);
    on<AddAthleteEvent>(_onAddAthlete);
    on<UpdateAthleteEvent>(_onUpdateAthlete);
    on<DeleteAthleteEvent>(_onDeleteAthlete);
    on<SelectAthleteEvent>(_onSelectAthlete);
  }

  Future<void> _onWatchAthletes(WatchAthletesEvent event, Emitter<AthleteState> emit) {
    emit(const AthleteLoading());
    return emit.forEach(
      watchAthletesUseCase(event.parentId),
      onData: (result) => result.fold(
        (failure) => AthleteError(failure.message),
        (athletes) => AthletesLoaded(athletes: athletes),
      ),
      onError: (e, _) => AthleteError('خطأ في الاتصال: $e'),
    );
  }

  Future<void> _onAddAthlete(AddAthleteEvent event, Emitter<AthleteState> emit) async {
    final result = await addAthleteUseCase.call(
      parentId: event.parentId,
      name: event.name,
      birthDate: event.birthDate,
      gender: event.gender,
      swimLevel: event.swimLevel,
      weightKg: event.weightKg,
      heightCm: event.heightCm,
      targetWeeklyHours: event.targetWeeklyHours,
      photoUrl: event.photoUrl,
    );
    final success = result.fold(
      (failure) {
        emit(AthleteError(failure.message));
        return false;
      },
      (_) => true,
    );
    if (success) {
      add(WatchAthletesEvent(parentId: event.parentId));
    }
  }

  Future<void> _onUpdateAthlete(UpdateAthleteEvent event, Emitter<AthleteState> emit) async {
    final result = await updateAthleteUseCase(event.athlete);
    final success = result.fold(
      (failure) {
        emit(AthleteError(failure.message));
        return false;
      },
      (_) => true,
    );
    if (success) {
      add(WatchAthletesEvent(parentId: event.athlete.parentId));
    }
  }

  Future<void> _onDeleteAthlete(DeleteAthleteEvent event, Emitter<AthleteState> emit) async {
    final result = await deleteAthleteUseCase(event.athleteId);
    final success = result.fold(
      (failure) {
        emit(AthleteError(failure.message));
        return false;
      },
      (_) => true,
    );
    if (success) {
      add(WatchAthletesEvent(parentId: event.parentId));
    }
  }

  void _onSelectAthlete(SelectAthleteEvent event, Emitter<AthleteState> emit) {
    if (state is AthletesLoaded) {
      final current = state as AthletesLoaded;
      emit(AthletesLoaded(
        athletes: current.athletes,
        selectedAthlete: event.athlete,
      ));
    }
  }
}
