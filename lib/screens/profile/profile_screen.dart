import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/fcm_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/kesantrian_provider.dart';
import '../../providers/student_provider.dart';
import '../registration/history_screen.dart';

/// Halaman Profil Wali Santri (Tab ke-4 pada bottom navigation)
class ProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final profile = user?.profile;

    final fullName = (profile != null && profile.fullName.isNotEmpty)
        ? profile.fullName
        : (user?.name.isNotEmpty == true ? user!.name : 'Wali Santri');

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'W';

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      body: CustomScrollView(
        slivers: [
          // Header Profil
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 20,
                right: 20,
                bottom: 28,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.emerald800, AppTheme.emerald600],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'Profil Saya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (profile?.nik != null && profile!.nik!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'NIK: ${profile.nik}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Informasi Akun
                _SectionCard(
                  title: 'Informasi Akun',
                  children: [
                    _InfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Nama Lengkap',
                      value: fullName,
                    ),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      label: 'NIK',
                      value: profile?.nik ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user?.email ?? '-',
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'No. Telepon',
                      value: profile?.phone ?? '-',
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Layanan
                _SectionCard(
                  title: 'Layanan',
                  children: [
                    _MenuRow(
                      icon: Icons.how_to_reg_rounded,
                      label: 'Pendaftaran PSB',
                      subtitle: 'Riwayat pendaftaran santri baru',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistrationHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuRow(
                      icon: Icons.notifications_none_rounded,
                      label: 'Notifikasi',
                      subtitle: 'Daftar pemberitahuan aplikasi',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _DummyNotifScreen(),
                          ),
                        );
                      },
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tentang Aplikasi
                _SectionCard(
                  title: 'Tentang Aplikasi',
                  children: [
                    _InfoRow(
                      icon: Icons.mosque_rounded,
                      label: 'Aplikasi',
                      value: 'Tamjid Wali v1.0.0',
                    ),
                    _InfoRow(
                      icon: Icons.local_hospital_outlined,
                      label: 'Fungsi Push',
                      value: PushNotificationService().fcmToken != null
                          ? 'Aktif'
                          : 'Tidak aktif',
                      isLast: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Tombol Logout
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmLogout(context, authProvider),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Keluar dari Akun',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.rose500,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar dari Akun?'),
        content: const Text(
          'Anda akan keluar dari aplikasi Tamjid Wali dan perlu login kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Reset state seluruh provider sebelum logout
              context.read<StudentProvider>().reset();
              context.read<FinanceProvider>().reset();
              context.read<KesantrianProvider>().reset();
              Navigator.of(ctx).pop();
              onLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.slate100, width: 1),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppTheme.emerald600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.slate600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  const _MenuRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppTheme.slate100, width: 1),
                  ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: AppTheme.teal600),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppTheme.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder notifikasi — mengarahkan ke NotificationScreen
class _DummyNotifScreen extends StatelessWidget {
  const _DummyNotifScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: const Center(child: Text('Memuat notifikasi...')),
    );
  }
}
