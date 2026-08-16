import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../repositories/task_repository.dart';

class DeleteTaskUseCase {
  final TaskRepository repository;
  DeleteTaskUseCase(this.repository);

  Future<Either<Failure, void>> call(
    String taskId, {
    required String projectName,
    required String workspaceId,
    required String workspaceName,
  }) {
    return repository.deleteTask(
      taskId,
      projectName: projectName,
      workspaceId: workspaceId,
      workspaceName: workspaceName,
    );
  }
}