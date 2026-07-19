import 'package:equatable/equatable.dart';
import '../../domain/entities/workspace_entity.dart';

abstract class WorkspaceState extends Equatable {
  const WorkspaceState();
  @override
  List<Object?> get props => [];
}

class WorkspaceInitial extends WorkspaceState {}

class WorkspaceLoading extends WorkspaceState {}

class WorkspaceLoaded extends WorkspaceState {
  final List<WorkspaceEntity> workspaces;
  final bool isMutating;

  const WorkspaceLoaded({required this.workspaces, this.isMutating = false});

  WorkspaceLoaded copyWith({List<WorkspaceEntity>? workspaces, bool? isMutating}) {
    return WorkspaceLoaded(
      workspaces: workspaces ?? this.workspaces,
      isMutating: isMutating ?? this.isMutating,
    );
  }

  @override
  List<Object?> get props => [workspaces, isMutating];
}

class WorkspaceError extends WorkspaceState {
  final String message;
  final List<WorkspaceEntity> workspaces;

  const WorkspaceError({required this.message, required this.workspaces});

  @override
  List<Object?> get props => [message, workspaces];
}