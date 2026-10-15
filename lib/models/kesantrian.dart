// Model data kedisiplinan (pelanggaran), perizinan, presensi, dan info asrama/kamar.
// Terhubung dengan backend smp-be.

class StudentViolationItem {
  final int id;
  final String title;
  final String categoryName;
  final int point;
  final String violationDate;
  final String? notes;
  final String status;
  final String? sanctionName;

  const StudentViolationItem({
    required this.id,
    required this.title,
    required this.categoryName,
    required this.point,
    required this.violationDate,
    this.notes,
    required this.status,
    this.sanctionName,
  });

  factory StudentViolationItem.fromJson(Map<String, dynamic> json) {
    final v = json['violation'] as Map<String, dynamic>?;
    final cat = v?['category'] as Map<String, dynamic>?;
    final sanctions = json['sanctions'] as List<dynamic>?;
    String? sanctionTitle;
    if (sanctions != null && sanctions.isNotEmpty) {
      final s = sanctions.first as Map<String, dynamic>?;
      sanctionTitle = s?['sanction']?['name']?.toString() ??
          s?['sanction_name']?.toString();
    }

    return StudentViolationItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      title: v?['name']?.toString() ?? 'Pelanggaran Disiplin',
      categoryName: cat?['name']?.toString() ?? 'Umum',
      point: v?['point'] is num
          ? (v!['point'] as num).toInt()
          : (json['point'] is num ? (json['point'] as num).toInt() : 0),
      violationDate: json['violation_date']?.toString() ?? '',
      notes: json['notes']?.toString(),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      sanctionName: sanctionTitle,
    );
  }

  bool get isPending => status == 'pending';
  bool get isProcessed => status == 'processed' || status == 'verified';
}

class ViolationReportSummary {
  final int totalViolations;
  final int totalPoints;
  final int pendingCount;
  final int processedCount;
  final List<StudentViolationItem> violations;

  const ViolationReportSummary({
    required this.totalViolations,
    required this.totalPoints,
    required this.pendingCount,
    required this.processedCount,
    required this.violations,
  });

  factory ViolationReportSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>?;
    final vListRaw = json['violations'] as List<dynamic>? ?? [];

