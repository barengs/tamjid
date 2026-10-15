import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/finance.dart';
import '../../models/santri.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_card_qr.dart';
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
  bool _isBalanceVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFinanceData();
    });
  }

  void _loadFinanceData() {
    final activeStudent =
        widget.student ?? context.read<StudentProvider>().activeStudent;
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
        title: const Text('Keuangan Anak'),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Tampilkan Saldo di Bagian Atas Kartu Santri (Hanya Saldo Tanpa Informasi Lainnya)
                    Consumer2<StudentProvider, FinanceProvider>(
                      builder: (context, sp, fp, _) {
                        final student = sp.activeStudent;
                        if (student == null) return const SizedBox.shrink();

                        final account = fp.getAccountFor(
                          nis: student.nis,
                          studentId: student.id,
                        );
                        final balanceText = account != null
                            ? 'Rp ${account.balance.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
                            : (fp.isLoadingAccount ? 'Memuat...' : 'Rp 0');

                        return Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppTheme.slate200,
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.emerald50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 16,
                                        color: AppTheme.emerald700,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Saldo: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.slate600,
                                      ),
                                    ),
                                    Text(
                                      _isBalanceVisible
                                          ? balanceText
                                          : 'Rp ••••••••',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.slate900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(
                                      () => _isBalanceVisible =
                                          !_isBalanceVisible,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      _isBalanceVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                      color: AppTheme.slate400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // 2. Kartu Santri (Model Swape Bertumpuk) pada bagian atas
                    Consumer2<StudentProvider, FinanceProvider>(
                      builder: (context, sp, fp, _) {
                        return StackedStudentCardsWidget(
                          students: sp.students,
                          activeStudent: sp.activeStudent,
                          cardSetting: sp.cardSetting,
                          onSelect: (student) {
                            sp.switchActiveStudent(student);
                            context.read<FinanceProvider>().refreshAll(
                              student.nis,
                              studentId: student.id,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Quick Action Menu (Top-Up, Tagihan, Mutasi, Riwayat)
                    _buildQuickActionGrid(context, targetStudent),
                    const SizedBox(height: 22),

                    // Banner Tunggakan SPP jika ada
                    if (financeProvider.billSummary != null &&
                        financeProvider.billSummary!.hasArrears)
                      _buildArrearsBanner(
                        context,
                        targetStudent,
                        financeProvider.billSummary!,
                      ),

                    // Limit Belanja Harian Koperasi Santri
                    if (financeProvider.currentAccount != null)
                      _buildKoperasiLimitCard(financeProvider.currentAccount!),

                    const SizedBox(height: 24),

                    // Transaksi Mutasi Terakhir
                    _buildRecentTransactionsSection(
                      context,
                      targetStudent,
                      financeProvider,
                    ),
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
              MaterialPageRoute(builder: (_) => TopUpScreen(student: student)),
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
              MaterialPageRoute(builder: (_) => BillsScreen(student: student)),
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
              separatorBuilder: (_, index) =>
                  const Divider(height: 1, color: AppTheme.slate100),
              itemBuilder: (context, index) {
                final item = movements[index];
                final isCredit = item.isCredit;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                        : (isCredit
                              ? 'Setoran Tabungan'
                              : 'Penarikan / Belanja'),
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
