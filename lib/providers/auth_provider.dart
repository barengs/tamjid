import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/dio_client.dart';
import '../core/storage/session_store.dart';
import '../core/notifications/fcm_service.dart';
import '../models/wali_user.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthStatus _status = AuthStatus.initial;
  WaliUser? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  WaliUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _currentUser != null;

  /// Inisialisasi sesi awal saat aplikasi dibuka
  Future<void> bootstrap() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await SessionStore().init();

    if (SessionStore().isLoggedIn && SessionStore().userData != null) {
      try {
        _currentUser = WaliUser.fromJson(SessionStore().userData!);
        _status = AuthStatus.authenticated;
        notifyListeners();

        // Refresh profil di background secara silent dan sinkron token FCM
        fetchProfile();
        PushNotificationService().syncTokenWithBackend();
        return;
      } catch (_) {}
    }

    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Login wali santri via smp-be
  Future<bool> login({required String usernameOrEmail, required String password}) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final dio = DioClient().dio;
      final response = await dio.post(
        ApiEndpoints.smpLogin,
        data: {
          'login': usernameOrEmail.trim(),
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final token = data['access_token']?.toString() ?? '';
        final userRaw = data['user'];
        if (userRaw is! Map<String, dynamic>) {
          throw Exception('Data profil user tidak ditemukan dari server.');
        }

        _currentUser = WaliUser.fromJson(userRaw);
        await SessionStore().saveSession(token: token, userData: userRaw);

        _status = AuthStatus.authenticated;
        notifyListeners();

        // Sinkronisasi FCM token ke backend
        PushNotificationService().syncTokenWithBackend();
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'Login gagal.');
      }
    } on DioException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Registrasi akun wali santri baru
  ///
  /// [nik] dan [phone] bersifat opsional, namun jika diisi wali langsung
  /// terdaftar sebagai ParentProfile sehingga bisa login via NIK / No HP.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? nik,
    String? phone,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final dio = DioClient().dio;
      final payload = <String, dynamic>{
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': passwordConfirmation,
      };
      if (nik != null && nik.trim().isNotEmpty) payload['nik'] = nik.trim();
      if (phone != null && phone.trim().isNotEmpty) payload['phone'] = phone.trim();

      final response = await dio.post(
        ApiEndpoints.smpRegister,
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['access_token']?.toString() ?? '';
        final userRaw = data['user'] as Map<String, dynamic>;

        _currentUser = WaliUser.fromJson(userRaw);
        await SessionStore().saveSession(token: token, userData: userRaw);

        _status = AuthStatus.authenticated;
        notifyListeners();
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'Pendaftaran gagal.');
      }
    } on DioException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Mengambil data profil terbaru dari server
  Future<void> fetchProfile() async {
    try {
      final dio = DioClient().dio;
      final response = await dio.get(ApiEndpoints.smpProfile);
      if (response.statusCode == 200 && response.data?['data'] != null) {
        final userRaw = response.data['data'] as Map<String, dynamic>;
        _currentUser = WaliUser.fromJson(userRaw);
        if (SessionStore().token != null) {
          await SessionStore().saveSession(
            token: SessionStore().token!,
            userData: userRaw,
          );
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  /// Logout wali santri
  Future<void> logout() async {
    try {
      final dio = DioClient().dio;
      await PushNotificationService().unregisterToken();
      await dio.post(ApiEndpoints.smpLogout);
    } catch (_) {}

    await SessionStore().clearSession();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  String _parseDioError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final d = e.response!.data;
      if (d is Map) {
        if (d['message'] != null) return d['message'].toString();
        if (d['errors'] != null && d['errors'] is Map) {
          final errMap = d['errors'] as Map;
          final firstKey = errMap.keys.first;
          final val = errMap[firstKey];
          if (val is List && val.isNotEmpty) return val.first.toString();
          return val.toString();
        }
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi ke server timeout. Silakan periksa jaringan Anda.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server pesantren.';
    }
    return e.message ?? 'Terjadi kesalahan pada jaringan.';
  }
}
