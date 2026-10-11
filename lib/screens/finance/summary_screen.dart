import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/finance.dart';
import '../../models/santri.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import 'bills_screen.dart';
import 'mutation_screen.dart';
import 'topup_history.dart';
import 'topup_screen.dart';

/// Halaman Ringkasan Keuangan Santri (Saldo, Rekening, Quick Action, dan Mutasi Terbaru)
class FinanceSummaryScreen extends StatefulWidget {
  final Student? student;

  const FinanceSummaryScreen({super.key, this.student});

  @override
  State<FinanceSummaryScreen> createState() => _FinanceSummaryScreenState();
}

class _FinanceSummaryScreenState extends State<FinanceSummaryScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanceData();
    });
  }

  void _loadFinanceData() {
    final activeStudent = widget.student ?? context.read<StudentProvider>().activeStudent;
    if (activeStudent != null && activeStudent.nis.isNotEmpty) {
      context.read<FinanceProvider>().refreshAll(activeStudent.nis);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final targetStudent = widget.student ?? studentProvider.activeStudent;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Keuangan Santri'),
        actions: [
          IconButton(
            tooltip: 'Segarkan Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadFinanceData,
          ),
        ],
      ),
      body: targetStudent == null
          ? _buildNoStudentSelected()
          : RefreshIndicator(
              onRefresh: () async => _loadFinanceData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kartu Rekening Digital (Digital ATM Card)
                    _buildAtmCard(targetStudent, financeProvider),
                    const SizedBox(height: 20),

                    // Quick Action Menu (Top-Up, Tagihan, Mutasi, Riwayat)
                    _buildQuickActionGrid(context, targetStudent),
                    const SizedBox(height: 22),

                    // Banner Tunggakan SPP jika ada
                    if (financeProvider.billSummary != null &&
                        financeProvider.billSummary!.hasArrears)
                      _buildArrearsBanner(context, targetStudent, financeProvider.billSummary!),

                    // Limit Belanja Harian Koperasi Santri
                    if (financeProvider.currentAccount != null)
                      _buildKoperasiLimitCard(financeProvider.currentAccount!),

                    const SizedBox(height: 24),

                    // Transaksi Mutasi Terakhir
                    _buildRecentTransactionsSection(context, targetStudent, financeProvider),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoStudentSelected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.emerald50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 48,
                color: AppTheme.emerald600,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Santri Terpilih',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pilih santri terlebih dahulu di halaman utama untuk melihat informasi perbankan dan keuangannya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.slate600, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtmCard(Student student, FinanceProvider fp) {
    final account = fp.currentAccount;
    final balance = account?.balance ?? 0.0;
    final status = account?.status ?? 'AKTIF';
    final akad = account?.akadType.toUpperCase() ?? 'WADIAH';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF064E3B), // Emerald 900
            Color(0xFF047857), // Emerald 700
            Color(0xFF0D9488), // Teal 600
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.emerald900.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Kartu
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'BANK SANTRI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'AKAD $akad',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Chip Sim & Contactless Icon
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 26,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCD34D), // Gold chip
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.contactless_rounded,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Saldo Rekening
                const Text(
                  'Saldo Tabungan Utama',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                fp.isLoadingAccount
                    ? const SizedBox(
                        height: 32,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      )
                    : Text(
                        _currencyFormat.format(balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                const SizedBox(height: 20),

                // Nomor Rekening & Nama Santri
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.fullName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'NIS: ${student.nis}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: status == 'AKTIF'
                            ? const Color(0xFF10B981).withValues(alpha: 0.3)
                            : Colors.red.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: status == 'AKTIF'
                              ? const Color(0xFF34D399)
                              : Colors.redAccent,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid(BuildContext context, Student student) {
    return Row(
      children: [
        _buildActionItem(
          context: context,
          icon: Icons.add_circle_outline_rounded,
          label: 'Top-Up',
          color: AppTheme.emerald600,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TopUpScreen(student: student),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildActionItem(
          context: context,
          icon: Icons.receipt_long_rounded,
          label: 'Tagihan SPP',
          color: AppTheme.amber500,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BillsScreen(student: student),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildActionItem(
          context: context,
          icon: Icons.history_rounded,
          label: 'Mutasi',
          color: AppTheme.indigo500,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MutationScreen(student: student),
              ),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildActionItem(
          context: context,
          icon: Icons.pending_actions_rounded,
          label: 'Status Top-Up',
          color: AppTheme.teal600,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TopUpHistoryScreen(student: student),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.slate200),
            boxShadow: [
              BoxShadow(
                color: AppTheme.slate200.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArrearsBanner(
    BuildContext context,
    Student student,
    BillSummary summary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Amber 50
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE68A)), // Amber 200
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.amber500.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.amber500,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perhatian: Tagihan Belum Lunas',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ada ${summary.overdueMonthsCount} bulan tunggakan sebesar ${_currencyFormat.format(summary.totalArrears)}.',
                  style: const TextStyle(
                    color: Color(0xFFB45309),
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BillsScreen(student: student),
                      ),
                    );
                  },
                  child: const Text(
                    'Lihat Rincian Tagihan \u2192',
                    style: TextStyle(
                      color: AppTheme.emerald700,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKoperasiLimitCard(AccountBalance account) {
    final limit = account.dailyWithdrawalLimit ?? 10000.0;

    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.teal500.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppTheme.teal600,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Batas Belanja Koperasi Harian',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.slate600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currencyFormat.format(limit),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Otomatis Tier',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.slate700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    BuildContext context,
    Student student,
    FinanceProvider fp,
  ) {
    final movements = fp.movements.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transaksi Terakhir',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
            if (fp.movements.isNotEmpty)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MutationScreen(student: student),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: AppTheme.emerald600,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (fp.isLoadingMovements)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (movements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 38,
                  color: AppTheme.slate400,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Belum ada transaksi',
                  style: TextStyle(
                    color: AppTheme.slate600,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Semua aktivitas tabungan santri akan tercatat di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.slate400, fontSize: 11),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.slate200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: movements.length,
              separatorBuilder: (_, index) => const Divider(
                height: 1,
                color: AppTheme.slate100,
              ),
              itemBuilder: (context, index) {
                final item = movements[index];
                final isCredit = item.isCredit;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: isCredit
                        ? AppTheme.emerald50
                        : const Color(0xFFFFF1F2), // Rose 50
                    child: Icon(
                      isCredit
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isCredit ? AppTheme.emerald600 : AppTheme.rose500,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.description?.isNotEmpty == true
                        ? item.description!
                        : (isCredit ? 'Setoran Tabungan' : 'Penarikan / Belanja'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.slate900,
                    ),
                  ),
                  subtitle: Text(
                    _formatDate(item.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.slate400,
                    ),
                  ),
                  trailing: Text(
                    '${isCredit ? "+" : "-"} ${_currencyFormat.format(item.amount)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isCredit ? AppTheme.emerald600 : AppTheme.rose500,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
