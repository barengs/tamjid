import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/kesantrian.dart';
import '../../models/santri.dart';
import '../../providers/kesantrian_provider.dart';
import '../../providers/student_provider.dart';

/// Halaman Riwayat & Formulir Pengajuan Izin Santri
class LeaveScreen extends StatefulWidget {
  final Student? student;

  const LeaveScreen({super.key, this.student});

  @override
  State<LeaveScreen> createState() => _LeaveScreenState();
}

class _LeaveScreenState extends State<LeaveScreen> {
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
      final kp = context.read<KesantrianProvider>();
      kp.fetchLeaves(student.id);
      kp.fetchLeaveTypes();
    }
  }

  void _openCreateLeaveDialog() {
    final student = _targetStudent;
    if (student == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _CreateLeaveBottomSheet(
        student: student,
        onSuccess: () => _load(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kesantrianProvider = context.watch<KesantrianProvider>();
    final report = kesantrianProvider.leaveReport;
    final leaves = report?.leaves ?? [];

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Perizinan Santri'),
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
        label: const Text('Ajukan Izin'),
        onPressed: _openCreateLeaveDialog,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Ringkasan Izin
              _buildLeaveSummaryCards(report),
              const SizedBox(height: 20),

              // Title Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Izin & Pulang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900,
                    ),
                  ),
                  Text(
                    '${leaves.length} Data',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (kesantrianProvider.isLoadingLeaves)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (leaves.isEmpty)
                _buildEmptyLeavesCard()
              else
                ...leaves.map((leave) => _buildLeaveCard(leave)),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveSummaryCards(LeaveReportSummary? report) {
    return Row(
      children: [
        Expanded(
          child: _SummaryBox(
            label: 'Total Izin',
            value: '${report?.totalLeaves ?? 0}',
            color: AppTheme.indigo500,
            icon: Icons.assignment_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryBox(
            label: 'Disetujui',
            value: '${report?.approvedLeaves ?? 0}',
            color: AppTheme.emerald600,
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryBox(
            label: 'Total Hari',
            value: '${report?.totalDays ?? 0} hari',
            color: AppTheme.amber500,
            icon: Icons.calendar_today_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyLeavesCard() {
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
              Icons.luggage_outlined,
              size: 38,
              color: AppTheme.emerald600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum Ada Pengajuan Izin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.slate800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Santri belum pernah mengajukan izin keluar pondok pesantren.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.slate400, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(StudentLeaveItem item) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (item.isApproved) {
      statusColor = AppTheme.emerald600;
      statusText = 'Disetujui';
      statusIcon = Icons.check_circle_rounded;
    } else if (item.isCompleted) {
      statusColor = AppTheme.teal600;
      statusText = 'Selesai Kembali';
      statusIcon = Icons.task_alt_rounded;
    } else if (item.isPending) {
      statusColor = AppTheme.amber500;
      statusText = 'Menunggu Persetujuan';
      statusIcon = Icons.hourglass_top_rounded;
    } else if (item.isOverdue) {
      statusColor = AppTheme.rose500;
      statusText = 'Terlambat Kembali';
      statusIcon = Icons.warning_rounded;
    } else {
      statusColor = AppTheme.rose500;
      statusText = 'Ditolak';
      statusIcon = Icons.cancel_rounded;
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
              Text(
                item.leaveNumber.isNotEmpty ? item.leaveNumber : 'Surat Izin',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tipe Izin & Durasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.typeName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
              Text(
                '${item.durationDays} Hari',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.emerald700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Rentang Tanggal
          Row(
            children: [
              const Icon(Icons.date_range_rounded, size: 14, color: AppTheme.slate400),
              const SizedBox(width: 6),
              Text(
                '${_formatDate(item.startDate)} - ${_formatDate(item.endDate)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.slate600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Alasan
          Text(
            'Keperluan: ${item.reason}',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.slate600,
            ),
          ),

          if (item.destination != null && item.destination!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Tujuan: ${item.destination}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.slate500,
              ),
            ),
          ],

          if (item.approverName != null && item.approverName!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Disetujui oleh: ${item.approverName}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.emerald600,
                fontWeight: FontWeight.w600,
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

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.slate500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom Sheet Formulir Pengajuan Izin Baru
class _CreateLeaveBottomSheet extends StatefulWidget {
  final Student student;
  final VoidCallback onSuccess;

  const _CreateLeaveBottomSheet({
    required this.student,
    required this.onSuccess,
  });

  @override
  State<_CreateLeaveBottomSheet> createState() =>
      _CreateLeaveBottomSheetState();
}

class _CreateLeaveBottomSheetState extends State<_CreateLeaveBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  final _destinationController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  LeaveTypeItem? _selectedLeaveType;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 3));

  @override
  void initState() {
    super.initState();
    final kp = context.read<KesantrianProvider>();
    if (kp.leaveTypes.isNotEmpty) {
      _selectedLeaveType = kp.leaveTypes.first;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _destinationController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final kp = context.read<KesantrianProvider>();

    final typeId = _selectedLeaveType?.id ?? 1;
    final startStr = DateFormat('yyyy-MM-dd').format(_startDate);
    final endStr = DateFormat('yyyy-MM-dd').format(_endDate);

    final result = await kp.submitLeaveRequest(
      studentId: widget.student.id,
      leaveTypeId: typeId,
      startDate: startStr,
      endDate: endStr,
      reason: _reasonController.text.trim(),
      destination: _destinationController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      widget.onSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.emerald600,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppTheme.rose500,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kp = context.watch<KesantrianProvider>();
    final leaveTypes = kp.leaveTypes;

    return Padding(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Formulir Pengajuan Izin',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Tipe Izin Dropdown
              const Text(
                'Tipe Izin',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate700),
              ),
              const SizedBox(height: 6),
              if (leaveTypes.isNotEmpty)
                DropdownButtonFormField<LeaveTypeItem>(
                  initialValue: _selectedLeaveType ?? leaveTypes.first,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    filled: true,
                    fillColor: AppTheme.slate50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.slate200),
                    ),
                  ),
                  items: leaveTypes.map((t) {
                    return DropdownMenuItem(
                      value: t,
                      child: Text(t.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedLeaveType = val),
                ),
              const SizedBox(height: 14),

              // Pilih Rentang Tanggal
              const Text(
                'Tanggal Izin s.d. Kembali',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate700),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: _pickDateRange,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.slate50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.slate200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: AppTheme.emerald600, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '${DateFormat('dd MMM yyyy', 'id_ID').format(_startDate)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_endDate)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.slate800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Alasan Izin
              const Text(
                'Alasan / Keperluan Izin',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Contoh: Menghadiri pernikahan keluarga di kampung',
                  filled: true,
                  fillColor: AppTheme.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                ),
                validator: (val) => (val == null || val.trim().isEmpty)
                    ? 'Alasan izin wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),

              // Tujuan / Alamat
              const Text(
                'Tujuan / Alamat Selama Izin',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _destinationController,
                decoration: InputDecoration(
                  hintText: 'Contoh: Rumah Orang Tua, Bandung',
                  filled: true,
                  fillColor: AppTheme.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // No HP Pendamping
              const Text(
                'Nomor HP Wali / Penjemput',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate700),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _contactPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Contoh: 08123456789',
                  filled: true,
                  fillColor: AppTheme.slate50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.slate200),
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Tombol Submit
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.emerald600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: kp.isSubmittingLeave ? null : _submit,
                  child: kp.isSubmittingLeave
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Kirim Pengajuan Izin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