    return ViolationReportSummary(
      totalViolations: summary?['total_violations'] is num
          ? (summary!['total_violations'] as num).toInt()
          : vListRaw.length,
      totalPoints: summary?['total_points'] is num
          ? (summary!['total_points'] as num).toInt()
          : 0,
      pendingCount: summary?['pending'] is num
          ? (summary!['pending'] as num).toInt()
          : 0,
      processedCount: summary?['processed'] is num
          ? (summary!['processed'] as num).toInt()
          : 0,
      violations: vListRaw
          .map((item) =>
              StudentViolationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class LeaveTypeItem {
  final int id;
  final String name;
  final int? maxDays;

  const LeaveTypeItem({
    required this.id,
    required this.name,
    this.maxDays,
  });

  factory LeaveTypeItem.fromJson(Map<String, dynamic> json) {
    return LeaveTypeItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      name: json['name']?.toString() ?? '',
      maxDays: json['max_days'] is num ? (json['max_days'] as num).toInt() : null,
    );
  }
}

class StudentLeaveItem {
  final int id;
  final String leaveNumber;
  final String typeName;
  final String startDate;
  final String endDate;
  final int durationDays;
  final String reason;
  final String? destination;
  final String status;
  final String? approverName;
  final bool hasPenalty;
  final String? penaltyNotes;

  const StudentLeaveItem({
    required this.id,
    required this.leaveNumber,
    required this.typeName,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.reason,
    this.destination,
    required this.status,
    this.approverName,
    required this.hasPenalty,
    this.penaltyNotes,
  });

  factory StudentLeaveItem.fromJson(Map<String, dynamic> json) {
    final lt = json['leave_type'] as Map<String, dynamic>?;
    final app = json['approver'] as Map<String, dynamic>?;

    return StudentLeaveItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      leaveNumber: json['leave_number']?.toString() ?? '',
      typeName: lt?['name']?.toString() ?? json['leave_type_name']?.toString() ?? 'Izin Santri',
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
      durationDays: json['duration_days'] is num
          ? (json['duration_days'] as num).toInt()
          : 1,
      reason: json['reason']?.toString() ?? '',
      destination: json['destination']?.toString(),
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      approverName: app?['name']?.toString(),
      hasPenalty: json['has_penalty'] == true,
      penaltyNotes: json['penalty_notes']?.toString(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isOverdue => status == 'overdue';
}

class LeaveReportSummary {
  final int totalLeaves;
  final int approvedLeaves;
  final int rejectedLeaves;
  final int completedLeaves;
  final int overdueLeaves;
  final int totalDays;
  final List<StudentLeaveItem> leaves;

  const LeaveReportSummary({
    required this.totalLeaves,
    required this.approvedLeaves,
    required this.rejectedLeaves,
    required this.completedLeaves,
    required this.overdueLeaves,
    required this.totalDays,
    required this.leaves,
  });

  factory LeaveReportSummary.fromJson(Map<String, dynamic> json) {
    final s = json['summary'] as Map<String, dynamic>?;
    final leavesRaw = json['leaves'] as List<dynamic>? ?? [];

    return LeaveReportSummary(
      totalLeaves: s?['total_leaves'] is num ? (s!['total_leaves'] as num).toInt() : leavesRaw.length,
      approvedLeaves: s?['approved_leaves'] is num ? (s!['approved_leaves'] as num).toInt() : 0,
      rejectedLeaves: s?['rejected_leaves'] is num ? (s!['rejected_leaves'] as num).toInt() : 0,
      completedLeaves: s?['completed_leaves'] is num ? (s!['completed_leaves'] as num).toInt() : 0,
      overdueLeaves: s?['overdue_leaves'] is num ? (s!['overdue_leaves'] as num).toInt() : 0,
      totalDays: s?['total_days_on_leave'] is num ? (s!['total_days_on_leave'] as num).toInt() : 0,
      leaves: leavesRaw
          .map((item) =>
              StudentLeaveItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class StudentPresenceItem {
  final int id;
  final String date;
  final String status; // hadir, sakit, izin, alpa
  final String? className;
  final String? schoolName; // Nama lembaga / sekolah pendidikan
  final String? classGroupName; // Nama rombel / class group
  final String? studyName; // Nama pelajaran / study
  final String? teacherName; // Nama guru / staff pengajar
  final String? academicYear; // Tahun ajaran
  final String? notes;

  const StudentPresenceItem({
    required this.id,
    required this.date,
    required this.status,
    this.className,
    this.schoolName,
    this.classGroupName,
    this.studyName,
    this.teacherName,
    this.academicYear,
    this.notes,
  });

  factory StudentPresenceItem.fromJson(Map<String, dynamic> json) {
    final sched = json['meeting_schedule']?['schedule'];
    final classSchedule = sched?['classSchedule'];
    final classroom = sched?['classroom'];
    final classGroup = sched?['classGroup'];
    final study = sched?['study'];
    final teacher = sched?['teacher'];

    return StudentPresenceItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString().toLowerCase() ?? 'hadir',
      className: classroom?['name']?.toString(),
      schoolName: classSchedule?['education']?['name']?.toString() ??
          classSchedule?['educational_institution']?['name']?.toString(),
      classGroupName: classGroup?['name']?.toString(),
      studyName: study?['name']?.toString(),
      teacherName: teacher?['first_name']?.toString() ??
          teacher?['name']?.toString(),
      academicYear: classSchedule?['academic_year']?.toString() ??
          classSchedule?['academicYear']?.toString(),
      notes: json['notes']?.toString(),
    );
  }
}

class HostelRoomInfo {
  final int? studentId;
  final String hostelName;
  final String roomName;
  final int? roomCapacity;
  final String? className;
  final String? programName;
  final String? institutionName; // Nama sekolah / lembaga pendidikan
  final String? classGroupName; // Nama rombel (class group)
  final String? academicYear; // Tahun ajaran aktif

  const HostelRoomInfo({
    this.studentId,
    required this.hostelName,
    required this.roomName,
    this.roomCapacity,
    this.className,
    this.programName,
    this.institutionName,
    this.classGroupName,
    this.academicYear,
  });

  factory HostelRoomInfo.fromJson(Map<String, dynamic> json) {
    // Unpack inner 'data' map if present from API response wrapping
    final root = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final currentRoom = root['current_room'] as Map<String, dynamic>?;
    final currentClass = root['current_class'] as Map<String, dynamic>?;
    final hostel = root['hostel'] as Map<String, dynamic>?;

    final hName = currentRoom?['hostel_name']?.toString() ??
        hostel?['name']?.toString() ??
        'Asrama Belum Ditentukan';
    final rName = currentRoom?['room_name']?.toString() ?? 'Kamar Belum Ditentukan';

    int? parseStudentId(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val != null) return int.tryParse(val.toString());
      return null;
    }

    return HostelRoomInfo(
      studentId: parseStudentId(root['id']),
      hostelName: hName,
      roomName: rName,
      roomCapacity: currentRoom?['room_capacity'] is num
          ? (currentRoom!['room_capacity'] as num).toInt()
          : null,
      className: currentClass?['class_name']?.toString(),
      programName: root['program']?['name']?.toString(),
      institutionName: currentClass?['institution_name']?.toString(),
      classGroupName: currentClass?['class_group_name']?.toString(),
      academicYear: currentClass?['academic_year']?.toString(),
    );
  }
}
