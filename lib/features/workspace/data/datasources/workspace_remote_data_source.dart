import '../../../../core/network/dio_client.dart';
import '../models/workspace_model.dart';

abstract class WorkspaceRemoteDataSource {
  Future<List<WorkspaceModel>> getWorkspaces();
  Future<WorkspaceModel> createWorkspace(String name);
  Future<void> deleteWorkspace(String workspaceId);
}

class WorkspaceRemoteDataSourceImpl implements WorkspaceRemoteDataSource {
  final DioClient _dioClient;

  WorkspaceRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<List<WorkspaceModel>> getWorkspaces() async {
    final response = await _dioClient.get('/workspaces');
    final data = response.data['data'] ?? response.data;
    return (data as List).map((json) => WorkspaceModel.fromJson(json)).toList();
  }

  @override
  Future<WorkspaceModel> createWorkspace(String name) async {
    final response = await _dioClient.post('/workspaces', data: {'name': name});
    return WorkspaceModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<void> deleteWorkspace(String workspaceId) async {
    await _dioClient.delete('/workspaces/$workspaceId');
  }
}