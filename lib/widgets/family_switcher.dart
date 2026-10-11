import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/santri.dart';

/// Kartu horizontal scrollable untuk beralih di antara santri aktif
/// (Family Switcher) yang bernaung di bawah satu akun Wali.
class FamilySwitcher extends StatelessWidget {
  final List<Student> students;
  final Student? activeStudent;
  final ValueChanged<Student> onSelect;

  const FamilySwitcher({
    super.key,
    required this.students,
    required this.activeStudent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.slate200),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.slate400, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Belum ada data santri terhubung ke akun Anda.',
                style: TextStyle(color: AppTheme.slate600, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pilih Santri',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.slate900,
              ),
            ),
            Text(
              '${students.length} Santri',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.emerald700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: students.length,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final student = students[index];
              final isActive = activeStudent?.id == student.id;
              return _FamilyCard(
                student: student,
                isActive: isActive,
                onTap: () => onSelect(student),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final Student student;
  final bool isActive;
  final VoidCallback onTap;

  const _FamilyCard({
    required this.student,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? AppTheme.emerald50 : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: isActive ? 2 : 0,
      shadowColor: AppTheme.emerald600.withValues(alpha: 0.15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive ? AppTheme.emerald500 : AppTheme.slate200,
              width: isActive ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive
                        ? [AppTheme.emerald600, AppTheme.emerald500]
                        : [AppTheme.slate300, AppTheme.slate400],
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
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      student.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppTheme.emerald900 : AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NIS: ${student.nis}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? AppTheme.emerald700 : AppTheme.slate500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.emerald100
                            : AppTheme.slate100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        student.statusLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? AppTheme.emerald800
                              : AppTheme.slate600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
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
