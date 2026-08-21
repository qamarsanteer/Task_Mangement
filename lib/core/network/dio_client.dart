import 'package:dio/dio.dart';
import '../storage/token_storage.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio dio;
  late final TokenStorage _tokenStorage;

  factory DioClient() => _instance;

  DioClient._internal() {
    _tokenStorage = TokenStorage();

    dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.masar.app/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      LogInterceptor(requestBody: true, responseBody: true, logPrint: (object) => print(object.toString())),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            _tokenStorage.deleteToken();
            // TODO: لاحقاً هون رح نضيف logout event لما نعمل GetIt + auth state management أشمل
          }
          return handler.next(error);
        },
      ),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }

  Future<Response> put(String path, {dynamic data}) async {
    return await dio.put(path, data: data);
  }

  Future<Response> delete(String path, {dynamic data}) async {
    return await dio.delete(path, data: data);
  }
}