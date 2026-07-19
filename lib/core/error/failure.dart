import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// خطأ من السيرفر (4xx, 5xx) مع رسالة واضحة من الـ response
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// ما في اتصال إنترنت أو الطلب انقطع (timeout)
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// 401 — التوكن منتهي أو غير صالح
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

/// 422 أو أي خطأ validation من السيرفر
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// أي خطأ غير متوقع (parsing، null، الخ)
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}