import 'package:intl/intl.dart';

/// Model untuk data santri (anak wali).
/// Berdasarkan response endpoint `GET /api/main/parent/nik/{nik}/cek`
/// dan `GET /api/main/student/{id}`.
class Student {
  final int id;
  final String? parentId; // NIK Wali (string, primary key di parent_profiles)
  final String nis; // NIS santri = nomor rekening bank
  final String? period;
  final String? nik; // NIK santri (jika ada)
  final String? kk;
  final String firstName;
  final String? lastName;
  final String? gender;
  final String? address;
  final String? bornIn;
  final String? bornAt; // Tgl lahir
  final String? lastEducation;
  final int? villageId;
  final String? village;
  final String? district;
  final String? postalCode;
  final String? phone;
  final int? hostelId;
  final String? hostelName;
  final int? programId;
  final String? programName;
  final String status; // active, pending, graduated, etc.
  final String? photo;
  final int? userId;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  Student({
    required this.id,
    this.parentId,
    required this.nis,
    this.period,
    this.nik,
    this.kk,
    required this.firstName,
    this.lastName,
    this.gender,
    this.address,
    this.bornIn,
    this.bornAt,
    this.lastEducation,
    this.villageId,
    this.village,
    this.district,
    this.postalCode,
    this.phone,
    this.hostelId,
    this.hostelName,
    this.programId,
    this.programName,
    required this.status,
    this.photo,
    this.userId,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName ${lastName ?? ''}'.trim();

  String get birthDateFormatted {
    if (bornAt == null || bornAt!.isEmpty) return '-';
    try {
      final dt = DateTime.tryParse(bornAt!);
      if (dt != null) return ddMMMyyyy(dt);
    } catch (_) {}
    return bornAt!;
  }

  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'active':
      case 'aktif':
        return 'Aktif';
      case 'pending':
      case 'menunggu':
        return 'Menunggu';
      case 'graduated':
      case 'lulus':
        return 'Lulus';
      case 'dropped_out':
      case 'keluar':
        return 'Keluar';
      default:
        return status;
    }
  }

  factory Student.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      return int.tryParse(val.toString());
    }

    return Student(
      id: parseInt(json['id']) ?? 0,
      parentId: json['parent_id']?.toString(),
      nis: json['nis']?.toString() ?? '',
      period: json['period']?.toString(),
      nik: json['nik']?.toString(),
      kk: json['kk']?.toString(),
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString(),
      gender: json['gender']?.toString(),
      address: json['address']?.toString(),
      bornIn: json['born_in']?.toString(),
      bornAt: json['born_at']?.toString(),
      lastEducation: json['last_education']?.toString(),
      villageId: parseInt(json['village_id']),
      village: json['village']?.toString(),
      district: json['district']?.toString(),
      postalCode: json['postal_code']?.toString(),
      phone: json['phone']?.toString(),
      hostelId: parseInt(json['hostel_id']),
      hostelName: json['hostel_name']?.toString() ?? json['hostel']?['name']?.toString(),
      programId: parseInt(json['program_id']),
      programName: json['program_name']?.toString() ?? json['program']?['name']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      photo: json['photo']?.toString(),
      userId: parseInt(json['user_id']),
      deletedAt: json['deleted_at']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'parent_id': parentId,
    'nis': nis,
    'period': period,
    'nik': nik,
    'kk': kk,
    'first_name': firstName,
    'last_name': lastName,
    'gender': gender,
    'address': address,
    'born_in': bornIn,
    'born_at': bornAt,
    'last_education': lastEducation,
    'village_id': villageId,
    'village': village,
    'district': district,
    'postal_code': postalCode,
    'phone': phone,
    'hostel_id': hostelId,
    'hostel_name': hostelName,
    'program_id': programId,
    'program_name': programName,
    'status': status,
    'photo': photo,
    'user_id': userId,
    'deleted_at': deletedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

String ddMMMyyyy(DateTime date) {
  final formatter = DateFormat('dd MMM yyyy', 'id_ID');
  return formatter.format(date);
}

/// Data profil wali beserta daftar santri yang bernaung di bawah NIK-nya
class ParentWithStudents {
  final int id;
  final String nik;
  final String fullName;
  final List<Student> students;

  ParentWithStudents({
    required this.id,
    required this.nik,
    required this.fullName,
    required this.students,
  });

  factory ParentWithStudents.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['student'];
    final List<Student> studentList = [];
    if (rawStudents is List) {
      for (final item in rawStudents) {
        if (item is Map<String, dynamic>) {
          studentList.add(Student.fromJson(item));
        }
      }
    }

    final firstName = json['first_name']?.toString() ?? '';
    final lastName = json['last_name']?.toString() ?? '';
    final name = '$firstName $lastName'.trim();

    return ParentWithStudents(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      nik: json['nik']?.toString() ?? '',
      fullName: name.isNotEmpty ? name : 'Wali Santri',
      students: studentList,
    );
  }
}
