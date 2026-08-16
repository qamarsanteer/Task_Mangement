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
import '../../features/project/presentation/bloc/project_bloc.dart';

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
import '../../features/task/domain/usecases/update_task_status_usecase.dart';
import '../../features/task/domain/usecases/update_task_usecase.dart';

final getIt = GetIt.instance;

/// غيّر هاد المتغير لـ false لما يجهز السيرفر الحقيقي
const bool _useMockData = true;

Future<void> setupServiceLocator() async {
  // ---------- External ----------
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton(() => sharedPreferences);

  // ---------- Core ----------
  getIt.registerLazySingleton(() => DioClient());
  getIt.registerLazySingleton(() => TokenStorage());
  getIt.registerLazySingleton(() => AppPreferences(getIt()));
  getIt.registerLazySingleton(() => ConnectivityService());
  getIt.registerLazySingleton(() => LocalCacheService(getIt()));

  // ---------- Core Blocs (theme / locale) ----------
  getIt.registerFactory(() => ThemeBloc(appPreferences: getIt()));
  getIt.registerFactory(() => LocaleBloc(appPreferences: getIt()));

  // ---------- Auth: Data sources ----------
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => _useMockData
        ? AuthMockDataSource(prefs: getIt())
        : AuthRemoteDataSourceImpl(dioClient: getIt()),
  );

  // ---------- Auth: Repository ----------
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: getIt(),
    cache: getIt(),
    connectivityService: getIt(),
  );
  getIt.registerLazySingleton<AuthRepository>(() => authRepository);

  // ---------- Auth: Use cases ----------
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadPhotoUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateProfileUseCase(getIt()));

  // ---------- Auth: Bloc ----------
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt(),
      registerUseCase: getIt(),
      uploadPhotoUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
      updateProfileUseCase: getIt(),
      tokenStorage: getIt(),
    ),
  );

  // ---------- Workspace: Data sources ----------
  getIt.registerLazySingleton<WorkspaceRemoteDataSource>(
    () => _useMockData
        ? WorkspaceMockDataSource()
        : WorkspaceRemoteDataSourceImpl(dioClient: getIt()),
  );

  // ---------- Workspace: Repository ----------
  final workspaceRepository = WorkspaceRepositoryImpl(
    remoteDataSource: getIt(),
    cache: getIt(),
    connectivityService: getIt(),
  );
  getIt.registerLazySingleton<WorkspaceRepository>(() => workspaceRepository);

  // ---------- Workspace: Use cases ----------
  getIt.registerLazySingleton(() => GetWorkspacesUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateWorkspaceUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteWorkspaceUseCase(getIt()));

  // ---------- Workspace: Bloc ----------
  getIt.registerFactory(
    () => WorkspaceBloc(
      getWorkspacesUseCase: getIt(),
      createWorkspaceUseCase: getIt(),
      deleteWorkspaceUseCase: getIt(),
    ),
  );

  // ---------- Project: Data sources ----------
  getIt.registerLazySingleton<ProjectRemoteDataSource>(
    () => _useMockData
        ? ProjectMockDataSource()
        : ProjectRemoteDataSourceImpl(dioClient: getIt()),
  );

  // ---------- Project: Repository ----------
  final projectRepository = ProjectRepositoryImpl(
    remoteDataSource: getIt(),
    cache: getIt(),
    connectivityService: getIt(),
  );
  getIt.registerLazySingleton<ProjectRepository>(() => projectRepository);

  // ---------- Project: Use cases ----------
  getIt.registerLazySingleton(() => GetProjectsUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateProjectUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteProjectUseCase(getIt()));

  // ---------- Project: Bloc ----------
  getIt.registerFactory(
    () => ProjectBloc(
      getProjectsUseCase: getIt(),
      createProjectUseCase: getIt(),
      deleteProjectUseCase: getIt(),
    ),
  );

  // ---------- Task: Data sources ----------
  getIt.registerLazySingleton<TaskRemoteDataSource>(
    () => _useMockData
        ? TaskMockDataSource()
        : TaskRemoteDataSourceImpl(dioClient: getIt()),
  );

  // ---------- Task: Repository ----------
  final taskRepository = TaskRepositoryImpl(
    remoteDataSource: getIt(),
    cache: getIt(),
    connectivityService: getIt(),
  );
  getIt.registerLazySingleton<TaskRepository>(() => taskRepository);

  // ---------- Task: Use cases ----------
  getIt.registerLazySingleton(() => GetTasksUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateTaskStatusUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadTaskAttachmentsUseCase(getIt()));
  getIt.registerLazySingleton(() => RemoveTaskAttachmentUseCase(getIt()));

  // ---------- Task: Bloc ----------
  getIt.registerFactory(
    () => TaskBloc(
      getTasksUseCase: getIt(),
      createTaskUseCase: getIt(),
      updateTaskStatusUseCase: getIt(),
      updateTaskUseCase: getIt(),
      uploadTaskAttachmentsUseCase: getIt(),
      removeTaskAttachmentUseCase: getIt(),
      deleteTaskUseCase: getIt(),
    ),
  );

  // ---------- Sync ----------
  // كل Repository بيطبّق Syncable لازم ينضاف هون حتى يتزامن تلقائياً
  // لحظة رجوع الاتصال بالإنترنت.
  final syncables = <Syncable>[
    authRepository,
    workspaceRepository,
    projectRepository,
    taskRepository,
  ];
  getIt.registerLazySingleton(
    () => SyncManager(connectivityService: getIt(), syncables: syncables),
  );
}
