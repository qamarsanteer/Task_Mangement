import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthStatusChecked extends AuthEvent {
  const AuthStatusChecked();
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;
  const SignInRequested({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  const SignUpRequested({
    required this.fullName,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
  @override
  List<Object?> get props => [fullName, email, password, confirmPassword];
}

class PhotoUploadRequested extends AuthEvent {
  final String userId;
  final String photoPath;
  const PhotoUploadRequested({required this.userId, required this.photoPath});
  @override
  List<Object?> get props => [userId, photoPath];
}

class UpdateProfileRequested extends AuthEvent {
  final String userId;
  final String fullName;
  final String email;
  const UpdateProfileRequested({
    required this.userId,
    required this.fullName,
    required this.email,
  });
  @override
  List<Object?> get props => [userId, fullName, email];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
