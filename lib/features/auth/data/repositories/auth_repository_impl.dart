import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/cache/local_cache_service.dart';
import '../../../../core/error/dio_error_mapper.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/sync/syncable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository, Syncable {
  static const _cachedUserKey = 'cache_current_user';
  static const _pendingProfileUpdateKey = 'pending_profile_update';

  final AuthRemoteDataSource _remoteDataSource;
  final LocalCacheService _cache;
  final ConnectivityService _connectivityService;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required LocalCacheService cache,
    required ConnectivityService connectivityService,
  })  : _remoteDataSource = remoteDataSource,
        _cache = cache,
        _connectivityService = connectivityService;

  @override
  Future<Either<Failure, UserEntity>> signIn({required String email, required String password}) async {
    try {
      final user = await _remoteDataSource.signIn(email: email, password: password);
      await _cacheUser(user);
      return Right(user);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String fullName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final user = await _remoteDataSource.signUp(
        fullName: fullName,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );
      await _cacheUser(user);
      return Right(user);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadPhoto(String userId, String photoPath) async {
    // رفع صورة محتاج اتصال فعلي بالسيرفر، ما منعمله أوفلاين.
    try {
      final photoUrl = await _remoteDataSource.uploadPhoto(userId, photoPath);
      return Right(photoUrl);
    } on DioException catch (e) {
      return Left(DioErrorMapper.map(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    final isConnected = await _connectivityService.isConnected;

    if (isConnected) {
      try {
        final user = await _remoteDataSource.getCurrentUser();
        await _cacheUser(user);
        debugPrint('[Auth] getCurrentUser: من السيرفر → ${user.fullName} (${user.email})');
        return Right(user);
      } on DioException catch (e) {
        // في نت بس الطلب فشل (سيرفر واقع، تايم آوت..) → نرجع لآخر نسخة بالكاش
        return _readCachedUser() ?? Left(DioErrorMapper.map(e));
      } catch (e) {
        return _readCachedUser() ?? Left(UnknownFailure(e.toString()));
      }
    }

    // ما في نت → منرجع آخر بيانات محفوظة بالكاش
    final cached = _readCachedUser();
    debugPrint('[Auth] getCurrentUser: بدون نت → من الكاش (${cached != null ? "موجود" : "غير موجود"})');
    return cached ??
        const Left(NetworkFailure('لا يوجد اتصال بالإنترنت ولا بيانات محفوظة محلياً.'));
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    required String fullName,
    required String email,
  }) async {
    final isConnected = await _connectivityService.isConnected;

    if (isConnected) {
      try {
        final user = await _remoteDataSource.updateProfile(userId: userId, fullName: fullName, email: email);
        await _cacheUser(user);
        await _cache.remove(_pendingProfileUpdateKey);
        return Right(user);
      } on DioException catch (e) {
        return Left(DioErrorMapper.map(e));
      } catch (e) {
        return Left(UnknownFailure(e.toString()));
      }
    }

    // ما في نت → نحدّث الكاش محلياً فوراً (عشان الشاشة تنعكس فوراً)
    // ونخزّن التعديل كـ Pending حتى الـ SyncManager يبعته لما يرجع النت.
    final cachedJson = _cache.getObject(_cachedUserKey);
    if (cachedJson == null) {
      return const Left(NetworkFailure('لا يوجد اتصال بالإنترنت.'));
    }

    final updatedUser = UserModel.fromJson(cachedJson).copyWith(fullName: fullName, email: email);
    await _cacheUser(updatedUser);
    await _cache.saveObject(_pendingProfileUpdateKey, {
      'userId': userId,
      'fullName': fullName,
      'email': email,
    });
    debugPrint('[Auth] updateProfile: بدون نت → خزّنت التعديل كـ Pending (${updatedUser.fullName})');
    return Right(updatedUser);
  }

  // ─── Syncable ───

  @override
  Future<void> syncPendingChanges() async {
    final pending = _cache.getObject(_pendingProfileUpdateKey);
    if (pending == null) return;

    debugPrint('[Auth] syncPendingChanges: بعت التعديل المعلّق (${pending['fullName']})...');
    final user = await _remoteDataSource.updateProfile(
      userId: pending['userId'] as String,
      fullName: pending['fullName'] as String,
      email: pending['email'] as String,
    );
    await _cacheUser(user);
    await _cache.remove(_pendingProfileUpdateKey);
    debugPrint('[Auth] syncPendingChanges: تمّت المزامنة ✅');
  }

  // ─── Helpers ───

  Future<void> _cacheUser(UserEntity user) async {
    final model = user is UserModel
        ? user
        : UserModel(
            id: user.id,
            fullName: user.fullName,
            email: user.email,
            photoUrl: user.photoUrl,
            token: user.token,
          );
    await _cache.saveObject(_cachedUserKey, model.toJson());
  }

  Either<Failure, UserEntity>? _readCachedUser() {
    final json = _cache.getObject(_cachedUserKey);
    if (json == null) return null;
    return Right(UserModel.fromJson(json));
  }
}
