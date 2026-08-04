import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_remote_data_source.dart';

/// نسخة وهمية (mock) لاستخدامها أثناء التطوير قبل جاهزية السيرفر.
///
/// بتخزّن بيانات "المستخدم" فعلياً بالـ SharedPreferences (تحت مفتاح منفصل
/// عن كاش التطبيق نفسه، بمثابة "قاعدة بيانات وهمية") عشان تحاكي سيرفر حقيقي
/// بيتذكر التعديلات — هيك تجربة الـ Offline-first بتكون مطابقة لشكلها
/// مع الباك اند الحقيقي، وما تعود القيم الافتراضية بعد كل تعديل.
class AuthMockDataSource implements AuthRemoteDataSource {
  static const _mockBackendKey = 'mock_backend_user';

  final SharedPreferences _prefs;

  AuthMockDataSource({required SharedPreferences prefs}) : _prefs = prefs;

  @override
  Future<UserModel> signIn({required String email, required String password}) async {
    await Future.delayed(const Duration(seconds: 1));
    final user = UserModel(id: '1', fullName: 'Test User', email: email, token: 'mock_token_12345');
    await _persist(user);
    return user;
  }

  @override
  Future<UserModel> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final user = UserModel(id: '1', fullName: fullName, email: email, token: 'mock_token_12345');
    await _persist(user);
    return user;
  }

  @override
  Future<String> uploadPhoto(String userId, String photoPath) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final current = await getCurrentUser();
    await _persist(current.copyWith(photoUrl: photoPath));
    // بالـ mock منرجع نفس المسار المحلي كأنه "رابط" الصورة، عشان نقدر نعاينها فوراً
    return photoPath;
  }

  @override
  Future<UserModel> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _loadPersisted() ?? await _persistDefault();
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final current = await getCurrentUser();
    final updated = current.copyWith(id: userId, fullName: fullName, email: email);
    await _persist(updated);
    return updated;
  }

  // ─── Helpers: تخزين "السيرفر الوهمي" بالـ SharedPreferences ───

  UserModel? _loadPersisted() {
    final raw = _prefs.getString(_mockBackendKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> _persistDefault() async {
    const defaultUser = UserModel(
      id: '1',
      fullName: 'Test User',
      email: 'test@masar.app',
      token: 'mock_token_12345',
    );
    await _persist(defaultUser);
    return defaultUser;
  }

  Future<void> _persist(UserModel user) async {
    await _prefs.setString(_mockBackendKey, jsonEncode(user.toJson()));
  }
}
