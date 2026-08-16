import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class RemoveTaskAttachmentUseCase {
  final TaskRepository repository;
  RemoveTaskAttachmentUseCase(this.repository);

  Future<Either<Failure, TaskEntity>> call({
    required String taskId,
    required String attachmentUrl,
  }) {
    return repository.removeAttachment(taskId: taskId, attachmentUrl: attachmentUrl);
  }
}
