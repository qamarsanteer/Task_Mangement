import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class UpdateProfileUseCase {
  final AuthRepository _repository;

  UpdateProfileUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    return await _repository.updateProfile(
      userId: userId,
      fullName: fullName,
      email: email,
    );
  }
}
