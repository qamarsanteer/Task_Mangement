import '../models/workspace_model.dart';
import 'workspace_remote_data_source.dart';

class WorkspaceMockDataSource implements WorkspaceRemoteDataSource {
  final List<WorkspaceModel> _workspaces = [
    WorkspaceModel(id: '1', name: 'Workspace 1', createdAt: DateTime.now()),
    WorkspaceModel(id: '2', name: 'Workspace 2', createdAt: DateTime.now()),
  ];

  @override
  Future<List<WorkspaceModel>> getWorkspaces() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_workspaces);
  }

  @override
  Future<WorkspaceModel> createWorkspace(String name) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newWorkspace = WorkspaceModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
    );
    _workspaces.add(newWorkspace);
    return newWorkspace;
  }

  @override
  Future<void> deleteWorkspace(String workspaceId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _workspaces.removeWhere((w) => w.id == workspaceId);
  }
}