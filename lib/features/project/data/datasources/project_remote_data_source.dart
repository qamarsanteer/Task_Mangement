import '../../../../core/network/dio_client.dart';
import '../models/project_model.dart';

abstract class ProjectRemoteDataSource {
  Future<List<ProjectModel>> getProjects(String workspaceId);

  Future<ProjectModel> createProject({
    required String workspaceId,
    required String name,
  });

  Future<void> deleteProject(String projectId);
}

class ProjectRemoteDataSourceImpl implements ProjectRemoteDataSource {
  final DioClient _dioClient;

  ProjectRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<List<ProjectModel>> getProjects(String workspaceId) async {
    final response = await _dioClient.get('/workspaces/$workspaceId/projects');
    final data = response.data['data'] ?? response.data;
    return (data as List).map((json) => ProjectModel.fromJson(json)).toList();
  }

  @override
  Future<ProjectModel> createProject({required String workspaceId, required String name}) async {
    final response = await _dioClient.post('/workspaces/$workspaceId/projects', data: {'name': name});
    return ProjectModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _dioClient.delete('/projects/$projectId');
  }
}