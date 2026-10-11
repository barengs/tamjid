import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/santri.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_card_qr.dart';

/// Halaman detail dan daftar santri milik wali
class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final students = studentProvider.students;
    final activeStudent = studentProvider.activeStudent;

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(
        title: const Text('Santri Saya'),
      ),
      body: students.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 64,
                      color: AppTheme.slate300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum ada data santri terdaftar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hubungi pihak pesantren untuk menghubungkan data santri Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.slate500),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu Profil Santri Aktif
                  if (activeStudent != null) ...[
                    _ActiveStudentHeaderCard(student: activeStudent),
                    const SizedBox(height: 16),
                    StudentCardQrWidget(student: activeStudent),
                    const SizedBox(height: 24),
                  ],

                  // Tab / List Semua Santri
                  const Text(
                    'Daftar Anak / Santri',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.slate900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final student = students[index];
                      final isSelected = activeStudent?.id == student.id;

                      return _StudentListItem(
                        student: student,
                        isSelected: isSelected,
                        onTap: () {
                          studentProvider.switchActiveStudent(student);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActiveStudentHeaderCard extends StatelessWidget {
  final Student student;

  const _ActiveStudentHeaderCard({required this.student});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.slate200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.emerald600, AppTheme.emerald500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  student.firstName.isNotEmpty
                      ? student.firstName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIS: ${student.nis}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.emerald700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.emerald100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  student.statusLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.emerald800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppTheme.slate200),
          const SizedBox(height: 16),

          _DetailRow(
            icon: Icons.auto_stories_rounded,
            label: 'Program Studi',
            value: student.programName ?? 'Belum ditentukan',
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.apartment_rounded,
            label: 'Asrama / Kamar',
            value: student.hostelName ?? 'Belum ditentukan',
          ),
          const SizedBox(height: 10),
          _DetailRow(
            icon: Icons.cake_outlined,
            label: 'Tanggal Lahir',
            value: student.birthDateFormatted,
          ),
          if (student.address != null && student.address!.isNotEmpty) ...[
            const SizedBox(height: 10),
            _DetailRow(
              icon: Icons.location_on_outlined,
              label: 'Alamat Asal',
              value: student.address!,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.slate400),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.slate500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.slate800,
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentListItem extends StatelessWidget {
  final Student student;
  final bool isSelected;
  final VoidCallback onTap;

  const _StudentListItem({
    required this.student,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppTheme.emerald50 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.emerald500 : AppTheme.slate200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.emerald600 : AppTheme.slate200,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  student.firstName.isNotEmpty
                      ? student.firstName[0].toUpperCase()
                      : 'S',
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.slate700,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppTheme.emerald900
                            : AppTheme.slate900,
                      ),
                    ),
                    Text(
                      'NIS: ${student.nis}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isSelected
                            ? AppTheme.emerald700
                            : AppTheme.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.emerald600,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
