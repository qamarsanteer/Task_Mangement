import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';
import '../network/connectivity_service.dart';
import '../cache/local_cache_service.dart';
import '../sync/sync_manager.dart';
import '../sync/syncable.dart';
import '../storage/token_storage.dart';
import '../storage/app_preferences.dart';
import '../bloc/theme/theme_bloc.dart';
import '../bloc/locale/locale_bloc.dart';
import '../events/task_changes_bus.dart';

import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/auth_mock_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/upload_photo_usecase.dart';
import '../../features/auth/domain/usecases/update_profile_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/workspace/data/datasources/workspace_remote_data_source.dart';
import '../../features/workspace/data/datasources/workspace_mock_data_source.dart';
import '../../features/workspace/data/repositories/workspace_repository_impl.dart';
import '../../features/workspace/domain/repositories/workspace_repository.dart';
import '../../features/workspace/domain/usecases/create_workspace_usecase.dart';
import '../../features/workspace/domain/usecases/delete_workspace_usecase.dart';
import '../../features/workspace/domain/usecases/get_workspaces_usecase.dart';
import '../../features/workspace/presentation/bloc/workspace_bloc.dart';

import '../../features/project/data/datasources/project_remote_data_source.dart';
import '../../features/project/data/datasources/project_mock_data_source.dart';
import '../../features/project/data/repositories/project_repository_impl.dart';
import '../../features/project/domain/repositories/project_repository.dart';
import '../../features/project/domain/usecases/create_project_usecase.dart';
import '../../features/project/domain/usecases/delete_project_usecase.dart';
import '../../features/project/domain/usecases/get_projects_usecase.dart';
import '../../features/project/domain/usecases/invite_project_member_usecase.dart';
import '../../features/project/domain/usecases/get_project_members_usecase.dart';
import '../../features/project/presentation/bloc/project_invite_bloc.dart';
import '../../features/project/presentation/bloc/project_members_bloc.dart';
import '../../features/project/presentation/bloc/project_bloc.dart';
import '../../features/project/presentation/cubit/project_picker_cubit.dart';

import '../../features/task/data/datasources/task_remote_data_source.dart';
import '../../features/task/data/datasources/task_mock_data_source.dart';
import '../../features/task/data/repositories/task_repository_impl.dart';
import '../../features/task/domain/repositories/task_repository.dart';
import '../../features/task/domain/usecases/create_task_usecase.dart';
import '../../features/task/domain/usecases/delete_task_usecase.dart';
import '../../features/task/domain/usecases/get_tasks_usecase.dart';
import '../../features/task/domain/usecases/update_task_status_usecase.dart';
import '../../features/task/presentation/bloc/task_bloc.dart';
import '../../features/task/domain/usecases/upload_task_attachments_usecase.dart';
import '../../features/task/domain/usecases/remove_task_attachment_usecase.dart';
import '../../features/task/domain/usecases/update_task_usecase.dart';
import '../../features/task/domain/usecases/move_task_to_project_usecase.dart';

import '../../features/bin/data/repositories/bin_repository_impl.dart';
import '../../features/bin/domain/repositories/bin_repository.dart';
import '../../features/bin/domain/usecases/delete_task_forever_usecase.dart';
import '../../features/bin/domain/usecases/get_deleted_tasks_usecase.dart';
import '../../features/bin/domain/usecases/restore_task_usecase.dart';
import '../../features/bin/domain/usecases/get_deleted_projects_usecase.dart';
import '../../features/bin/domain/usecases/restore_project_usecase.dart';
import '../../features/bin/domain/usecases/delete_project_forever_usecase.dart';
import '../../features/bin/presentation/bloc/bin_bloc.dart';

import '../../features/calendar/presentation/bloc/calendar_bloc.dart';

final getIt = GetIt.instance;
const bool _useMockData = true;

Future<void> setupServiceLocator() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  getIt.registerLazySingleton(() => DioClient());
  getIt.registerLazySingleton(() => TokenStorage());
  getIt.registerLazySingleton(() => AppPreferences(getIt()));
  getIt.registerLazySingleton(() => ConnectivityService());
  getIt.registerLazySingleton(() => LocalCacheService(getIt()));
  getIt.registerLazySingleton(() => TaskChangesBus());

  getIt.registerFactory(() => ThemeBloc(appPreferences: getIt()));
  getIt.registerFactory(() => LocaleBloc(appPreferences: getIt()));

  getIt.registerLazySingleton(
    () => _useMockData ? AuthMockDataSource(prefs: getIt()) : AuthRemoteDataSourceImpl(dioClient: getIt()),
  );

  final authRepository = AuthRepositoryImpl(remoteDataSource: getIt(), cache: getIt(), connectivityService: getIt());
  getIt.registerLazySingleton<AuthRepository>(() => authRepository);

  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadPhotoUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateProfileUseCase(getIt()));

  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt(), registerUseCase: getIt(), uploadPhotoUseCase: getIt(),
      getCurrentUserUseCase: getIt(), updateProfileUseCase: getIt(), tokenStorage: getIt(),
    ),
  );

  getIt.registerLazySingleton(
    () => _useMockData ? WorkspaceMockDataSource() : WorkspaceRemoteDataSourceImpl(dioClient: getIt()),
  );

  final workspaceRepository = WorkspaceRepositoryImpl(remoteDataSource: getIt(), cache: getIt(), connectivityService: getIt());
  getIt.registerLazySingleton<WorkspaceRepository>(() => workspaceRepository);

  getIt.registerLazySingleton(() => GetWorkspacesUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateWorkspaceUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteWorkspaceUseCase(getIt()));

  getIt.registerFactory(
    () => WorkspaceBloc(getWorkspacesUseCase: getIt(), createWorkspaceUseCase: getIt(), deleteWorkspaceUseCase: getIt()),
  );

  getIt.registerLazySingleton(
    () => _useMockData ? TaskMockDataSource() : TaskRemoteDataSourceImpl(dioClient: getIt()),
  );

  
