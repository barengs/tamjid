import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/notifications/fcm_service.dart';
import '../../core/theme/app_theme.dart';

/// Halaman Daftar Notifikasi Wali Santri
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final PushNotificationService _service = PushNotificationService();
  String _filter = 'all'; // all | finance | kamtib | academic | general

  @override
  void initState() {
    super.initState();
    // Tandai semua notifikasi terbaca saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _service.markAllAsRead();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _service.notifications;
    final filtered = notifications.where((n) {
      if (_filter == 'all') return true;
      return n.type == _filter;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                _service.markAllAsRead();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Semua notifikasi ditandai telah dibaca.'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text(
                'Tandai Dibaca',
                style: TextStyle(
                  color: AppTheme.emerald600,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Keuangan',
                    selected: _filter == 'finance',
                    onTap: () => setState(() => _filter = 'finance'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Kamtib',
                    selected: _filter == 'kamtib',
                    onTap: () => setState(() => _filter = 'kamtib'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Perizinan',
                    selected: _filter == 'academic',
                    onTap: () => setState(() => _filter = 'academic'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Umum',
                    selected: _filter == 'general',
                    onTap: () => setState(() => _filter = 'general'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (filtered.isEmpty)
              _buildEmptyState()
            else
              ...filtered.map((notif) => _buildNotificationCard(notif)),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 40,
              color: AppTheme.emerald600,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pemberitahuan terkait keuangan, perizinan, dan kegiatan santri akan muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.slate400,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notif) {
    Color typeColor;
    IconData typeIcon;

    switch (notif.type) {
      case 'finance':
        typeColor = AppTheme.emerald600;
        typeIcon = Icons.account_balance_wallet_rounded;
        break;
      case 'kamtib':
        typeColor = AppTheme.rose500;
        typeIcon = Icons.warning_amber_rounded;
        break;
      case 'academic':
        typeColor = AppTheme.indigo500;
        typeIcon = Icons.assignment_rounded;
        break;
      default:
        typeColor = AppTheme.teal600;
        typeIcon = Icons.notifications_active_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: notif.isRead
              ? AppTheme.slate200
              : typeColor.withValues(alpha: 0.35),
        ),
        boxShadow: [
          if (!notif.isRead)
            BoxShadow(
              color: typeColor.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(typeIcon, color: typeColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        notif.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: notif.isRead
                              ? FontWeight.w600
                              : FontWeight.w800,
                          color: AppTheme.slate900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(notif.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.slate400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.body,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes == 0 ? 1 : diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else {
      return DateFormat('dd MMM', 'id_ID').format(dt);
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.emerald600 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.emerald600 : AppTheme.slate200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.slate600,
          ),
        ),
      ),
    );
  }
}
