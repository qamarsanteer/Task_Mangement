import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;
  RegisterUseCase(this.repository);
  Future<Either<Failure, UserEntity>> call({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) {
    return repository.signUp(
      fullName: fullName,
      email: email,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}