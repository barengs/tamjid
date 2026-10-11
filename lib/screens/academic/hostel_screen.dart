import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/santri.dart';
import '../../providers/kesantrian_provider.dart';
import '../../providers/student_provider.dart';

/// Halaman Informasi Asrama & Kamar Santri
class HostelScreen extends StatefulWidget {
  final Student? student;

  const HostelScreen({super.key, this.student});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
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
      context.read<KesantrianProvider>().fetchHostelInfo(student.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kp = context.watch<KesantrianProvider>();
    final info = kp.hostelInfo;
    final student = _targetStudent;

    final hostelName = info?.hostelName ?? student?.hostelName ?? 'Asrama Santri';
    final roomName = info?.roomName ?? 'Kamar Santri';
    final className = info?.className ?? 'Kelas Reguler';
    final programName = info?.programName ?? student?.programName ?? 'Pendidikan Pesantren';
    final capacity = info?.roomCapacity ?? 8;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Info Asrama & Kamar'),
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
              // Kartu Asrama Utama
              _buildHostelCard(hostelName, roomName, capacity),
              const SizedBox(height: 20),

              // Rincian Informasi Penempatan
              const Text(
                'Rincian Penempatan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 12),

              _buildDetailItem(
                icon: Icons.hotel_rounded,
                label: 'Nama Gedung / Asrama',
                value: hostelName,
                color: AppTheme.emerald600,
              ),
              _buildDetailItem(
                icon: Icons.meeting_room_rounded,
                label: 'Nomor / Nama Kamar',
                value: roomName,
                color: AppTheme.teal600,
              ),
              _buildDetailItem(
                icon: Icons.people_outline_rounded,
                label: 'Kapasitas Santri',
                value: '$capacity Santri per Kamar',
                color: AppTheme.indigo500,
              ),
              _buildDetailItem(
                icon: Icons.school_rounded,
                label: 'Kelas / Halaqah',
                value: className,
                color: AppTheme.amber500,
              ),
              _buildDetailItem(
                icon: Icons.auto_stories_rounded,
                label: 'Program Pendidikan',
                value: programName,
                color: AppTheme.emerald700,
              ),

              const SizedBox(height: 24),

              // Petunjuk & Tata Tertib Asrama
              _buildHostelRulesCard(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHostelCard(String hostelName, String roomName, int capacity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F766E), // Teal 700
            Color(0xFF0D9488), // Teal 600
            Color(0xFF14B8A6), // Teal 500
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.teal600.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.home_work_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'KOMPLEK ASRAMA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bed_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            hostelName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            roomName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.group_rounded, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                'Kapasitas: $capacity Orang',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.slate400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostelRulesCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.slate100,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.slate700, size: 18),
              SizedBox(width: 8),
              Text(
                'Tata Tertib & Jam Kunjung Asrama',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.slate900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildBulletText('Jam jenguk wali santri: Ahad (08.00 - 17.00 WIB).'),
          _buildBulletText('Santri wajib berada di asrama sebelum pukul 21.30 WIB.'),
          _buildBulletText('Untuk keperluan penitipan barang, silakan melalui pos kamtib resmi.'),
        ],
      ),
    );
  }

  Widget _buildBulletText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppTheme.slate600, fontSize: 12)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.slate600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
