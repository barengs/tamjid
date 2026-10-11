import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/finance.dart';
import '../../models/santri.dart';
import '../../providers/finance_provider.dart';
import '../../providers/student_provider.dart';

/// Halaman Riwayat Mutasi Rekening Santri (Semua, Masuk / Kredit, Keluar / Debit)
class MutationScreen extends StatefulWidget {
  final Student? student;

  const MutationScreen({super.key, this.student});

  @override
  State<MutationScreen> createState() => _MutationScreenState();
}

class _MutationScreenState extends State<MutationScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  String _filter = 'all'; // all | credit | debit

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
      context.read<FinanceProvider>().fetchMovements(student.nis);
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final movements = financeProvider.movements;

    final filtered = movements.where((m) {
      if (_filter == 'credit') return m.isCredit;
      if (_filter == 'debit') return m.isDebit;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Riwayat Mutasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan',
            onPressed: _load,
          ),
        ],
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
                    label: 'Dana Masuk (+)',
                    selected: _filter == 'credit',
                    onTap: () => setState(() => _filter = 'credit'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Dana Keluar (-)',
                    selected: _filter == 'debit',
                    onTap: () => setState(() => _filter = 'debit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (financeProvider.isLoadingMovements)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filtered.isEmpty)
                _buildEmptyState()
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
                    itemCount: filtered.length,
                    separatorBuilder: (_, index) => const Divider(
                      height: 1,
                      color: AppTheme.slate100,
                    ),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildMovementTile(item);
                    },
                  ),
                ),
              const SizedBox(height: 32),
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
              Icons.receipt_long_outlined,
              size: 36,
              color: AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Mutasi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tidak ada riwayat perbankan yang sesuai dengan filter yang dipilih.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementTile(AccountMovementItem item) {
    final isCredit = item.isCredit;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                isCredit ? AppTheme.emerald50 : const Color(0xFFFFF1F2),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit ? AppTheme.emerald600 : AppTheme.rose500,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description?.isNotEmpty == true
                      ? item.description!
                      : (isCredit ? 'Setoran Tabungan' : 'Penarikan / Transaksi'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.slate400,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      'Saldo Awal: ${_currencyFormat.format(item.balanceBefore)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.slate500,
                      ),
                    ),
                    const Text(' \u2192 ',
                        style:
                            TextStyle(fontSize: 10, color: AppTheme.slate400)),
                    Text(
                      'Akhir: ${_currencyFormat.format(item.balanceAfter)}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.slate700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? "+" : "-"} ${_currencyFormat.format(item.amount)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isCredit ? AppTheme.emerald600 : AppTheme.rose500,
            ),
          ),
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
