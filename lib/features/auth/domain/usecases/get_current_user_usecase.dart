import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';
import 'package:aquatrack_pro/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUserUseCase {
  final AuthRepository repository;

  GetCurrentUserUseCase({required this.repository});

  Future<Either<Failure, UserEntity>> call() {
    return repository.getCurrentUser();
  }
}
