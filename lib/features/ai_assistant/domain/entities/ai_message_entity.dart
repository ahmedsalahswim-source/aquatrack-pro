import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

class AiMessageEntity extends Equatable {
  final String id;
  final String userId;
  final String athleteId;
  final String question;
  final String answer;
  final List<String> citations;
  final AiCategory category;
  final AiTrigger trigger;
  final DateTime timestamp;
  final UserFeedback? feedback;

  const AiMessageEntity({
    required this.id,
    required this.userId,
    required this.athleteId,
    required this.question,
    required this.answer,
    this.citations = const [],
    this.category = AiCategory.general,
    this.trigger = AiTrigger.userQuery,
    required this.timestamp,
    this.feedback,
  });

  @override
  List<Object?> get props => [id, userId, athleteId, question, answer, citations, category, trigger, timestamp, feedback];
}
