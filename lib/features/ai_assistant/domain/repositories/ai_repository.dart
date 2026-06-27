import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';

abstract class AiRepository {
  Future<Either<Failure, AiMessageEntity>> sendMessage({
    required String userId,
    required String athleteId,
    required String athleteName,
    required String question,
    required Map<String, dynamic> context,
    List<AiMessageEntity> history = const [],
  });

  Stream<String> sendMessageStream({
    required String userId,
    required String athleteId,
    required String athleteName,
    required String question,
    required Map<String, dynamic> context,
    List<AiMessageEntity> history = const [],
  });

  Future<Either<Failure, List<AiMessageEntity>>> getHistory({
    required String userId,
    required String athleteId,
  });

  Future<Either<Failure, int>> getMessagesUsedToday(String userId);

  Future<Either<Failure, void>> clearHistory(String userId, String athleteId);

  Future<Either<Failure, void>> updateFeedback(
    String messageId, UserFeedback feedback);
}
