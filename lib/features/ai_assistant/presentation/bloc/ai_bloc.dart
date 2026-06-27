import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/constants/app_constants.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/services/swimmer_context_builder.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/get_ai_history_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/get_messages_used_today_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/send_message_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_event.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_state.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetAiHistoryUseCase getAiHistoryUseCase;
  final GetMessagesUsedTodayUseCase getMessagesUsedTodayUseCase;
  final AiRepository aiRepository;
  final SwimmerContextBuilder contextBuilder;
  final DailyLogRepository logRepository;

  String _userId = '';
  String _athleteId = '';
  AthleteEntity? _athlete;
  List<DailyLogEntity> _recentLogs = [];
  DailyLogEntity? _todayLog;
  double? _acwr;
  int? _stressScore;

  AiBloc({
    required this.sendMessageUseCase,
    required this.getAiHistoryUseCase,
    required this.getMessagesUsedTodayUseCase,
    required this.aiRepository,
    required this.contextBuilder,
    required this.logRepository,
  }) : super(const AiInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<SendMessageStreamEvent>(_onSendMessageStream);
    on<LoadHistoryEvent>(_onLoadHistory);
    on<ClearConversationEvent>(_onClearConversation);
    on<RateMessageEvent>(_onRateMessage);
  }

  void initialize(String userId, AthleteEntity athlete) {
    _userId = userId;
    _athlete = athlete;
    _athleteId = athlete.id;
  }

  void setContextData({
    List<DailyLogEntity>? recentLogs,
    DailyLogEntity? todayLog,
    double? acwr,
    int? stressScore,
  }) {
    if (recentLogs != null) _recentLogs = recentLogs;
    if (todayLog != null) _todayLog = todayLog;
    if (acwr != null) _acwr = acwr;
    if (stressScore != null) _stressScore = stressScore;
  }

  void _onLoadHistory(LoadHistoryEvent event, Emitter<AiState> emit) async {
    if (_userId.isEmpty) return;
    emit(const AiLoading());
    final results = await Future.wait([
      getAiHistoryUseCase(userId: _userId, athleteId: _athleteId),
      getMessagesUsedTodayUseCase(_userId),
    ]);
    if (isClosed) return;
    final historyResult = results[0] as Either<Failure, List<AiMessageEntity>>;
    final countResult = results[1] as Either<Failure, int>;
    historyResult.fold(
      (failure) => emit(AiError(
        message: failure.message,
        currentMessages: const [],
      )),
      (messages) => emit(AiLoaded(
        messages: messages,
        messagesUsedToday: countResult.fold((_) => messages.length, (c) => c),
        maxMessages: AppConstants.freeMessagesPerDay,
      )),
    );
  }

  void _onSendMessage(SendMessageEvent event, Emitter<AiState> emit) async {
    if (_userId.isEmpty || event.question.trim().isEmpty || state is AiLoading) return;

    final currentMessages = state is AiLoaded
        ? (state as AiLoaded).messages
        : state is AiError
            ? (state as AiError).currentMessages
            : <AiMessageEntity>[];

    emit(AiLoading(currentMessages: currentMessages));

    Map<String, dynamic> contextMap;
    if (_athlete != null) {
      try {
        final fullContext = contextBuilder.buildFullContext(
          athlete: _athlete!,
          recentLogs: _recentLogs,
          todayLog: _todayLog,
          acwr: _acwr,
          stressScore: _stressScore,
        );
        contextMap = {'_fullContext': fullContext, ...event.context};
      } catch (_) {
        contextMap = event.context;
      }
    } else {
      contextMap = event.context;
    }

    final result = await sendMessageUseCase(
      userId: _userId,
      athleteId: _athleteId,
      athleteName: event.athleteName,
      question: event.question.trim(),
      context: contextMap,
      history: currentMessages,
    );

    try {
      await result.fold(
        (failure) async => emit(AiError(
          message: failure.message,
          currentMessages: currentMessages,
        )),
        (message) async {
          final updatedMessages = [...currentMessages, message];
          final count = await _getMessageCount();
          if (!isClosed) {
            emit(AiLoaded(
              messages: updatedMessages,
              messagesUsedToday: count,
              maxMessages: AppConstants.freeMessagesPerDay,
            ));
          }
        },
      );
    } catch (e) {
      if (!isClosed) {
        emit(AiError(
          message: e.toString(),
          currentMessages: currentMessages,
        ));
      }
    }
  }

  void _onSendMessageStream(SendMessageStreamEvent event, Emitter<AiState> emit) async {
    if (_userId.isEmpty || event.question.trim().isEmpty || state is AiLoading) return;

    final currentMessages = state is AiLoaded
        ? (state as AiLoaded).messages
        : state is AiError
            ? (state as AiError).currentMessages
            : <AiMessageEntity>[];

    emit(AiLoading(currentMessages: currentMessages));

    Map<String, dynamic> contextMap;
    if (_athlete != null) {
      try {
        final fullContext = contextBuilder.buildFullContext(
          athlete: _athlete!,
          recentLogs: _recentLogs,
          todayLog: _todayLog,
          acwr: _acwr,
          stressScore: _stressScore,
        );
        contextMap = {'_fullContext': fullContext, ...event.context};
      } catch (_) {
        contextMap = event.context;
      }
    } else {
      contextMap = event.context;
    }

    final buffer = StringBuffer();
    aiRepository.sendMessageStream(
      userId: _userId,
      athleteId: _athleteId,
      athleteName: event.athleteName,
      question: event.question.trim(),
      context: contextMap,
      history: currentMessages,
    ).listen(
      (chunk) {
        buffer.write(chunk);
        if (!isClosed) {
          emit(AiStreaming(
            currentMessages: currentMessages,
            partialAnswer: buffer.toString(),
          ));
        }
      },
      onDone: () async {
        final userMessage = AiMessageEntity(
          id: '${DateTime.now().millisecondsSinceEpoch}',
          userId: _userId,
          athleteId: _athleteId,
          question: event.question.trim(),
          answer: buffer.toString(),
          category: AiCategory.general,
          trigger: AiTrigger.userQuery,
          timestamp: DateTime.now(),
        );
        final updatedMessages = [...currentMessages, userMessage];
        final count = await _getMessageCount();
        if (!isClosed) {
          emit(AiLoaded(
            messages: updatedMessages,
            messagesUsedToday: count,
            maxMessages: AppConstants.freeMessagesPerDay,
          ));
        }
      },
      onError: (e) {
        if (!isClosed) {
          emit(AiError(
            message: e.toString(),
            currentMessages: currentMessages,
          ));
        }
      },
    );
  }

  Future<int> _getMessageCount() async {
    if (_userId.isEmpty) return 0;
    final result = await getMessagesUsedTodayUseCase(_userId);
    return result.fold((_) => 0, (count) => count);
  }

  void _onClearConversation(
      ClearConversationEvent event, Emitter<AiState> emit) {
    final currentCount = state is AiLoaded
        ? (state as AiLoaded).messagesUsedToday
        : 0;
    emit(AiLoaded(
      messages: [],
      messagesUsedToday: currentCount,
      maxMessages: AppConstants.freeMessagesPerDay,
    ));
  }

  void _onRateMessage(RateMessageEvent event, Emitter<AiState> emit) async {
    await aiRepository.updateFeedback(event.messageId, event.feedback);
    if (!isClosed && state is AiLoaded) {
      final loaded = state as AiLoaded;
      final updated = loaded.messages.map((m) {
        if (m.id == event.messageId) {
          return AiMessageEntity(
            id: m.id,
            userId: m.userId,
            athleteId: m.athleteId,
            question: m.question,
            answer: m.answer,
            citations: m.citations,
            category: m.category,
            trigger: m.trigger,
            timestamp: m.timestamp,
            feedback: event.feedback,
          );
        }
        return m;
      }).toList();
      emit(AiLoaded(
        messages: updated,
        messagesUsedToday: loaded.messagesUsedToday,
        maxMessages: loaded.maxMessages,
      ));
    }
  }
}
