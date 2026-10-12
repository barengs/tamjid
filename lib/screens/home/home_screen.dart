import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/fcm_service.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/family_switcher.dart';
import '../../widgets/student_card_qr.dart';
import '../academic/report_screen.dart';
import '../finance/bills_screen.dart';
import '../finance/summary_screen.dart';
import '../finance/topup_screen.dart';
import '../kamtib/leave_screen.dart';
import '../kamtib/violation_screen.dart';
import '../notifications/notification_screen.dart';
import '../profile/profile_screen.dart';
import '../registration/history_screen.dart';
import '../student/student_detail_screen.dart';

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
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudents();
    });
  }

  void _loadStudents() {
    final auth = widget.authProvider;
    final studentProvider = context.read<StudentProvider>();
    final nik = auth.currentUser?.profile?.nik ?? '';
    if (nik.isNotEmpty) {
      studentProvider.fetchStudentsByNik(nik).then((_) {
        _syncFinance();
      });
    }
  }

  void _syncFinance() {
    final sp = context.read<StudentProvider>();
    final active = sp.activeStudent;
    if (active != null) {
      context.read<FinanceProvider>().refreshAll(
        active.nis,
        studentId: active.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.slate50,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(context),
            const StudentDetailScreen(),
            const FinanceSummaryScreen(),
            ProfileScreen(onLogout: widget.onLogout),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: NavigationBar(
            height: 64,
            elevation: 0,
            backgroundColor: Colors.transparent,
            selectedIndex: _currentIndex,
            indicatorColor: AppTheme.emerald100,
            onDestinationSelected: (idx) {
              setState(() => _currentIndex = idx);
              if (idx == 2) {
                _syncFinance();
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, color: AppTheme.slate600),
                selectedIcon: Icon(
                  Icons.home_rounded,
                  color: AppTheme.emerald700,
                ),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.people_outline_rounded,
                  color: AppTheme.slate600,
                ),
                selectedIcon: Icon(
                  Icons.people_rounded,
                  color: AppTheme.emerald700,
                ),
                label: 'Anak',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppTheme.slate600,
                ),
                selectedIcon: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppTheme.emerald700,
                ),
                label: 'Keuangan',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.slate600,
                ),
                selectedIcon: Icon(
                  Icons.person_rounded,
                  color: AppTheme.emerald700,
                ),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final user = widget.authProvider.currentUser;
    final profile = user?.profile;

    // Gunakan fullName wali secara utuh, bukan hanya firstName
    final fullName = (profile != null && profile.fullName.isNotEmpty)
        ? profile.fullName
        : (user != null && user.name.isNotEmpty ? user.name : 'Wali Santri');

    return RefreshIndicator(
      onRefresh: () async {
        await widget.authProvider.fetchProfile();
        _loadStudents();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unified Seamless Header (Status Bar + Greeting)
            _buildSeamlessHeader(fullName, profile?.nik),
            const SizedBox(height: 16),

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
                          borderRadius: BorderRadius.circular(20),
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
                        onSelect: (student) {
                          sp.switchActiveStudent(student);
                          context.read<FinanceProvider>().refreshAll(
                            student.nis,
                            studentId: student.id,
                          );
                        },
                      );
                  }
                },
              ),
            ),

            // Quick Financial Snapshot Card
            Consumer2<StudentProvider, FinanceProvider>(
              builder: (context, sp, fp, _) {
                final student = sp.activeStudent;
                if (student == null) return const SizedBox.shrink();

                final account = fp.currentAccount;
                final balanceText = account != null
                    ? 'Rp ${account.balance.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
                    : 'Memuat...';

                return Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.slate900, AppTheme.slate800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.slate900.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: AppTheme.emerald400,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Saldo Tabungan Santri',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                setState(() => _currentIndex = 2);
                                _syncFinance();
                              },
                              child: const Row(
                                children: [
                                  Text(
                                    'Rincian',
                                    style: TextStyle(
                                      color: AppTheme.emerald400,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: AppTheme.emerald400,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          balanceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              'Rekening: ${student.nis}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.emerald600.withValues(
                                  alpha: 0.25,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                account?.akadType.toUpperCase() ?? 'WADIAH',
                                style: const TextStyle(
                                  color: AppTheme.emerald400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Kartu Santri Digital dengan QR Code
            Consumer<StudentProvider>(
              builder: (context, sp, _) {
                if (sp.activeStudent != null) {
                  return Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                    ),
                    child: StudentCardQrWidget(student: sp.activeStudent!),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 22),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Layanan & Menu Utama',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
                childAspectRatio: 1.45,
                children: [
                  _MenuCard(
                    icon: Icons.people_alt_rounded,
                    color: AppTheme.emerald600,
                    label: 'Anak Saya',
                    subtitle: 'Detail & dokumen anak',
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  _MenuCard(
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppTheme.indigo500,
                    label: 'Keuangan',
                    subtitle: 'Saldo & mutasi bank',
                    onTap: () {
                      setState(() => _currentIndex = 2);
                      _syncFinance();
                    },
                  ),
                  _MenuCard(
                    icon: Icons.fact_check_rounded,
                    color: AppTheme.teal600,
                    label: 'Presensi',
                    subtitle: 'Kehadiran & kelas',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: Icons.assignment_rounded,
                    color: AppTheme.amber500,
                    label: 'Perizinan',
                    subtitle: 'Surat izin santri',
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
                    icon: Icons.receipt_long_rounded,
                    color: AppTheme.rose500,
                    label: 'Tagihan SPP',
                    subtitle: 'Cek rincian pembayaran',
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
                    icon: Icons.add_card_rounded,
                    color: AppTheme.emerald700,
                    label: 'Top-Up Dana',
                    subtitle: 'Isi tabungan santri',
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
                    icon: Icons.how_to_reg_rounded,
                    color: AppTheme.teal500,
                    label: 'Pendaftaran PSB',
                    subtitle: 'Santri baru pesantren',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const RegistrationHistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuCard(
                    icon: Icons.shield_rounded,
                    color: AppTheme.rose500,
                    label: 'Kedisiplinan',
                    subtitle: 'Catatan tata tertib',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ViolationScreen(),
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
    );
  }

  /// App Header menyatu utuh dari Status Bar sampai kartu sapaan
  Widget _buildSeamlessHeader(String fullName, String? nik) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 12,
        left: 20,
        right: 20,
        bottom: 24,
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
        boxShadow: [
          BoxShadow(
            color: AppTheme.emerald700.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Brand Title & Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'TAMJID WALI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _NotificationBell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white70,
                    ),
                    tooltip: 'Keluar',
                    onPressed: widget.onLogout,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sapaan & Nama Lengkap
          const Text(
            'Assalamu\u2019alaikum,',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  color: AppTheme.emerald400,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  nik != null && nik.isNotEmpty
                      ? 'NIK: $nik'
                      : 'Wali Santri Terdaftar',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppTheme.slate500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final VoidCallback onTap;

  const _NotificationBell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = PushNotificationService().unreadCount;

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          tooltip: 'Notifikasi',
          onPressed: onTap,
        ),
        if (unread > 0)
          Positioned(
            right: 8,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.rose500,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyStudentCard extends StatelessWidget {
  final bool nikProvided;
  final VoidCallback onRetry;

  const _EmptyStudentCard({required this.nikProvided, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          const Icon(Icons.school_outlined, size: 48, color: AppTheme.slate400),
          const SizedBox(height: 12),
          Text(
            nikProvided
                ? 'Tidak ada santri yang terhubung'
                : 'NIK Anda belum terisi',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nikProvided
                ? 'Pastikan NIK Anda sudah didaftarkan pada data santri di pesantren.'
                : 'Lengkapi data NIK pada menu profil untuk menghubungkan akun Anda dengan santri.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Coba Lagi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.emerald600,
              side: const BorderSide(color: AppTheme.emerald600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorStudentCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorStudentCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.rose500.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 44,
            color: AppTheme.rose500,
          ),
          const SizedBox(height: 10),
          const Text(
            'Gagal Memuat Data Santri',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Muat Ulang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
