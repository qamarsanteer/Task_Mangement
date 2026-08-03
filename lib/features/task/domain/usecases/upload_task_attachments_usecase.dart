import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/task_repository.dart';

class UploadTaskAttachmentsUseCase {
  final TaskRepository repository;
  UploadTaskAttachmentsUseCase(this.repository);

  Future<Either<Failure, List<String>>> call({
    required String taskId,
    required List<String> filePaths,
  }) {
    return repository.uploadAttachments(taskId: taskId, filePaths: filePaths);
  }
}