import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/add_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/update_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/delete_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/watch_athletes_usecase.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';

class MockAddAthleteUseCase extends Mock implements AddAthleteUseCase {}
class MockUpdateAthleteUseCase extends Mock implements UpdateAthleteUseCase {}
class MockDeleteAthleteUseCase extends Mock implements DeleteAthleteUseCase {}
class MockWatchAthletesUseCase extends Mock implements WatchAthletesUseCase {}

void main() {
  late AddAthleteUseCase addUseCase;
  late UpdateAthleteUseCase updateUseCase;
  late DeleteAthleteUseCase deleteUseCase;
  late WatchAthletesUseCase watchUseCase;

  setUpAll(() {
    registerFallbackValue(AthleteEntity(
      id: '', parentId: '', name: '',
      birthDate: DateTime(2000), gender: Gender.male,
      createdAt: DateTime(2026),
    ));
    registerFallbackValue(Gender.male);
    registerFallbackValue(DateTime(2000));
  });

  setUp(() {
    addUseCase = MockAddAthleteUseCase();
    updateUseCase = MockUpdateAthleteUseCase();
    deleteUseCase = MockDeleteAthleteUseCase();
    watchUseCase = MockWatchAthletesUseCase();
  });

  group('AthleteBloc', () {
    blocTest<AthleteBloc, AthleteState>(
      'loads athletes on WatchAthletesEvent',
      build: () {
        when(() => watchUseCase.call(any())).thenAnswer(
          (_) => Stream.value(Right([
            AthleteEntity(
              id: '1', parentId: 'p1', name: 'A',
              birthDate: DateTime(2010), gender: Gender.male,
              createdAt: DateTime(2026),
            ),
          ])),
        );
        return AthleteBloc(
          addAthleteUseCase: addUseCase,
          updateAthleteUseCase: updateUseCase,
          deleteAthleteUseCase: deleteUseCase,
          watchAthletesUseCase: watchUseCase,
        );
      },
      act: (bloc) => bloc.add(const WatchAthletesEvent(parentId: 'p1')),
      expect: () => [
        const AthleteLoading(),
        isA<AthletesLoaded>().having((s) => s.athletes.length, 'count', 1),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AthleteBloc, AthleteState>(
      'emits error when add fails',
      build: () {
        when(() => addUseCase.call(
          parentId: any(named: 'parentId'),
          name: any(named: 'name'),
          birthDate: any(named: 'birthDate'),
          gender: any(named: 'gender'),
        )).thenAnswer((_) async => const Left(ServerFailure(message: 'Add failed')));
        return AthleteBloc(
          addAthleteUseCase: addUseCase,
          updateAthleteUseCase: updateUseCase,
          deleteAthleteUseCase: deleteUseCase,
          watchAthletesUseCase: watchUseCase,
        );
      },
      act: (bloc) => bloc.add(AddAthleteEvent(
        parentId: 'p1', name: 'New',
        birthDate: DateTime(2010), gender: Gender.male,
      )),
      expect: () => [
        isA<AthleteError>().having((s) => s.message, 'msg', 'Add failed'),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AthleteBloc, AthleteState>(
      'emits error when update fails',
      build: () {
        when(() => updateUseCase.call(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Update failed')),
        );
        return AthleteBloc(
          addAthleteUseCase: addUseCase,
          updateAthleteUseCase: updateUseCase,
          deleteAthleteUseCase: deleteUseCase,
          watchAthletesUseCase: watchUseCase,
        );
      },
      act: (bloc) => bloc.add(UpdateAthleteEvent(
        athlete: AthleteEntity(
          id: '1', parentId: 'p1', name: 'A',
          birthDate: DateTime(2010), gender: Gender.male,
          createdAt: DateTime(2026),
        ),
      )),
      expect: () => [
        isA<AthleteError>().having((s) => s.message, 'msg', 'Update failed'),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AthleteBloc, AthleteState>(
      'emits error when delete fails',
      build: () {
        when(() => deleteUseCase.call(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Delete failed')),
        );
        return AthleteBloc(
          addAthleteUseCase: addUseCase,
          updateAthleteUseCase: updateUseCase,
          deleteAthleteUseCase: deleteUseCase,
          watchAthletesUseCase: watchUseCase,
        );
      },
      act: (bloc) => bloc.add(const DeleteAthleteEvent(
        athleteId: '1', parentId: 'p1',
      )),
      expect: () => [
        isA<AthleteError>().having((s) => s.message, 'msg', 'Delete failed'),
      ],
      wait: const Duration(milliseconds: 100),
    );
  });
}
