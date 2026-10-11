import 'package:dio/dio.dart';
import '../storage/session_store.dart';
import 'api_endpoints.dart';

/// Dio Client terpusat dengan Auto Token Injection & Error Interceptor.
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal();

  late final Dio _dio;

  Dio get dio => _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = SessionStore().token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Tangani 401 Unauthorized (token expired)
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefreshToken();
            if (refreshed) {
              // Retry request sebelumnya dengan token baru
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer ${SessionStore().token}';
              try {
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              } catch (_) {}
            } else {
              // Gagal refresh -> hapus sesi
              await SessionStore().clearSession();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final token = SessionStore().token;
      if (token == null) return false;

      final res = await Dio().post(
        ApiEndpoints.smpRefresh,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (res.statusCode == 200 && res.data['access_token'] != null) {
        final newToken = res.data['access_token'].toString();
        final currentData = SessionStore().userData ?? {};
        await SessionStore().saveSession(token: newToken, userData: currentData);
        return true;
      }
    } catch (_) {}
    return false;
  }
}
