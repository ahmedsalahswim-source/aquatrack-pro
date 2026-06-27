import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/repositories/ai_repository.dart';

class GetMessagesUsedTodayUseCase {
  final AiRepository repository;

  GetMessagesUsedTodayUseCase({required this.repository});

  Future<Either<Failure, int>> call(String userId) {
    return repository.getMessagesUsedToday(userId);
  }
}
