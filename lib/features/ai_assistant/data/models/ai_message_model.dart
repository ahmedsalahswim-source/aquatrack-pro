import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';

class AiMessageModel extends AiMessageEntity {
  const AiMessageModel({
    required super.id,
    required super.userId,
    required super.athleteId,
    required super.question,
    required super.answer,
    super.citations = const [],
    super.category = AiCategory.general,
    super.trigger = AiTrigger.userQuery,
    required super.timestamp,
    super.feedback,
  });

  factory AiMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AiMessageModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      athleteId: data['athleteId'] as String? ?? '',
      question: data['question'] as String? ?? '',
      answer: data['answer'] as String? ?? '',
      citations: (data['citations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      category: data['category'] != null
          ? AiCategory.values.firstWhere(
              (e) => e.name == data['category'],
              orElse: () => AiCategory.general,
            )
          : AiCategory.general,
      trigger: data['trigger'] != null
          ? AiTrigger.values.firstWhere(
              (e) => e.name == data['trigger'],
              orElse: () => AiTrigger.userQuery,
            )
          : AiTrigger.userQuery,
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      feedback: data['feedback'] != null
          ? UserFeedback.values.firstWhere(
              (e) => e.name == data['feedback'],
              orElse: () => UserFeedback.helpful,
            )
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'athleteId': athleteId,
      'question': question,
      'answer': answer,
      'citations': citations,
      'category': category.name,
      'trigger': trigger.name,
      'timestamp': Timestamp.fromDate(timestamp),
      'feedback': feedback?.name,
    };
  }

  factory AiMessageModel.fromGeminiResponse({
    required String userId,
    required String athleteId,
    required String question,
    required String answer,
    required List<String> citations,
    required AiCategory category,
    DateTime? timestamp,
  }) {
    return AiMessageModel(
      id: '${(timestamp ?? DateTime.now()).millisecondsSinceEpoch}_${question.hashCode}',
      userId: userId,
      athleteId: athleteId,
      question: question,
      answer: answer,
      citations: citations,
      category: category,
      timestamp: timestamp ?? DateTime.now(),
    );
  }
}
