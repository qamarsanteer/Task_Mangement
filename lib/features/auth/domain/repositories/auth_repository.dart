import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> signIn({required String email, required String password});

  Future<Either<Failure, UserEntity>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<Either<Failure, String>> uploadPhoto(String userId, String photoPath);

  Future<Either<Failure, UserEntity>> getCurrentUser();
}