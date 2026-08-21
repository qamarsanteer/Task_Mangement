import 'package:equatable/equatable.dart';

class ProjectOption extends Equatable {
  final String projectId;
  final String projectName;
  final String workspaceId;
  final String workspaceName;

  const ProjectOption({
    required this.projectId,
    required this.projectName,
    required this.workspaceId,
    required this.workspaceName,
  });

  @override
  List<Object?> get props => [projectId, projectName, workspaceId, workspaceName];
}