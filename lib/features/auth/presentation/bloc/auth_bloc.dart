import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/storage/token_storage.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/upload_photo_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final UploadPhotoUseCase _uploadPhotoUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final TokenStorage _tokenStorage;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required UploadPhotoUseCase uploadPhotoUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    TokenStorage? tokenStorage,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _uploadPhotoUseCase = uploadPhotoUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _tokenStorage = tokenStorage ?? TokenStorage(),
        super(AuthInitial()) {
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<SignInRequested>(_onSignInRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<PhotoUploadRequested>(_onPhotoUploadRequested);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onAuthStatusChecked(AuthStatusChecked event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final hasToken = await _tokenStorage.hasToken();
    if (!hasToken) {
      emit(AuthUnauthenticated());
      return;
    }

    final result = await _getCurrentUserUseCase();
    await result.fold(
      (failure) async {
        await _tokenStorage.deleteToken();
        emit(AuthUnauthenticated());
      },
      (user) async => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onSignInRequested(SignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _loginUseCase(email: event.email, password: event.password);

    await result.fold(
      (failure) async => emit(AuthError(_mapFailureToMessage(failure))),
      (user) async {
        await _tokenStorage.saveToken(user.token);
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onSignUpRequested(SignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _registerUseCase(
      fullName: event.fullName,
      email: event.email,
      password: event.password,
      confirmPassword: event.confirmPassword,
    );

    await result.fold(
      (failure) async => emit(AuthError(_mapFailureToMessage(failure))),
      (user) async {
        await _tokenStorage.saveToken(user.token);
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> _onPhotoUploadRequested(PhotoUploadRequested event, Emitter<AuthState> emit) async {
    final previousState = state;
    emit(AuthLoading());

    final result = await _uploadPhotoUseCase(event.userId, event.photoPath);

    result.fold(
      (failure) => emit(AuthError(_mapFailureToMessage(failure))),
      (photoUrl) {
        if (previousState is AuthAuthenticated) {
          emit(AuthAuthenticated(previousState.user.copyWith(photoUrl: photoUrl)));
        } else {
          emit(AuthError('User session not found.'));
        }
      },
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await _tokenStorage.deleteToken();
    emit(AuthUnauthenticated());
  }

  String _mapFailureToMessage(Failure failure) {
    return failure.message;
  }
}