import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/kesantrian.dart';
import '../../models/santri.dart';
import '../../providers/kesantrian_provider.dart';
import '../../providers/student_provider.dart';

/// Halaman Riwayat Pelanggaran Disiplin & Poin Kamtib Santri
class ViolationScreen extends StatefulWidget {
  final Student? student;

  const ViolationScreen({super.key, this.student});

  @override
  State<ViolationScreen> createState() => _ViolationScreenState();
}

class _ViolationScreenState extends State<ViolationScreen> {
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
      context.read<KesantrianProvider>().fetchViolations(student.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kesantrianProvider = context.watch<KesantrianProvider>();
    final report = kesantrianProvider.violationReport;
    final violations = report?.violations ?? [];

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Kedisiplinan & Pelanggaran'),
        actions: [
          IconButton(
            tooltip: 'Segarkan',
            icon: const Icon(Icons.refresh_rounded),
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
              // Header Summary Card (Total Poin, Jumlah Pelanggaran, Status)
              _buildPointsSummaryCard(report),
              const SizedBox(height: 20),

              // Title Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Catatan Pelanggaran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900,
                    ),
                  ),
                  Text(
                    '${violations.length} Catatan',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (kesantrianProvider.isLoadingViolations)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (violations.isEmpty)
                _buildCleanDisciplineCard()
              else
                ...violations.map((v) => _buildViolationCard(v)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPointsSummaryCard(ViolationReportSummary? report) {
    final totalPoints = report?.totalPoints ?? 0;
    final totalViolations = report?.totalViolations ?? 0;

    // Tingkat keparahan poin
    Color badgeColor;
    String statusTitle;
    String statusDesc;

    if (totalPoints == 0) {
      badgeColor = AppTheme.emerald600;
      statusTitle = 'Sangat Baik (Taat Disiplin)';
      statusDesc = 'Alhamdulillah, santri belum memiliki catatan pelanggaran.';
    } else if (totalPoints <= 25) {
      badgeColor = AppTheme.amber500;
      statusTitle = 'Perhatian Ringan';
      statusDesc = 'Poin kedisiplinan masih dalam batas wajar binaan.';
    } else {
      badgeColor = AppTheme.rose500;
      statusTitle = 'Perhatian Khusus';
      statusDesc = 'Poin pelanggaran telah mencapai ambang pembinaan kamtib.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: AppTheme.slate200.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: badgeColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Poin Pelanggaran',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.slate500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$totalPoints Poin',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.slate100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '$totalViolations Kali',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.slate100),
          const SizedBox(height: 12),
          Text(
            statusTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            statusDesc,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.slate600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanDisciplineCard() {
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
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppTheme.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 40,
              color: AppTheme.emerald600,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Tidak Ada Catatan Pelanggaran',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Santri memiliki rekam jejak kedisiplinan yang sangat baik di pondok pesantren.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.slate500,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationCard(StudentViolationItem item) {
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
              // Kategori Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.categoryName,
                  style: const TextStyle(
                    color: AppTheme.rose500,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Tanggal
              Text(
                _formatDate(item.violationDate),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.slate400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Judul Pelanggaran & Poin
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2), // Rose 50
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDD3)), // Rose 200
                ),
                child: Text(
                  '+${item.point} Poin',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.rose500,
                  ),
                ),
              ),
            ],
          ),

          if (item.notes != null && item.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Keterangan: ${item.notes}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.slate600,
                height: 1.3,
              ),
            ),
          ],

          if (item.sanctionName != null && item.sanctionName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.amber500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.amber500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.gavel_rounded,
                    color: AppTheme.amber500,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Sanksi / Pembinaan: ${item.sanctionName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
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
      final dt = DateTime.parse(isoString);
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt.toLocal());
    } catch (_) {
      return isoString;
    }
  }
}
