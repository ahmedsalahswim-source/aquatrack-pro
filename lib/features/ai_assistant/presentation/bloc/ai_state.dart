import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';

abstract class AiState extends Equatable {
  const AiState();

  @override
  List<Object?> get props => [];
}

class AiInitial extends AiState {
  const AiInitial();
}

class AiLoading extends AiState {
  final List<AiMessageEntity> currentMessages;

  const AiLoading({this.currentMessages = const []});

  @override
  List<Object?> get props => [currentMessages];
}

class AiStreaming extends AiState {
  final List<AiMessageEntity> currentMessages;
  final String partialAnswer;

  const AiStreaming({
    required this.currentMessages,
    this.partialAnswer = '',
  });

  @override
  List<Object?> get props => [currentMessages, partialAnswer];
}

class AiLoaded extends AiState {
  final List<AiMessageEntity> messages;
  final int messagesUsedToday;
  final int maxMessages;

  const AiLoaded({
    required this.messages,
    this.messagesUsedToday = 0,
    this.maxMessages = 20,
  });

  bool get canSendMore => messagesUsedToday < maxMessages;

  @override
  List<Object?> get props => [messages, messagesUsedToday, maxMessages];
}

class AiError extends AiState {
  final String message;
  final List<AiMessageEntity> currentMessages;

  const AiError({
    required this.message,
    this.currentMessages = const [],
  });

  @override
  List<Object?> get props => [message, currentMessages];
}
