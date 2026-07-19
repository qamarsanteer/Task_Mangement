import '../models/project_model.dart';
import 'project_remote_data_source.dart';

/// نسخة وهمية (mock) — بتحتفظ بالمشاريع بالذاكرة، مرتبة حسب workspaceId
class ProjectMockDataSource implements ProjectRemoteDataSource {
  final Map<String, List<ProjectModel>> _projectsByWorkspace = {
    '1': [
      ProjectModel(id: 'p1', name: 'Project 1', workspaceId: '1', createdAt: DateTime.now()),
      ProjectModel(id: 'p2', name: 'Project 2', workspaceId: '1', createdAt: DateTime.now()),
    ],
  };

  @override
  Future<List<ProjectModel>> getProjects(String workspaceId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_projectsByWorkspace[workspaceId] ?? []);
  }

  @override
  Future<ProjectModel> createProject({required String workspaceId, required String name}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newProject = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      workspaceId: workspaceId,
      createdAt: DateTime.now(),
    );
    _projectsByWorkspace.putIfAbsent(workspaceId, () => []).add(newProject);
    return newProject;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    for (final list in _projectsByWorkspace.values) {
      list.removeWhere((p) => p.id == projectId);
    }
  }
}