import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatelessWidget {
  final AuthProvider authProvider;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.authProvider,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final user = authProvider.currentUser;
    final profile = user?.profile;
    final greetingName = profile?.firstName.isNotEmpty == true
        ? profile!.firstName
        : (user?.name ?? 'Wali Santri');

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Beranda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: onLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => authProvider.fetchProfile(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kartu Sapaan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.emerald700, AppTheme.emerald500],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.emerald600.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assalamu\u2019alaikum,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      greetingName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          profile?.nik != null
                              ? 'NIK Terverifikasi'
                              : 'Lengkapi profil Anda',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Menu Utama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 12),

              // Grid Menu Placeholder
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _MenuCard(
                    icon: Icons.group_add_rounded,
                    color: AppTheme.emerald600,
                    label: 'Santri Saya',
                    subtitle: 'Daftar & profil anak',
                    onTap: () => _showComingSoon(context, 'Santri Saya'),
                  ),
                  _MenuCard(
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.indigo500,
                    label: 'Keuangan',
                    subtitle: 'Saldo & mutasi',
                    onTap: () => _showComingSoon(context, 'Keuangan'),
                  ),
                  _MenuCard(
                    icon: Icons.receipt_long_rounded,
                    color: AppTheme.amber500,
                    label: 'Tagihan SPP',
                    subtitle: 'Cek tunggakan',
                    onTap: () => _showComingSoon(context, 'Tagihan SPP'),
                  ),
                  _MenuCard(
                    icon: Icons.upload_rounded,
                    color: AppTheme.teal600,
                    label: 'Top-Up Dana',
                    subtitle: 'Transfer bank',
                    onTap: () => _showComingSoon(context, 'Top-Up Dana'),
                  ),
                  _MenuCard(
                    icon: Icons.mosque_rounded,
                    color: AppTheme.emerald700,
                    label: 'Pendaftaran PSB',
                    subtitle: 'Santri baru',
                    onTap: () => _showComingSoon(context, 'Pendaftaran PSB'),
                  ),
                  _MenuCard(
                    icon: Icons.rule_rounded,
                    color: AppTheme.rose500,
                    label: 'Pelanggaran',
                    subtitle: 'Riwayat kamtib',
                    onTap: () => _showComingSoon(context, 'Pelanggaran'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String menu) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.slate800,
        content: Text('Modul "$menu" akan tersedia di sprint berikutnya.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.slate200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
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
      ),
    );
  }
}
