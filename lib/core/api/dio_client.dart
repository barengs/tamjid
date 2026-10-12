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
            final requestPath = error.requestOptions.path;
            final isSmpRequest = requestPath.startsWith(ApiEndpoints.smpBase);

            // Jangan hapus session jika 401 berasal dari service lain (misal bank-santri)
            if (isSmpRequest && !requestPath.contains('/auth/login') && !requestPath.contains('/auth/refresh')) {
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
                // Hanya hapus sesi jika server benar-benar menolak refresh token (bukan timeout/koneksi putus)
                // Jika koneksi putus saat background, jangan log out user
                final refreshStatusCode = _lastRefreshStatusCode;
                if (refreshStatusCode == 401 || refreshStatusCode == 403) {
                  await SessionStore().clearSession();
                }
              }
            }
          }

          // Format pesan error jaringan yang ramah pengguna
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            final customErr = DioException(
              requestOptions: error.requestOptions,
              type: error.type,
              error: 'Koneksi ke server pesantren melebihi batas waktu (timeout).',
              message: 'Koneksi timeout. Silakan periksa jaringan internet Anda.',
            );
            return handler.next(customErr);
          }

          if (error.type == DioExceptionType.connectionError) {
            final customErr = DioException(
              requestOptions: error.requestOptions,
              type: error.type,
              error: 'Tidak dapat terhubung ke server pesantren.',
              message: 'Tidak ada koneksi internet atau server pesantren sedang offline.',
            );
            return handler.next(customErr);
          }

          return handler.next(error);
        },
      ),
    );
  }

  int? _lastRefreshStatusCode;

  Future<bool> _tryRefreshToken() async {
    _lastRefreshStatusCode = null;
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

      _lastRefreshStatusCode = res.statusCode;
      if (res.statusCode == 200 && res.data['access_token'] != null) {
        final newToken = res.data['access_token'].toString();
        final currentData = SessionStore().userData ?? {};
        await SessionStore().saveSession(token: newToken, userData: currentData);
        return true;
      }
    } on DioException catch (e) {
      _lastRefreshStatusCode = e.response?.statusCode;
    } catch (_) {}
    return false;
  }
}
