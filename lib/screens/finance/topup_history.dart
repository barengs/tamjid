import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/finance.dart';
import '../../models/santri.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';
import 'topup_screen.dart';

/// Halaman Riwayat Status Pengajuan Top-Up Transfer Bank
class TopUpHistoryScreen extends StatefulWidget {
  final Student? student;

  const TopUpHistoryScreen({super.key, this.student});

  @override
  State<TopUpHistoryScreen> createState() => _TopUpHistoryScreenState();
}

class _TopUpHistoryScreenState extends State<TopUpHistoryScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _filter = 'all'; // all | waiting | success | failed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Student? get _targetStudent =>
      widget.student ?? context.read<StudentProvider>().activeStudent;

  void _load() {
    final student = _targetStudent;
    if (student != null && student.nis.isNotEmpty) {
      context.read<FinanceProvider>().fetchTopUpHistory(student.nis);
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final history = financeProvider.topUpHistory;

    final filtered = history.where((item) {
      if (_filter == 'waiting') return item.isWaitingVerification;
      if (_filter == 'success') return item.isSuccess;
      if (_filter == 'failed') return item.isFailed;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Status Pengajuan Top-Up'),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.emerald600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Top-Up Baru'),
        onPressed: () {
          final student = _targetStudent;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TopUpScreen(student: student),
            ),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Chips
              Row(
                children: [
                  _FilterChip(
                    label: 'Semua',
                    selected: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Menunggu',
                    selected: _filter == 'waiting',
                    onTap: () => setState(() => _filter = 'waiting'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Berhasil',
                    selected: _filter == 'success',
                    onTap: () => setState(() => _filter = 'success'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Ditolak',
                    selected: _filter == 'failed',
                    onTap: () => setState(() => _filter = 'failed'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (financeProvider.isLoadingTopUps)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filtered.isEmpty)
                _buildEmptyState()
              else
                ...filtered.map((item) => _buildTopUpCard(item)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.slate100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              size: 36,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Pengajuan Top-Up',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ajukan top-up tabungan santri melalui transfer bank menggunakan tombol di bawah.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpCard(TopUpRequestItem item) {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    if (item.isSuccess) {
      badgeColor = AppTheme.emerald600;
      badgeText = 'Berhasil';
      badgeIcon = Icons.check_circle_rounded;
    } else if (item.isWaitingVerification) {
      badgeColor = AppTheme.amber500;
      badgeText = 'Menunggu Verifikasi';
      badgeIcon = Icons.hourglass_top_rounded;
    } else {
      badgeColor = AppTheme.rose500;
      badgeText = 'Ditolak';
      badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ref number
              Text(
                item.paymentRef?.isNotEmpty == true
                    ? item.paymentRef!
                    : 'REF #${item.id}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate700,
                ),
              ),

              // Status Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, color: badgeColor, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nominal & Tanggal
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nominal Transfer',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.slate400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _currencyFormat.format(item.amount),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.slate900,
                    ),
                  ),
                ],
              ),
              Text(
                _formatDate(item.createdAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.slate400,
                ),
              ),
            ],
          ),

          if (item.packageName != null && item.packageName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Paket: ${item.packageName}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.slate600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.slate50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Catatan: ${item.notes}',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.slate600,
                ),
              ),
            ),
          ],
        ],
      ),
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
