import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

abstract class AiEvent extends Equatable {
  const AiEvent();

  @override
  List<Object?> get props => [];
}

class SendMessageEvent extends AiEvent {
  final String question;
  final String athleteName;
  final Map<String, dynamic> context;

  const SendMessageEvent({
    required this.question,
    required this.athleteName,
    required this.context,
  });

  @override
  List<Object?> get props => [question, athleteName, context];
}

class SendMessageStreamEvent extends AiEvent {
  final String question;
  final String athleteName;
  final Map<String, dynamic> context;

  const SendMessageStreamEvent({
    required this.question,
    required this.athleteName,
    required this.context,
  });

  @override
  List<Object?> get props => [question, athleteName, context];
}

class LoadHistoryEvent extends AiEvent {
  const LoadHistoryEvent();
}

class ClearConversationEvent extends AiEvent {
  const ClearConversationEvent();
}

class RateMessageEvent extends AiEvent {
  final String messageId;
  final UserFeedback feedback;

  const RateMessageEvent({
    required this.messageId,
    required this.feedback,
  });

  @override
  List<Object?> get props => [messageId, feedback];
}
