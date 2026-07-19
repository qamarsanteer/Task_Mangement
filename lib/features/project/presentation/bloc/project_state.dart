import 'package:equatable/equatable.dart';
import '../../domain/entities/project_entity.dart';

abstract class ProjectState extends Equatable {
  const ProjectState();
  @override
  List<Object?> get props => [];
}

class ProjectInitial extends ProjectState {}

class ProjectLoading extends ProjectState {}

class ProjectLoaded extends ProjectState {
  final List<ProjectEntity> projects;
  final bool isMutating;

  const ProjectLoaded({required this.projects, this.isMutating = false});

  @override
  List<Object?> get props => [projects, isMutating];
}

class ProjectError extends ProjectState {
  final String message;
  final List<ProjectEntity> projects;

  const ProjectError({required this.message, required this.projects});

  @override
  List<Object?> get props => [message, projects];
}