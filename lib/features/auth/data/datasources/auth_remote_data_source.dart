import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});

  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  });

  Future<String> uploadPhoto(String userId, String photoPath);

  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl({required DioClient dioClient}) : _dioClient = dioClient;

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    final response = await _dioClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return UserModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _dioClient.post(
      '/auth/register',
      data: {
        'full_name': fullName,
        'email': email,
        'password': password,
        'password_confirmation': confirmPassword,
      },
    );
    return UserModel.fromJson(response.data['data'] ?? response.data);
  }

  @override
  Future<String> uploadPhoto(String userId, String photoPath) async {
    final formData = FormData.fromMap({
      'photo': await MultipartFile.fromFile(photoPath),
    });
    final response = await _dioClient.dio.post('/users/$userId/photo', data: formData);
    final data = response.data['data'] ?? response.data;
    return data['photo_url'] ?? data['avatar'] ?? '';
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _dioClient.get('/auth/me');
    return UserModel.fromJson(response.data['data'] ?? response.data);
  }
}