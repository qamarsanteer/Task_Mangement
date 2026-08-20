import 'package:equatable/equatable.dart';

abstract class ProjectInviteState extends Equatable {
  const ProjectInviteState();
  @override
  List<Object?> get props => [];
}

class ProjectInviteInitial extends ProjectInviteState {}

class ProjectInviteLoading extends ProjectInviteState {}

class ProjectInviteSuccess extends ProjectInviteState {
  final String email;
  const ProjectInviteSuccess(this.email);
  @override
  List<Object?> get props => [email];
}

class ProjectInviteFailure extends ProjectInviteState {
  final String message;
  const ProjectInviteFailure(this.message);
  @override
  List<Object?> get props => [message];
}