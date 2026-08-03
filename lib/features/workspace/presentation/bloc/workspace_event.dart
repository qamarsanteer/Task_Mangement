import 'package:equatable/equatable.dart';

abstract class WorkspaceEvent extends Equatable {
  const WorkspaceEvent();
  @override
  List<Object?> get props => [];
}

class WorkspacesLoadRequested extends WorkspaceEvent {
  const WorkspacesLoadRequested();
}

class WorkspaceCreateRequested extends WorkspaceEvent {
  final String name;
  const WorkspaceCreateRequested(this.name);
  @override
  List<Object?> get props => [name];
}

class WorkspaceDeleteRequested extends WorkspaceEvent {
  final String workspaceId;
  const WorkspaceDeleteRequested(this.workspaceId);
  @override
  List<Object?> get props => [workspaceId];
}

class WorkspacesDeleteRequested extends WorkspaceEvent {
  final List<String> workspaceIds;
  const WorkspacesDeleteRequested(this.workspaceIds);
  @override
  List<Object?> get props => [workspaceIds];
}
