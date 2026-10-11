import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_endpoints.dart';
import '../core/api/dio_client.dart';
import '../models/kesantrian.dart';

/// Provider untuk mengelola state data kesantrian & akademik santri:
/// - Riwayat pelanggaran / kedisiplinan (Kamtib)
/// - Riwayat & pengajuan izin santri (Surat Izin format hijriah)
/// - Tipe izin yang tersedia
/// - Riwayat presensi (kehadiran)
/// - Info asrama & kamar santri
class KesantrianProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  bool _isLoadingViolations = false;
  bool _isLoadingLeaves = false;
  bool _isLoadingLeaveTypes = false;
  bool _isLoadingPresence = false;
  bool _isSubmittingLeave = false;

  ViolationReportSummary? _violationReport;
  LeaveReportSummary? _leaveReport;
  List<LeaveTypeItem> _leaveTypes = [];
  List<StudentPresenceItem> _presenceList = [];
  HostelRoomInfo? _hostelInfo;

  String? _errorMessage;

  // Getters
  bool get isLoadingViolations => _isLoadingViolations;
  bool get isLoadingLeaves => _isLoadingLeaves;
  bool get isLoadingLeaveTypes => _isLoadingLeaveTypes;
  bool get isLoadingPresence => _isLoadingPresence;
  bool get isSubmittingLeave => _isSubmittingLeave;

  ViolationReportSummary? get violationReport => _violationReport;
  LeaveReportSummary? get leaveReport => _leaveReport;
  List<LeaveTypeItem> get leaveTypes => _leaveTypes;
  List<StudentPresenceItem> get presenceList => _presenceList;
  HostelRoomInfo? get hostelInfo => _hostelInfo;
  String? get errorMessage => _errorMessage;

  /// Ambil laporan pelanggaran santri berdasarkan student ID smpt
  Future<bool> fetchViolations(int studentId) async {
    if (studentId <= 0) return false;
    _isLoadingViolations = true;
    notifyListeners();

    try {
      final url =
          ApiEndpoints.smpStudentViolations.replaceAll('{id}', studentId.toString());
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        _violationReport = ViolationReportSummary.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _isLoadingViolations = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchViolations: $e');
    }

    _isLoadingViolations = false;
    notifyListeners();
    return false;
  }

  /// Ambil riwayat izin santri berdasarkan student ID smpt
  Future<bool> fetchLeaves(int studentId) async {
    if (studentId <= 0) return false;
    _isLoadingLeaves = true;
    notifyListeners();

    try {
      final url =
          ApiEndpoints.smpStudentLeaves.replaceAll('{id}', studentId.toString());
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        _leaveReport = LeaveReportSummary.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _isLoadingLeaves = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchLeaves: $e');
    }

    _isLoadingLeaves = false;
    notifyListeners();
    return false;
  }

  /// Ambil daftar tipe izin yang tersedia
  Future<bool> fetchLeaveTypes() async {
    if (_leaveTypes.isNotEmpty) return true;
    _isLoadingLeaveTypes = true;
    notifyListeners();

    try {
      final response = await _dio.get(ApiEndpoints.smpLeaveTypes);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final list = (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data is List ? data : (response.data is List ? response.data as List : []));

        _leaveTypes = list
            .map((item) => LeaveTypeItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoadingLeaveTypes = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchLeaveTypes: $e');
    }

    _isLoadingLeaveTypes = false;
    notifyListeners();
    return false;
  }

  /// Kirim pengajuan izin baru untuk santri
  Future<({bool success, String message})> submitLeaveRequest({
    required int studentId,
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? destination,
    String? contactPerson,
    String? contactPhone,
    String? notes,
  }) async {
    _isSubmittingLeave = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'student_id': studentId,
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      };
      if (destination != null && destination.isNotEmpty) payload['destination'] = destination;
      if (contactPerson != null && contactPerson.isNotEmpty) payload['contact_person'] = contactPerson;
      if (contactPhone != null && contactPhone.isNotEmpty) payload['contact_phone'] = contactPhone;
      if (notes != null && notes.isNotEmpty) payload['notes'] = notes;

      final response = await _dio.post(
        ApiEndpoints.smpCreateLeave,
        data: payload,
      );

      _isSubmittingLeave = false;

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh riwayat izin setelah submit
        fetchLeaves(studentId);
        return (
          success: true,
          message: response.data['message']?.toString() ??
              'Pengajuan izin berhasil dikirim. Menunggu persetujuan pembina.',
        );
      } else {
        final msg = response.data['message']?.toString() ?? 'Gagal mengirim pengajuan izin.';
        _errorMessage = msg;
        notifyListeners();
        return (success: false, message: msg);
      }
    } catch (e) {
      _isSubmittingLeave = false;
      final msg = _extractErrorMessage(e);
      _errorMessage = msg;
      notifyListeners();
      return (success: false, message: msg);
    }
  }

  /// Ambil riwayat presensi santri berdasarkan student ID smpt
  Future<bool> fetchPresences(int studentId) async {
    if (studentId <= 0) return false;
    _isLoadingPresence = true;
    notifyListeners();

    try {
      final response = await _dio.get(
        ApiEndpoints.smpPresence,
        queryParameters: {'student_id': studentId, 'per_page': 30},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'];
        final list = (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data is List ? data : []);

        _presenceList = list
            .map((item) =>
                StudentPresenceItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoadingPresence = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchPresences: $e');
    }

    _isLoadingPresence = false;
    notifyListeners();
    return false;
  }

  /// Ambil detail info asrama & kamar santri dari endpoint student detail
  Future<bool> fetchHostelInfo(int studentId) async {
    if (studentId <= 0) return false;

    try {
      final url =
          ApiEndpoints.smpStudentDetail.replaceAll('{id}', studentId.toString());
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data != null) {
          _hostelInfo = HostelRoomInfo.fromJson(data);
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error fetchHostelInfo: $e');
    }

    return false;
  }

  /// Refresh seluruh data kesantrian santri secara bersamaan
  Future<void> refreshAll(int studentId) async {
    if (studentId <= 0) return;
    await Future.wait([
      fetchViolations(studentId),
      fetchLeaves(studentId),
      fetchPresences(studentId),
      fetchHostelInfo(studentId),
      if (_leaveTypes.isEmpty) fetchLeaveTypes(),
    ]);
  }

  /// Reset state ketika santri berganti atau logout
  void reset() {
    _violationReport = null;
    _leaveReport = null;
    _leaveTypes = [];
    _presenceList = [];
    _hostelInfo = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        if (data['message'] != null) return data['message'].toString();
        if (data['error'] != null) return data['error'].toString();
        // Ambil error validasi pertama jika ada
        if (data['errors'] is Map) {
          final errors = data['errors'] as Map;
          for (final entry in errors.entries) {
            final val = entry.value;
            if (val is List && val.isNotEmpty) {
              return '${entry.key}: ${val.first}';
            }
          }
        }
      }
      return error.message ?? 'Terjadi kesalahan jaringan';
    }
    return error.toString();
  }
}
