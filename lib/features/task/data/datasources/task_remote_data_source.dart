import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/task_entity.dart';
import '../models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks(String projectId);

  Future<TaskModel> createTask({
    required String projectId,
    required String title,
    String? description,
    bool isImportant,
    bool isUrgent,
    DateTime? dueDate,
    String? labelId,
    RepeatFrequency repeatFrequency,
  });

  Future<TaskModel> updateTaskStatus({required String taskId, required TaskStatus status});

  Future<TaskModel> updateTask({
    required String taskId,
    required String title,
    String? description,
    bool isImportant,
    bool isUrgent,
    DateTime? dueDate,
    String? labelId,
    RepeatFrequency repeatFrequency,
  });

  Future<List<String>> uploadAttachments({required String taskId, required List<String> filePaths});

  Future<TaskModel> removeAttachment({required String taskId, required String attachmentUrl});

  Future<void> deleteTask(String taskId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final DioClient _dioClient;

  TaskRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<List<TaskModel>> getTasks(String projectId) async {
    final response = await _dioClient.get('/projects/$projectId/tasks');
    final data = response.data['data'] ?? response.data;
    return (data as List).map((json) => TaskModel.fromJson(json)).toList();
  }

  @override
  Future<TaskModel> createTask({
    required String projectId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  }) async {
    final response = await _dioClient.post('/projects/$projectId/tasks', data: {
      'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      'is_important': isImportant,
      'is_urgent': isUrgent,
      if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      if (labelId != null) 'label_id': labelId,
      'repeat_frequency': TaskModel.repeatToString(repeatFrequency),
    });
    return TaskModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<TaskModel> updateTaskStatus({required String taskId, required TaskStatus status}) async {
    final response = await _dioClient.put('/tasks/$taskId/status', data: {
      'status': TaskModel.statusToString(status),
    });
    return TaskModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<TaskModel> updateTask({
    required String taskId,
    required String title,
    String? description,
    bool isImportant = false,
    bool isUrgent = false,
    DateTime? dueDate,
    String? labelId,
    RepeatFrequency repeatFrequency = RepeatFrequency.none,
  }) async {
    // منبعت description / due_date / label_id حتى لو null، حتى يقدر
    // المستخدم يمسح قيمة كانت موجودة (متل حذف تاريخ الاستحقاق).
    final response = await _dioClient.put('/tasks/$taskId', data: {
      'title': title,
      'description': description,
      'is_important': isImportant,
      'is_urgent': isUrgent,
      'due_date': dueDate?.toIso8601String(),
      'label_id': labelId,
      'repeat_frequency': TaskModel.repeatToString(repeatFrequency),
    });
    return TaskModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<List<String>> uploadAttachments({required String taskId, required List<String> filePaths}) async {
    final formData = FormData();
    for (final path in filePaths) {
      formData.files.add(MapEntry('attachments[]', await MultipartFile.fromFile(path)));
    }
    final response = await _dioClient.dio.post('/tasks/$taskId/attachments', data: formData);
    final data = response.data['data'] ?? response.data;
    return (data as List).map((e) => e.toString()).toList();
  }

  @override
  Future<TaskModel> removeAttachment({required String taskId, required String attachmentUrl}) async {
    final response = await _dioClient.delete('/tasks/$taskId/attachments', data: {
      'url': attachmentUrl,
    });
    return TaskModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _dioClient.delete('/tasks/$taskId');
  }
}