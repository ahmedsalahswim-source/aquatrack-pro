import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> loginWithEmail(String email, String password);
  Future<Either<Failure, UserEntity>> registerWithEmail(
    String email,
    String password,
    String displayName,
  );
  Future<Either<Failure, UserEntity>> loginWithGoogle();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, void>> updateConsent(bool consented);
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);
  Stream<UserEntity?> get authStateChanges;
}
