import 'package:dartz/dartz.dart';
import '../../../../core/error/failure.dart';
import '../entities/task_entity.dart';
import '../repositories/task_repository.dart';

class UpdateTaskUseCase {
  final TaskRepository repository;
  UpdateTaskUseCase(this.repository);

  Future<Either<Failure, TaskEntity>> call({
    required String taskId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  }) {
    return repository.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      isImportant: isImportant,
      isUrgent: isUrgent,
      dueDate: dueDate,
      labelId: labelId,
      repeatFrequency: repeatFrequency,
    );
  }
}