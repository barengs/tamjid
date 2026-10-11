import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/family_switcher.dart';
import '../../widgets/student_card_qr.dart';
import '../registration/history_screen.dart';
import '../student/student_detail_screen.dart';
import '../finance/summary_screen.dart';
import '../finance/bills_screen.dart';
import '../finance/topup_screen.dart';
import '../kamtib/violation_screen.dart';
import '../kamtib/leave_screen.dart';
import '../academic/hostel_screen.dart';
import '../academic/report_screen.dart';

class HomeScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final VoidCallback onLogout;

  const HomeScreen({
    super.key,
    required this.authProvider,
    required this.onLogout,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Muat daftar santri setelah frame pertama (menunggu NIK wali dari auth)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  void _loadStudents() {
    final auth = widget.authProvider;
    final studentProvider = context.read<StudentProvider>();
    final nik = auth.currentUser?.profile?.nik ?? '';
    studentProvider.fetchStudentsByNik(nik);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = widget.authProvider;
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
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await authProvider.fetchProfile();
          _loadStudents();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
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
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
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

              // Family Switcher (Daftar Santri)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Consumer<StudentProvider>(
                  builder: (context, sp, _) {
                    switch (sp.status) {
                      case StudentStatus.loading:
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 26),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppTheme.slate200),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.emerald600,
                              strokeWidth: 2.5,
                            ),
                          ),
                        );
                      case StudentStatus.empty:
                        return _EmptyStudentCard(
                          nikProvided: profile?.nik != null,
                          onRetry: _loadStudents,
                        );
                      case StudentStatus.error:
                        return _ErrorStudentCard(
                          message: sp.errorMessage ?? 'Terjadi kesalahan.',
                          onRetry: _loadStudents,
                        );
                      case StudentStatus.loaded:
                      case StudentStatus.initial:
                        return FamilySwitcher(
                          students: sp.students,
                          activeStudent: sp.activeStudent,
                          onSelect: (student) =>
                              sp.switchActiveStudent(student),
                        );
                    }
                  },
                ),
              ),

              // Kartu Santri Digital dengan QR Code
              Consumer<StudentProvider>(
                builder: (context, sp, _) {
                  if (sp.activeStudent != null) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                      child: StudentCardQrWidget(student: sp.activeStudent!),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Menu Utama',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Grid Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StudentDetailScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppTheme.indigo500,
                      label: 'Keuangan',
                      subtitle: 'Saldo & mutasi',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FinanceSummaryScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.receipt_long_rounded,
                      color: AppTheme.amber500,
                      label: 'Tagihan SPP',
                      subtitle: 'Cek tunggakan',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BillsScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.upload_rounded,
                      color: AppTheme.teal600,
                      label: 'Top-Up Dana',
                      subtitle: 'Transfer bank',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TopUpScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.mosque_rounded,
                      color: AppTheme.emerald700,
                      label: 'Pendaftaran PSB',
                      subtitle: 'Santri baru',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrationHistoryScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.rule_rounded,
                      color: AppTheme.rose500,
                      label: 'Pelanggaran',
                      subtitle: 'Riwayat kamtib',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ViolationScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.assignment_outlined,
                      color: AppTheme.indigo500,
                      label: 'Perizinan',
                      subtitle: 'Riwayat & ajukan',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LeaveScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.hotel_rounded,
                      color: AppTheme.teal500,
                      label: 'Info Asrama',
                      subtitle: 'Kamar & pembina',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HostelScreen(),
                          ),
                        );
                      },
                    ),
                    _MenuCard(
                      icon: Icons.checklist_rtl_rounded,
                      color: AppTheme.emerald600,
                      label: 'Presensi',
                      subtitle: 'Kehadiran santri',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReportScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu empty state ketika wali belum memiliki santri terhubung
class _EmptyStudentCard extends StatelessWidget {
  final bool nikProvided;
  final VoidCallback onRetry;

  const _EmptyStudentCard({required this.nikProvided, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.emerald50,
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppTheme.emerald600,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nikProvided
                ? 'Belum ada santri terhubung'
                : 'Profil Anda belum lengkap',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            nikProvided
                ? 'Silakan hubungi bagian pendaftaran pesantren untuk menghubungkan data santri Anda.'
                : 'Lengkapi profil wali (NIK) agar data santri dapat terhubung otomatis.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.slate500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Muat Ulang'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.emerald700,
              side: const BorderSide(color: AppTheme.emerald600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu error state ketika fetch data santri gagal
class _ErrorStudentCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorStudentCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.rose500.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.rose500, size: 28),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.slate600),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.rose500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
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
