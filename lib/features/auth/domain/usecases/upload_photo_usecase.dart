import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/auth_repository.dart';

class UploadPhotoUseCase {
  final AuthRepository repository;
  UploadPhotoUseCase(this.repository);

  Future<Either<Failure, String>> call(String userId, String photoPath) {
    return repository.uploadPhoto(userId, photoPath);
  }
}