import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;
  LoginUseCase(this.repository);
  Future<Either<Failure, UserEntity>> call({required String email, required String password}) {
    return repository.signIn(email: email, password: password);
  }
}