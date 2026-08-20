import '../../../../core/network/dio_client.dart';
import '../../domain/entities/project_member_role.dart';
import '../models/project_model.dart';
import '../models/project_member_model.dart';

abstract class ProjectRemoteDataSource {
  Future<List<ProjectModel>> getProjects(String workspaceId);

  Future<ProjectModel> createProject({
    required String workspaceId,
    required String name,
    String? description,
  });

  Future<void> deleteProject(String projectId);

  Future<void> inviteMember({
    required String projectId,
    required String email,
    required ProjectMemberRole role,
  });

  Future<List<ProjectMemberModel>> getMembers(String projectId);
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
  Future<ProjectModel> createProject({
    required String workspaceId,
    required String name,
    String? description,
  }) async {
    final response = await _dioClient.post('/workspaces/$workspaceId/projects', data: {
      'name': name,
      if (description != null && description.trim().isNotEmpty) 'description': description.trim(),
    });
    return ProjectModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _dioClient.delete('/projects/$projectId');
  }

  @override
  Future<void> inviteMember({
    required String projectId,
    required String email,
    required ProjectMemberRole role,
  }) async {
    await _dioClient.post(
      '/projects/$projectId/members',
      data: {
        'email': email,
        'role': role.apiValue,
      },
    );
  }

  @override
  Future<List<ProjectMemberModel>> getMembers(String projectId) async {
    final response = await _dioClient.get('/projects/$projectId/members');
    final data = response.data['data'] ?? response.data;
    return (data as List).map((json) => ProjectMemberModel.fromJson(json)).toList();
  }
}