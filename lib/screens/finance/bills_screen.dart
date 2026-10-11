import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/finance.dart';
import '../../models/santri.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';

/// Halaman Tagihan & Tunggakan SPP Santri
class BillsScreen extends StatefulWidget {
  final Student? student;

  const BillsScreen({super.key, this.student});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _filter = 'all'; // all | unpaid | overdue | paid

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
      context.read<FinanceProvider>().fetchBills(student.nis);
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final summary = financeProvider.billSummary;

    final bills = summary?.bills ?? [];
    final filteredBills = bills.where((b) {
      switch (_filter) {
        case 'unpaid':
          return b.isUnpaid || b.isPartial;
        case 'overdue':
          return b.isOverdue && !b.isPaid;
        case 'paid':
          return b.isPaid;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(title: const Text('Tagihan SPP')),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(summary),
              const SizedBox(height: 20),
              _buildFilterChips(),
              const SizedBox(height: 16),
              if (financeProvider.isLoadingBills)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filteredBills.isEmpty)
                _buildEmptyState()
              else
                ...filteredBills.map((b) => _buildBillTile(b)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BillSummary? summary) {
    return Row(
      children: [
        // Total Tagihan Belum Dibayar
        Expanded(
          child: _SummaryCard(
            icon: Icons.pending_actions_rounded,
            color: AppTheme.amber500,
            label: 'Belum Dibayar',
            value: _currencyFormat.format(summary?.totalUnpaidAll ?? 0),
          ),
        ),
        const SizedBox(width: 12),
        // Tunggakan
        Expanded(
          child: _SummaryCard(
            icon: Icons.warning_amber_rounded,
            color: AppTheme.rose500,
            label: 'Tunggakan',
            value: _currencyFormat.format(summary?.totalArrears ?? 0),
          ),
        ),
        const SizedBox(width: 12),
        // Jumlah Bulan Tunggakan
        Expanded(
          child: _SummaryCard(
            icon: Icons.calendar_month_rounded,
            color: AppTheme.emerald600,
            label: 'Bulan Tunggakan',
            value: '${summary?.overdueMonthsCount ?? 0} bulan',
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        _FilterChip(
          label: 'Semua',
          selected: _filter == 'all',
          onTap: () => setState(() => _filter = 'all'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Belum Lunas',
          selected: _filter == 'unpaid',
          onTap: () => setState(() => _filter = 'unpaid'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Tunggakan',
          selected: _filter == 'overdue',
          onTap: () => setState(() => _filter = 'overdue'),
        ),
        const SizedBox(width: 8),
        _FilterChip(
          label: 'Lunas',
          selected: _filter == 'paid',
          onTap: () => setState(() => _filter = 'paid'),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
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
              color: AppTheme.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 36,
              color: AppTheme.emerald600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _filter == 'all'
                ? 'Belum Ada Tagihan'
                : 'Tidak Ada Tagihan dengan Filter "$_filter"',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Semua tagihan SPP santri Anda lunas atau belum diterbitkan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBillTile(BillItem bill) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (bill.status) {
      case 'paid':
        statusColor = AppTheme.emerald600;
        statusLabel = 'Lunas';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'partial':
        statusColor = AppTheme.amber500;
        statusLabel = 'Sebagian';
        statusIcon = Icons.timelapse_rounded;
        break;
      case 'overdue':
        statusColor = AppTheme.rose500;
        statusLabel = 'Tunggakan';
        statusIcon = Icons.error_rounded;
        break;
      case 'waived':
        statusColor = AppTheme.slate400;
        statusLabel = 'Dihapuskan';
        statusIcon = Icons.remove_circle_rounded;
        break;
      default:
        statusColor = AppTheme.indigo500;
        statusLabel = 'Belum Lunas';
        statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bill.isOverdue && !bill.isPaid
              ? AppTheme.rose500.withValues(alpha: 0.4)
              : AppTheme.slate200,
        ),
      ),
      child: Row(
        children: [
          // Ikon Status Tagihan
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24),
          ),
          const SizedBox(width: 14),

          // Detail Tagihan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatPeriodLabel(bill.period),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (bill.dueDate != null && bill.dueDate!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Jatuh tempo: ${_formatDate(bill.dueDate!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.slate400,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (bill.paidAmount > 0 && !bill.isPaid) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Terbayar: ${_currencyFormat.format(bill.paidAmount)}',
                    style: const TextStyle(
                      color: AppTheme.slate500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Jumlah Tagihan
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _currencyFormat.format(bill.isPaid ? bill.amount : bill.remaining),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: bill.isPaid ? AppTheme.emerald600 : AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 2),
              if (!bill.isPaid)
                Text(
                  'dari ${_currencyFormat.format(bill.amount)}',
                  style: const TextStyle(
                    color: AppTheme.slate400,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPeriodLabel(String period) {
    // period dalam format YYYY-MM
    try {
      final parts = period.split('-');
      if (parts.length != 2) return period;
      final month = int.tryParse(parts[1]) ?? 1;
      const bulanNames = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ];
      return '${bulanNames[month - 1]} ${parts[0]}';
    } catch (_) {
      return period;
    }
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
