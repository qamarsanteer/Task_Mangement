import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';
import 'task_remote_data_source.dart';

class TaskMockDataSource implements TaskRemoteDataSource {
  final Map<String, List<TaskModel>> _tasksByProject = {};

  @override
  Future<List<TaskModel>> getTasks(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_tasksByProject[projectId] ?? []);
  }

  @override
  Future<TaskModel> createTask({
    required String projectId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    DateTime? startDate, 
    bool hasStartTime = false, 
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newTask = TaskModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      status: TaskStatus.notStarted,
      isImportant: isImportant,
      isUrgent: isUrgent,
      dueDate: dueDate,
      startDate: startDate,
      hasStartTime: hasStartTime, 
      projectId: projectId,
      createdAt: DateTime.now(),
      labelId: labelId,
      repeatFrequency: repeatFrequency,
    );
    _tasksByProject.putIfAbsent(projectId, () => []).add(newTask);
    return newTask;
  }

  @override
  Future<TaskModel> updateTaskStatus({required String taskId, required TaskStatus status}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    for (final list in _tasksByProject.values) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final updated = TaskModel(
          id: list[index].id,
          title: list[index].title,
          description: list[index].description,
          status: status,
          isImportant: list[index].isImportant,
          isUrgent: list[index].isUrgent,
          dueDate: list[index].dueDate,
          startDate: list[index].startDate, 
          hasStartTime: list[index].hasStartTime, 
          projectId: list[index].projectId,
          createdAt: list[index].createdAt,
          labelId: list[index].labelId,
          attachmentUrls: list[index].attachmentUrls,
          repeatFrequency: list[index].repeatFrequency,
        );
        list[index] = updated;
        return updated;
      }
    }
    throw Exception('Task not found');
  }

  @override
  Future<TaskModel> updateTask({
    required String taskId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    DateTime? startDate,
    bool? hasStartTime,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    for (final list in _tasksByProject.values) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final updated = TaskModel(
          id: list[index].id,
          title: title,
          description: description,
          status: list[index].status,
          isImportant: isImportant,
          isUrgent: isUrgent,
          dueDate: dueDate,
          startDate: startDate ?? list[index].startDate,
          hasStartTime: hasStartTime ?? list[index].hasStartTime, 
          projectId: list[index].projectId,
          createdAt: list[index].createdAt,
          labelId: labelId,
          attachmentUrls: list[index].attachmentUrls,
          repeatFrequency: repeatFrequency,
        );
        list[index] = updated;
        return updated;
      }
    }
    throw Exception('Task not found');
  }

  @override
  Future<List<String>> uploadAttachments({required String taskId, required List<String> filePaths}) async {
    await Future.delayed(const Duration(milliseconds: 700));
    for (final list in _tasksByProject.values) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final updated = TaskModel(
          id: list[index].id,
          title: list[index].title,
          description: list[index].description,
          status: list[index].status,
          isImportant: list[index].isImportant,
          isUrgent: list[index].isUrgent,
          dueDate: list[index].dueDate,
          startDate: list[index].startDate,
          projectId: list[index].projectId,
          createdAt: list[index].createdAt,
          labelId: list[index].labelId,
          attachmentUrls: filePaths,
          repeatFrequency: list[index].repeatFrequency,
        );
        list[index] = updated;
      }
    }
    return filePaths;
  }

  @override
  Future<TaskModel> removeAttachment({required String taskId, required String attachmentUrl}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    for (final list in _tasksByProject.values) {
      final index = list.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final updated = TaskModel(
          id: list[index].id,
          title: list[index].title,
          description: list[index].description,
          status: list[index].status,
          isImportant: list[index].isImportant,
          isUrgent: list[index].isUrgent,
          dueDate: list[index].dueDate,
          startDate: list[index].startDate, 
          projectId: list[index].projectId,
          createdAt: list[index].createdAt,
          labelId: list[index].labelId,
          attachmentUrls: list[index].attachmentUrls.where((u) => u != attachmentUrl).toList(),
          repeatFrequency: list[index].repeatFrequency,
        );
        list[index] = updated;
        return updated;
      }
    }
    throw Exception('Task not found');
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    for (final list in _tasksByProject.values) {
      list.removeWhere((t) => t.id == taskId);
    }
  }

  @override
  Future<TaskModel> updateTaskProject({required String taskId, required String newProjectId}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    for (final entry in _tasksByProject.entries) {
      final index = entry.value.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final old = entry.value[index];
        final moved = TaskModel(
          id: old.id,
          title: old.title,
          description: old.description,
          status: old.status,
          isImportant: old.isImportant,
          isUrgent: old.isUrgent,
          dueDate: old.dueDate,
          startDate: old.startDate, 
          hasStartTime: old.hasStartTime, 
          projectId: newProjectId,
          createdAt: old.createdAt,
          labelId: old.labelId,
          attachmentUrls: old.attachmentUrls,
          repeatFrequency: old.repeatFrequency,
        );
        entry.value.removeAt(index);
        _tasksByProject.putIfAbsent(newProjectId, () => []).add(moved);
        return moved;
      }
    }
    throw Exception('Task not found');
  }
}