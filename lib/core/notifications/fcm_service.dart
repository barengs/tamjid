import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../storage/session_store.dart';
import '../api/dio_client.dart';
import '../api/api_endpoints.dart';

/// Notification payload model untuk notifikasi wali santri
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? type; // finance, kamtib, academic, general
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.timestamp,
    this.isRead = false,
  });
}

/// Service Push Notification untuk aplikasi Wali Santri Tamjid
/// Mengintegrasikan Firebase Cloud Messaging (FCM) native Flutter,
/// sinkronisasi device token ke backend pesantren (smp-be),
/// dan daftar notifikasi in-app (local state).
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  FirebaseMessaging? _messaging;
  FirebaseMessaging get _firebaseMessaging =>
      _messaging ??= FirebaseMessaging.instance;
  String? _fcmToken;
  final List<AppNotification> _notifications = [];

  String? get fcmToken => _fcmToken;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Inisialisasi service: dapatkan token FCM asli, register ke Firebase,
  /// dan muat notifikasi selamat datang default.
  Future<void> init() async {
    try {
      // 1. Request permission (Android 13+, iOS)
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // 2. Dapatkan FCM Token asli dari Firebase
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken == null || _fcmToken!.isEmpty) {
        // Fallback untuk platform web/simulator tanpa layanan Firebase
        _fcmToken = 'device_token_${DateTime.now().millisecondsSinceEpoch}';
      }
      debugPrint('PushNotificationService initialized with token: $_fcmToken');

      // 3. Dengarkan foreground messages (saat aplikasi terbuka)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          addNotification(
            title: notification.title ?? 'Pemberitahuan',
            body: notification.body ?? 'Ada notifikasi baru.',
            type: message.data['type']?.toString(),
          );
        }
      });

      // 4. Muat notifikasi selamat datang default
      if (_notifications.isEmpty) {
        _notifications.add(
          AppNotification(
            id: 'notif_welcome',
            title: 'Selamat Datang di Tamjid Wali',
            body:
                'Pantau perkembangan pendidikan, kedisiplinan, dan keuangan santri Anda secara mudah dan transparan.',
            type: 'general',
            timestamp: DateTime.now(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error init PushNotificationService: $e');
      // Fallback token mock agar aplikasi tetap berjalan tanpa crash
      _fcmToken = 'device_token_${DateTime.now().millisecondsSinceEpoch}';
      if (_notifications.isEmpty) {
        _notifications.add(
          AppNotification(
            id: 'notif_welcome',
            title: 'Selamat Datang di Tamjid Wali',
            body:
                'Pantau perkembangan pendidikan, kedisiplinan, dan keuangan santri Anda secara mudah dan transparan.',
            type: 'general',
            timestamp: DateTime.now(),
          ),
        );
      }
    }
  }

  /// Daftarkan token FCM ke backend pesantren setelah login
  Future<bool> syncTokenWithBackend({String deviceType = 'android'}) async {
    final token = SessionStore().token;
    if (token == null || _fcmToken == null) return false;

    try {
      await DioClient().dio.post(
        ApiEndpoints.smpFcmRegister,
        data: {
          'token': _fcmToken,
          'device_type': deviceType,
          'device_name': 'Tamjid Mobile App',
        },
      );
      debugPrint('FCM token synchronized with backend for user session.');
      return true;
    } catch (e) {
      debugPrint('Failed to sync FCM token with backend: $e');
      return false;
    }
  }

  /// Hapus token FCM dari backend saat logout
  Future<bool> unregisterToken() async {
    final token = SessionStore().token;
    if (token == null || _fcmToken == null) return false;

    try {
      await DioClient().dio.post(
        ApiEndpoints.smpFcmUnregister,
        data: {'token': _fcmToken},
      );
      debugPrint('FCM token unregistered from backend.');
      return true;
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
      return false;
    }
  }

  /// Tambah notifikasi in-app baru
  void addNotification({
    required String title,
    required String body,
    String? type,
  }) {
    final notif = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
    );
    _notifications.insert(0, notif);
  }

  /// Tandai semua notifikasi telah dibaca
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = AppNotification(
        id: _notifications[i].id,
        title: _notifications[i].title,
        body: _notifications[i].body,
        type: _notifications[i].type,
        timestamp: _notifications[i].timestamp,
        isRead: true,
      );
    }
  }
}
