import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/kesantrian.dart';
import '../../models/santri.dart';
import '../../providers/finance_provider.dart';
import '../../providers/kesantrian_provider.dart';
import '../../providers/student_provider.dart';
import '../../widgets/student_card_qr.dart';

/// Halaman detail dan daftar santri milik wali
class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  int? _lastFetchedStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndFetchEducationInfo());
  }

  void _checkAndFetchEducationInfo() {
    if (!mounted) return;
    final activeStudent = context.read<StudentProvider>().activeStudent;
    if (activeStudent != null && activeStudent.id > 0 && activeStudent.id != _lastFetchedStudentId) {
      _lastFetchedStudentId = activeStudent.id;
      context.read<KesantrianProvider>().fetchHostelInfo(activeStudent.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();
    final kesantrianProvider = context.watch<KesantrianProvider>();
    final students = studentProvider.students;
    final activeStudent = studentProvider.activeStudent;
    final eduInfo = kesantrianProvider.hostelInfo;

    // Sinkronkan info kelas dan asrama otomatis jika santri aktif berubah
    if (activeStudent != null && activeStudent.id > 0 && activeStudent.id != _lastFetchedStudentId) {
      _lastFetchedStudentId = activeStudent.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<KesantrianProvider>().fetchHostelInfo(activeStudent.id);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.slate50,
      appBar: AppBar(title: const Text('Anak Saya')),
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
                  // 1. Kartu Santri (Model Swape Bertumpuk) pada bagian paling atas
                  StackedStudentCardsWidget(
                    students: students,
                    activeStudent: activeStudent,
                    cardSetting: studentProvider.cardSetting,
                    onSelect: (student) {
                      studentProvider.switchActiveStudent(student);
                      // Muat ulang info pendidikan santri yang baru dipilih
                      if (student.id > 0) {
                        context.read<KesantrianProvider>().fetchHostelInfo(student.id);
                      }
                      // Sinkronkan saldo rekening saat berganti kartu santri
                      context.read<FinanceProvider>().refreshAll(
                            student.nis,
                            studentId: student.id,
                          );
                    },
                  ),

                  if (activeStudent != null) ...[
                    const SizedBox(height: 16),

                    // 2. Strip Info Pendidikan (jenjang, sekolah, asrama, kamar)
                    _EducationInfoStrip(student: activeStudent, eduInfo: eduInfo),
                    const SizedBox(height: 14),

                    // 3. Detail Biodata Santri
                    _ActiveStudentHeaderCard(student: activeStudent),
                    const SizedBox(height: 24),

                    // 4. Tab / List Semua Santri
                    const Text(
                      'Daftar Anak / Santri',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

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
                          // Muat ulang info pendidikan santri yang baru dipilih
                          if (student.id > 0) {
                            context.read<KesantrianProvider>().fetchHostelInfo(student.id);
                          }
                          // Sinkronkan saldo rekening saat berganti kartu santri
                          context.read<FinanceProvider>().refreshAll(
                                student.nis,
                                studentId: student.id,
                              );
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
        borderRadius: BorderRadius.circular(16),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.emerald600, AppTheme.emerald500],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  student.firstName.isNotEmpty
                      ? student.firstName[0].toUpperCase()
                      : 'S',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'NIS: ${student.nis}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.emerald700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.emerald50,
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
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppTheme.slate200),
          const SizedBox(height: 14),

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

class _EducationInfoStrip extends StatelessWidget {
  final Student student;
  final HostelRoomInfo? eduInfo;

  const _EducationInfoStrip({required this.student, this.eduInfo});

  @override
  Widget build(BuildContext context) {
    // Pastikan eduInfo yang dipakai cocok dengan ID santri aktif saat ini
    final isMatching = eduInfo == null || eduInfo!.studentId == null || eduInfo!.studentId == student.id;
    final validEduInfo = isMatching ? eduInfo : null;

    final institutionName = validEduInfo?.institutionName;
    final className = validEduInfo?.className ??
        (student.className.isNotEmpty ? student.className : null);
    final classGroupName = validEduInfo?.classGroupName;
    final academicYear = validEduInfo?.academicYear;
    final programName = student.programName ?? validEduInfo?.programName;
    final hostelName = validEduInfo?.hostelName ?? student.hostelName;
    final roomName = validEduInfo?.roomName;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.school_rounded,
                size: 18,
                color: AppTheme.emerald600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  institutionName ?? programName ?? 'Pendidikan Pesantren',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.slate900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.emerald50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  student.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.emerald700,
                  ),
                ),
              ),
            ],
          ),
          if (className != null || classGroupName != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: AppTheme.slate100),
            ),
            Row(
              children: [
                const Icon(Icons.class_rounded, size: 16, color: AppTheme.emerald600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kelas: ${className ?? '-'}${classGroupName != null ? ' • Rombel: $classGroupName' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.slate600, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          if (academicYear != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: AppTheme.emerald600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tahun Ajaran: $academicYear',
                    style: const TextStyle(fontSize: 12, color: AppTheme.slate600, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
          if (hostelName != null && hostelName.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: AppTheme.slate100),
            ),
            Row(
              children: [
                const Icon(
                  Icons.hotel_rounded,
                  size: 16,
                  color: AppTheme.teal600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Asrama: $hostelName${roomName != null && roomName != 'Kamar Belum Ditentukan' ? ' • Kamar: $roomName' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.slate600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
