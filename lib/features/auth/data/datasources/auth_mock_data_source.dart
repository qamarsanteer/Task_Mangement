import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// نسخة وهمية (mock) لاستخدامها أثناء التطوير قبل جاهزية السيرفر
class AuthMockDataSource implements AuthRemoteDataSource {
  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: '1',
      fullName: 'Test User',
      email: email,
      token: 'mock_token_12345',
    );
  }

  @override
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    return UserModel(
      id: '1',
      fullName: fullName,
      email: email,
      token: 'mock_token_12345',
    );
  }

  @override
  Future<String> uploadPhoto(String userId, String photoPath) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // بالـ mock منرجع نفس المسار المحلي كأنه "رابط" الصورة، عشان نقدر نعاينها فوراً
    return photoPath;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const UserModel(
      id: '1',
      fullName: 'Test User',
      email: 'test@masar.app',
      token: 'mock_token_12345',
    );
  }
}