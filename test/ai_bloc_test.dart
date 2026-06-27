import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/services/swimmer_context_builder.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/send_message_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/get_ai_history_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/get_messages_used_today_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_bloc.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_event.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_state.dart';

class MockSendMessageUseCase extends Mock implements SendMessageUseCase {}
class MockGetAiHistoryUseCase extends Mock implements GetAiHistoryUseCase {}
class MockGetMessagesUsedTodayUseCase extends Mock
    implements GetMessagesUsedTodayUseCase {}
class MockAiRepository extends Mock implements AiRepository {}
class MockDailyLogRepository extends Mock implements DailyLogRepository {}

final testAthlete = AthleteEntity(
  id: 'athlete_1',
  parentId: 'user_1',
  name: 'Test Athlete',
  birthDate: DateTime(2014, 1, 1),
  gender: Gender.male,
  createdAt: DateTime(2026, 1, 1),
);

final testMessage = AiMessageEntity(
  id: 'msg_1',
  userId: 'user_1',
  athleteId: 'athlete_1',
  question: 'How is my training?',
  answer: 'Your training is going well.',
  category: AiCategory.training,
  trigger: AiTrigger.userQuery,
  timestamp: DateTime(2026, 6, 12),
);

void main() {
  late SendMessageUseCase sendMessageUseCase;
  late GetAiHistoryUseCase getAiHistoryUseCase;
  late GetMessagesUsedTodayUseCase getMessagesUsedTodayUseCase;
  late MockAiRepository aiRepository;
  late DailyLogRepository logRepository;

  setUpAll(() {
    registerFallbackValue(const <String, dynamic>{});
  });

  setUp(() {
    sendMessageUseCase = MockSendMessageUseCase();
    getAiHistoryUseCase = MockGetAiHistoryUseCase();
    getMessagesUsedTodayUseCase = MockGetMessagesUsedTodayUseCase();
    aiRepository = MockAiRepository();
    logRepository = MockDailyLogRepository();
  });

  group('AiBloc', () {
    blocTest<AiBloc, AiState>(
      'sends message and appends to messages',
      build: () {
        when(() => sendMessageUseCase.call(
          userId: any(named: 'userId'),
          athleteId: any(named: 'athleteId'),
          athleteName: any(named: 'athleteName'),
          question: any(named: 'question'),
          context: any(named: 'context'),
        )).thenAnswer((_) async => Right(testMessage));
        when(() => getMessagesUsedTodayUseCase.call(any())).thenAnswer(
          (_) async => const Right(1),
        );
        return AiBloc(
          sendMessageUseCase: sendMessageUseCase,
          getAiHistoryUseCase: getAiHistoryUseCase,
          getMessagesUsedTodayUseCase: getMessagesUsedTodayUseCase,
          aiRepository: aiRepository,
          contextBuilder: const SwimmerContextBuilder(),
          logRepository: logRepository,
        );
      },
      act: (bloc) {
        bloc.initialize('user_1', testAthlete);
        bloc.add(const SendMessageEvent(
          question: 'Hello?', athleteName: 'A', context: {},
        ));
      },
      expect: () => [
        isA<AiLoading>().having((s) => s.currentMessages.length, 'count', 0),
        isA<AiLoaded>().having((s) => s.messages.length, 'count', 1),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AiBloc, AiState>(
      'emits error when send fails',
      build: () {
        when(() => sendMessageUseCase.call(
          userId: any(named: 'userId'),
          athleteId: any(named: 'athleteId'),
          athleteName: any(named: 'athleteName'),
          question: any(named: 'question'),
          context: any(named: 'context'),
        )).thenAnswer((_) async => const Left(ServerFailure(message: 'Failed')));
        when(() => getMessagesUsedTodayUseCase.call(any())).thenAnswer(
          (_) async => const Right(1),
        );
        return AiBloc(
          sendMessageUseCase: sendMessageUseCase,
          getAiHistoryUseCase: getAiHistoryUseCase,
          getMessagesUsedTodayUseCase: getMessagesUsedTodayUseCase,
          aiRepository: aiRepository,
          contextBuilder: const SwimmerContextBuilder(),
          logRepository: logRepository,
        );
      },
      act: (bloc) {
        bloc.initialize('user_1', testAthlete);
        bloc.add(const SendMessageEvent(
          question: 'Hello?', athleteName: 'A', context: {},
        ));
      },
      expect: () => [
        isA<AiLoading>().having((s) => s.currentMessages.length, 'count', 0),
        isA<AiError>().having((s) => s.message, 'msg', 'Failed'),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AiBloc, AiState>(
      'clears conversation',
      build: () => AiBloc(
        sendMessageUseCase: sendMessageUseCase,
        getAiHistoryUseCase: getAiHistoryUseCase,
        getMessagesUsedTodayUseCase: getMessagesUsedTodayUseCase,
        aiRepository: aiRepository,
        contextBuilder: const SwimmerContextBuilder(),
        logRepository: logRepository,
      ),
      act: (bloc) => bloc.add(const ClearConversationEvent()),
      expect: () => [
        isA<AiLoaded>().having((s) => s.messages.length, 'count', 0),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AiBloc, AiState>(
      'handles history load error gracefully',
      build: () {
        when(() => getAiHistoryUseCase.call(
          userId: any(named: 'userId'),
          athleteId: any(named: 'athleteId'),
        )).thenAnswer((_) async => const Left(ServerFailure(message: 'No history')));
        when(() => getMessagesUsedTodayUseCase.call(any())).thenAnswer(
          (_) async => const Right(0),
        );
        return AiBloc(
          sendMessageUseCase: sendMessageUseCase,
          getAiHistoryUseCase: getAiHistoryUseCase,
          getMessagesUsedTodayUseCase: getMessagesUsedTodayUseCase,
          aiRepository: aiRepository,
          contextBuilder: const SwimmerContextBuilder(),
          logRepository: logRepository,
        );
      },
      act: (bloc) {
        bloc.initialize('user_1', testAthlete);
        bloc.add(const LoadHistoryEvent());
      },
      expect: () => [
        isA<AiLoading>(),
        isA<AiError>(),
      ],
      wait: const Duration(milliseconds: 300),
    );

    blocTest<AiBloc, AiState>(
      'loads history and emits loaded',
      build: () {
        when(() => getAiHistoryUseCase.call(
          userId: any(named: 'userId'),
          athleteId: any(named: 'athleteId'),
        )).thenAnswer((_) async => Right([testMessage]));
        when(() => getMessagesUsedTodayUseCase.call(any())).thenAnswer(
          (_) async => const Right(1),
        );
        return AiBloc(
          sendMessageUseCase: sendMessageUseCase,
          getAiHistoryUseCase: getAiHistoryUseCase,
          getMessagesUsedTodayUseCase: getMessagesUsedTodayUseCase,
          aiRepository: aiRepository,
          contextBuilder: const SwimmerContextBuilder(),
          logRepository: logRepository,
        );
      },
      act: (bloc) {
        bloc.initialize('user_1', testAthlete);
        bloc.add(const LoadHistoryEvent());
      },
      expect: () => [
        isA<AiLoading>(),
        isA<AiLoaded>().having((s) => s.messages.length, 'count', 1),
      ],
      wait: const Duration(milliseconds: 300),
    );
  });
}
