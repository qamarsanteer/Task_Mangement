import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/dio_client.dart';
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

final getIt = GetIt.instance;

/// غيّر هاد المتغير لـ false لما يجهز السيرفر الحقيقي
const bool _useMockData = true;

Future<void> setupServiceLocator() async {
  // ---------- External ----------
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerLazySingleton<SharedPreferences>(() => sharedPreferences);

  // ---------- Core ----------
  getIt.registerLazySingleton<DioClient>(() => DioClient());
  getIt.registerLazySingleton<TokenStorage>(() => TokenStorage());
  getIt.registerLazySingleton<AppPreferences>(() => AppPreferences(getIt()));

  // ---------- Core Blocs (theme / locale) ----------
  getIt.registerFactory(() => ThemeBloc(appPreferences: getIt()));
  getIt.registerFactory(() => LocaleBloc(appPreferences: getIt()));

  // ---------- Auth: Data sources ----------
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => _useMockData
        ? AuthMockDataSource()
        : AuthRemoteDataSourceImpl(dioClient: getIt()),
  );

  // ---------- Auth: Repository ----------
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: getIt()),
  );

  // ---------- Auth: Use cases ----------
  getIt.registerLazySingleton(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadPhotoUseCase(getIt()));
  getIt.registerLazySingleton(() => GetCurrentUserUseCase(getIt()));

  // ---------- Auth: Bloc ----------
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt(),
      registerUseCase: getIt(),
      uploadPhotoUseCase: getIt(),
      getCurrentUserUseCase: getIt(),
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
  getIt.registerLazySingleton<WorkspaceRepository>(
    () => WorkspaceRepositoryImpl(remoteDataSource: getIt()),
  );

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
  getIt.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(remoteDataSource: getIt()),
  );

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
  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(remoteDataSource: getIt()),
  );

  // ---------- Task: Use cases ----------
  getIt.registerLazySingleton(() => GetTasksUseCase(getIt()));
  getIt.registerLazySingleton(() => CreateTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateTaskStatusUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteTaskUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadTaskAttachmentsUseCase(getIt()));

  // ---------- Task: Bloc ----------
  getIt.registerFactory(
    () => TaskBloc(
      getTasksUseCase: getIt(),
      createTaskUseCase: getIt(),
      updateTaskStatusUseCase: getIt(),
      uploadTaskAttachmentsUseCase: getIt(), 
      deleteTaskUseCase: getIt(),
    ),
  );
}