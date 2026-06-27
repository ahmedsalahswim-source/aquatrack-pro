import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/repositories/ai_repository.dart';

class SendMessageUseCase {
  final AiRepository repository;

  SendMessageUseCase({required this.repository});

  Future<Either<Failure, AiMessageEntity>> call({
    required String userId,
    required String athleteId,
    required String athleteName,
    required String question,
    required Map<String, dynamic> context,
    List<AiMessageEntity> history = const [],
  }) {
    return repository.sendMessage(
      userId: userId,
      athleteId: athleteId,
      athleteName: athleteName,
      question: question,
      context: context,
      history: history,
    );
  }
}
