import 'package:dio/dio.dart';
import 'failure.dart';

class DioErrorMapper {
  static Failure map(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('انتهت مهلة الاتصال. تحقق من الإنترنت.');

      case DioExceptionType.connectionError:
        return const NetworkFailure('لا يوجد اتصال بالإنترنت.');

      case DioExceptionType.badResponse:
        return _mapResponseError(error);

      case DioExceptionType.cancel:
        return const UnknownFailure('تم إلغاء الطلب.');

      default:
        return const UnknownFailure('حدث خطأ غير متوقع.');
    }
  }

  static Failure _mapResponseError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String message = 'حدث خطأ بالسيرفر.';
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    }

    switch (statusCode) {
      case 401:
        return UnauthorizedFailure(message);
      case 422:
        return ValidationFailure(message);
      default:
        return ServerFailure(message);
    }
  }
}