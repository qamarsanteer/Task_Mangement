import '../models/project_model.dart';
import '../models/project_member_model.dart';
import 'project_remote_data_source.dart';
import '../../domain/entities/project_member_role.dart';
import '../../domain/entities/project_member_entity.dart';

/// نسخة وهمية (mock) — بتحتفظ بالمشاريع بالذاكرة، مرتبة حسب workspaceId
class ProjectMockDataSource implements ProjectRemoteDataSource {
  final Map<String, List<ProjectModel>> _projectsByWorkspace = {
    '1': [
      ProjectModel(id: 'p1', name: 'Project 1', workspaceId: '1', createdAt: DateTime.now()),
      ProjectModel(id: 'p2', name: 'Project 2', workspaceId: '1', createdAt: DateTime.now()),
    ],
  };

  // خارطة أعضاء وهمية لكل مشروع — تحاكي جدول عضويات بالباك اند
  final Map<String, List<ProjectMemberModel>> _membersByProject = {
    'p1': [
      ProjectMemberModel(
        id: 'm1',
        userId: 'u1',
        email: 'sara@example.com',
        fullName: 'Sara Ahmad',
        avatarUrl: null,
        role: ProjectMemberRole.readWrite,
        status: InviteStatus.accepted,
        invitedAt: DateTime.now().subtract(const Duration(days: 5)),
        joinedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      ProjectMemberModel(
        id: 'm2',
        email: 'khaled@example.com',
        role: ProjectMemberRole.readOnly,
        status: InviteStatus.pending,
        invitedAt: DateTime.now().subtract(const Duration(hours: 3)),
      ),
    ],
  };

  @override
  Future<List<ProjectModel>> getProjects(String workspaceId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_projectsByWorkspace[workspaceId] ?? []);
  }

  @override
  Future<ProjectModel> createProject({
    required String workspaceId,
    required String name,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final trimmedDescription = description?.trim();
    final newProject = ProjectModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      description: (trimmedDescription == null || trimmedDescription.isEmpty) ? null : trimmedDescription,
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

  @override
  Future<void> inviteMember({
    required String projectId,
    required String email,
    required ProjectMemberRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newMember = ProjectMemberModel(
      id: 'local_member_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      role: role,
      status: InviteStatus.pending,
      invitedAt: DateTime.now(),
    );
    _membersByProject.putIfAbsent(projectId, () => []).add(newMember);
  }

  @override
  Future<List<ProjectMemberModel>> getMembers(String projectId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_membersByProject[projectId] ?? []);
  }
}