import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/invite_project_member_usecase.dart';
import 'project_invite_event.dart';
import 'project_invite_state.dart';

class ProjectInviteBloc extends Bloc<ProjectInviteEvent, ProjectInviteState> {
  final InviteProjectMemberUseCase _inviteProjectMemberUseCase;

  ProjectInviteBloc({required InviteProjectMemberUseCase inviteProjectMemberUseCase})
      : _inviteProjectMemberUseCase = inviteProjectMemberUseCase,
        super(ProjectInviteInitial()) {
    on<ProjectInviteMemberRequested>(_onInviteMemberRequested);
    on<ProjectInviteReset>((event, emit) => emit(ProjectInviteInitial()));
  }

  Future<void> _onInviteMemberRequested(
    ProjectInviteMemberRequested event,
    Emitter<ProjectInviteState> emit,
  ) async {
    emit(ProjectInviteLoading());

    final result = await _inviteProjectMemberUseCase(
      projectId: event.projectId,
      email: event.email,
    );

    result.fold(
      (failure) => emit(ProjectInviteFailure(failure.message)),
      (_) => emit(ProjectInviteSuccess(event.email)),
    );
  }
}