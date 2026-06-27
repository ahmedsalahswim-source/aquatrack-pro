import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/auth/domain/repositories/auth_repository.dart';

class UpdateConsentUseCase {
  final AuthRepository repository;

  UpdateConsentUseCase({required this.repository});

  Future<Either<Failure, void>> call(bool consented) {
    return repository.updateConsent(consented);
  }
}
