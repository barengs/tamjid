import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/kesantrian.dart';
import '../../models/santri.dart';
import '../../providers/kesantrian_provider.dart';
import '../../providers/student_provider.dart';

/// Halaman Presensi & Catatan Kehadiran Santri
class ReportScreen extends StatefulWidget {
  final Student? student;

  const ReportScreen({super.key, this.student});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String _filter = 'all'; // all | hadir | izin | sakit | alpa

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Student? get _targetStudent =>
      widget.student ?? context.read<StudentProvider>().activeStudent;

  void _load() {
    final student = _targetStudent;
    if (student != null && student.id > 0) {
      context.read<KesantrianProvider>().fetchPresences(student.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kp = context.watch<KesantrianProvider>();
    final presenceList = kp.presenceList;

    final filtered = presenceList.where((p) {
      if (_filter == 'all') return true;
      return p.status == _filter;
    }).toList();

    final totalHadir = presenceList.where((p) => p.status == 'hadir').length;
    final totalIzin = presenceList.where((p) => p.status == 'izin').length;
    final totalSakit = presenceList.where((p) => p.status == 'sakit').length;
    final totalAlpa = presenceList.where((p) => p.status == 'alpa').length;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Presensi Santri'),
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
              // Summary Ringkasan Kehadiran
              _buildAttendanceSummary(
                hadir: totalHadir,
                izin: totalIzin,
                sakit: totalSakit,
                alpa: totalAlpa,
              ),
              const SizedBox(height: 20),

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
                    label: 'Hadir',
                    selected: _filter == 'hadir',
                    onTap: () => setState(() => _filter = 'hadir'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Izin',
                    selected: _filter == 'izin',
                    onTap: () => setState(() => _filter = 'izin'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Sakit',
                    selected: _filter == 'sakit',
                    onTap: () => setState(() => _filter = 'sakit'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Alpa',
                    selected: _filter == 'alpa',
                    onTap: () => setState(() => _filter = 'alpa'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (kp.isLoadingPresence)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (filtered.isEmpty)
                _buildEmptyState()
              else
                ...filtered.map((item) => _buildPresenceTile(item)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceSummary({
    required int hadir,
    required int izin,
    required int sakit,
    required int alpa,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistik Kehadiran Kelas / Halaqah',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBadge(
                  label: 'Hadir',
                  count: hadir,
                  color: AppTheme.emerald600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBadge(
                  label: 'Izin',
                  count: izin,
                  color: AppTheme.indigo500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBadge(
                  label: 'Sakit',
                  count: sakit,
                  color: AppTheme.amber500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MetricBadge(
                  label: 'Alpa',
                  count: alpa,
                  color: AppTheme.rose500,
                ),
              ),
            ],
          ),
        ],
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
            decoration: const BoxDecoration(
              color: AppTheme.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checklist_rounded,
              size: 36,
              color: AppTheme.emerald600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Catatan Presensi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Catatan kehadiran pembelajaran santri akan otomatis muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceTile(StudentPresenceItem item) {
    Color badgeColor;
    String badgeLabel;
    IconData badgeIcon;

    switch (item.status) {
      case 'hadir':
        badgeColor = AppTheme.emerald600;
        badgeLabel = 'Hadir';
        badgeIcon = Icons.check_circle_rounded;
        break;
      case 'izin':
        badgeColor = AppTheme.indigo500;
        badgeLabel = 'Izin';
        badgeIcon = Icons.info_rounded;
        break;
      case 'sakit':
        badgeColor = AppTheme.amber500;
        badgeLabel = 'Sakit';
        badgeIcon = Icons.medical_services_rounded;
        break;
      default:
        badgeColor = AppTheme.rose500;
        badgeLabel = 'Alpa';
        badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(badgeIcon, color: badgeColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.className?.isNotEmpty == true
                      ? item.className!
                      : 'Halaqah Pembelajaran',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.slate500,
                  ),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Catatan: ${item.notes}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.slate400,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString);
      return DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(dt.toLocal());
    } catch (_) {
      return isoString;
    }
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MetricBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppTheme.slate600,
          ),
        ),
      ),
    );
  }
}