getIt.registerLazySingleton(
  () => _useMockData ? ProjectMockDataSource() : ProjectRemoteDataSourceImpl(dioClient: getIt()),
);

final taskRepository = TaskRepositoryImpl(
  remoteDataSource: getIt(),
  projectRemoteDataSource: getIt(), // ← جديد
  cache: getIt(),
  connectivityService: getIt(),
  taskChangesBus: getIt(),
);
getIt.registerLazySingleton<TaskRepository>(() => taskRepository);

getIt.registerLazySingleton(() => GetTasksUseCase(getIt()));
getIt.registerLazySingleton(() => CreateTaskUseCase(getIt()));
getIt.registerLazySingleton(() => UpdateTaskStatusUseCase(getIt()));
getIt.registerLazySingleton(() => UpdateTaskUseCase(getIt()));
getIt.registerLazySingleton(() => DeleteTaskUseCase(getIt()));
getIt.registerLazySingleton(() => UploadTaskAttachmentsUseCase(getIt()));
getIt.registerLazySingleton(() => RemoveTaskAttachmentUseCase(getIt()));
getIt.registerLazySingleton(() => MoveTaskToProjectUseCase(getIt()));

getIt.registerFactory(
  () => TaskBloc(
    getTasksUseCase: getIt(), createTaskUseCase: getIt(), updateTaskStatusUseCase: getIt(),
    updateTaskUseCase: getIt(), uploadTaskAttachmentsUseCase: getIt(),
    removeTaskAttachmentUseCase: getIt(), deleteTaskUseCase: getIt(), moveTaskToProjectUseCase: getIt(),
  ),
);


final projectRepository = ProjectRepositoryImpl(
  remoteDataSource: getIt(), cache: getIt(), connectivityService: getIt(), taskRepository: getIt(),
);
getIt.registerLazySingleton<ProjectRepository>(() => projectRepository);

getIt.registerLazySingleton(() => GetProjectsUseCase(getIt()));
getIt.registerLazySingleton(() => CreateProjectUseCase(getIt()));
getIt.registerLazySingleton(() => DeleteProjectUseCase(getIt()));
getIt.registerLazySingleton(() => InviteProjectMemberUseCase(getIt()));
getIt.registerLazySingleton(() => GetProjectMembersUseCase(getIt()));

getIt.registerFactory(
  () => ProjectBloc(getProjectsUseCase: getIt(), createProjectUseCase: getIt(), deleteProjectUseCase: getIt()),
);
getIt.registerFactory(() => ProjectInviteBloc(inviteProjectMemberUseCase: getIt()));
getIt.registerFactory(() => ProjectMembersBloc(getProjectMembersUseCase: getIt()));

getIt.registerFactory(
  () => ProjectPickerCubit(getWorkspacesUseCase: getIt(), getProjectsUseCase: getIt()),
);

getIt.registerLazySingleton<BinRepository>(
  () => BinRepositoryImpl(taskRepository: getIt()),
);

getIt.registerLazySingleton(() => GetDeletedTasksUseCase(getIt()));
getIt.registerLazySingleton(() => RestoreTaskUseCase(getIt()));
getIt.registerLazySingleton(() => DeleteTaskForeverUseCase(getIt()));
getIt.registerLazySingleton(() => GetDeletedProjectsUseCase(getIt()));
getIt.registerLazySingleton(() => RestoreProjectUseCase(getIt()));
getIt.registerLazySingleton(() => DeleteProjectForeverUseCase(getIt()));

getIt.registerFactory(
  () => BinBloc(
    getDeletedTasksUseCase: getIt(), restoreTaskUseCase: getIt(), deleteTaskForeverUseCase: getIt(),
    getDeletedProjectsUseCase: getIt(), restoreProjectUseCase: getIt(), deleteProjectForeverUseCase: getIt(),
  ),
);

getIt.registerFactory(
  () => CalendarBloc(
    getWorkspacesUseCase: getIt(), getProjectsUseCase: getIt(), getTasksUseCase: getIt(),
    createTaskUseCase: getIt(), deleteTaskUseCase: getIt(), uploadTaskAttachmentsUseCase: getIt(),
  ),
);

  final syncables = <Syncable>[authRepository, workspaceRepository, projectRepository, taskRepository];
  getIt.registerLazySingleton(
    () => SyncManager(connectivityService: getIt(), syncables: syncables),
  );
}