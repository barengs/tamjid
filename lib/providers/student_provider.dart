import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/dio_client.dart';
import '../models/santri.dart';

enum StudentStatus { initial, loading, loaded, empty, error }

/// Mengelola daftar santri milik wali dan santri aktif yang sedang dipilih.
///
/// Sumber data: `GET /api/main/parent/nik/{nik}/cek` — mengembalikan profil
/// parent beserta relasi `student` (hasMany, di-join via `parent_id = nik`).
class StudentProvider extends ChangeNotifier {
  StudentStatus _status = StudentStatus.initial;
  List<Student> _students = [];
  Student? _activeStudent;
  String? _errorMessage;

  StudentStatus get status => _status;
  List<Student> get students => _students;
  Student? get activeStudent => _activeStudent;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == StudentStatus.loading;
  bool get hasStudents => _students.isNotEmpty;

  /// Fetch daftar santri berdasarkan NIK wali
  Future<void> fetchStudentsByNik(String nik) async {
    if (nik.isEmpty) {
      _status = StudentStatus.empty;
      _students = [];
      _activeStudent = null;
      _errorMessage = 'NIK wali belum tersedia. Lengkapi profil Anda terlebih dahulu.';
      notifyListeners();
      return;
    }

    _status = StudentStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final dio = DioClient().dio;
      final url = ApiEndpoints.smpParentByNik.replaceAll('{nik}', nik);
      final response = await dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data;
        // Response backend: { status: 'success', data: { ..., student: [...] } }
        final dataNode = rawData is Map<String, dynamic> && rawData['data'] is Map<String, dynamic>
            ? rawData['data'] as Map<String, dynamic>
            : (rawData is Map<String, dynamic> ? rawData : null);

        if (dataNode == null) {
          _students = [];
          _activeStudent = null;
          _status = StudentStatus.empty;
          notifyListeners();
          return;
        }

        final parent = ParentWithStudents.fromJson(dataNode);
        _students = parent.students;

        if (_students.isEmpty) {
          _status = StudentStatus.empty;
          _activeStudent = null;
        } else {
          // Pertahankan santri aktif sebelumnya jika masih ada di daftar
          final previousActive = _activeStudent;
          if (previousActive != null) {
            _activeStudent = _students.firstWhere(
              (s) => s.id == previousActive.id,
              orElse: () => _students.first,
            );
          } else {
            // Default: santri aktif (status 'active'), fallback ke yang pertama
            final activeOnly = _students.where((s) => s.status.toLowerCase() == 'active').toList();
            _activeStudent = activeOnly.isNotEmpty ? activeOnly.first : _students.first;
          }
          _status = StudentStatus.loaded;
        }
        notifyListeners();
      } else {
        throw Exception(response.data?['message'] ?? 'Gagal memuat data santri.');
      }
    } on DioException catch (e) {
      _status = StudentStatus.error;
      _errorMessage = _parseDioError(e);
      notifyListeners();
    } catch (e) {
      _status = StudentStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Pindah santri aktif (untuk Family Switcher)
  void switchActiveStudent(Student student) {
    if (_activeStudent?.id == student.id) return;
    _activeStudent = student;
    notifyListeners();
  }

  /// Reset state (saat logout)
  void reset() {
    _status = StudentStatus.initial;
    _students = [];
    _activeStudent = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _parseDioError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final d = e.response!.data;
      if (d is Map) {
        if (d['message'] != null) return d['message'].toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Koneksi ke server timeout. Silakan periksa jaringan Anda.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Tidak dapat terhubung ke server pesantren.';
    }
    return e.message ?? 'Terjadi kesalahan pada jaringan.';
  }
}
