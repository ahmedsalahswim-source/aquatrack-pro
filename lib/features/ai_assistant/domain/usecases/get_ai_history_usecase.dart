import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/repositories/ai_repository.dart';

class GetAiHistoryUseCase {
  final AiRepository repository;

  GetAiHistoryUseCase({required this.repository});

  Future<Either<Failure, List<AiMessageEntity>>> call({
    required String userId,
    required String athleteId,
  }) {
    return repository.getHistory(userId: userId, athleteId: athleteId);
  }
}
