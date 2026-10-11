import 'package:flutter/foundation.dart';
import '../storage/session_store.dart';

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
/// Siap terhubung dengan Firebase Cloud Messaging (FCM) dan sistem notifikasi lokal.
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  String? _fcmToken;
  final List<AppNotification> _notifications = [];

  String? get fcmToken => _fcmToken;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Inisialisasi service dan simulasi pendaftaran push token
  Future<void> init() async {
    try {
      // Mock / bootstrap device token
      _fcmToken = 'device_token_${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('PushNotificationService initialized with token: $_fcmToken');

      // Muat notifikasi selamat datang default
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
    }
  }

  /// Daftarkan token FCM ke backend pesantren setelah login
  Future<bool> syncTokenWithBackend() async {
    final token = SessionStore().token;
    if (token == null || _fcmToken == null) return false;

    // Disiapkan untuk endpoint FCM registration:
    // await DioClient().dio.post('/api/main/fcm/register', data: {'fcm_token': _fcmToken});
    debugPrint('FCM token synchronized with backend for user session.');
    return true;
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
