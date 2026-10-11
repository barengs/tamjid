import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/api/api_endpoints.dart';
import '../core/api/dio_client.dart';

enum RegistrationStatus { initial, submitting, success, error }

/// State mentah untuk Wizard PSB (multi-step form).
/// Field disimpan sebagai Map agar mudah dikirim sebagai multipart/form-data
/// ke `POST /api/main/registration`.
class RegistrationProvider extends ChangeNotifier {
  // Status pengiriman form
  RegistrationStatus _status = RegistrationStatus.initial;
  String? _errorMessage;
  String? _successMessage;

  RegistrationStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isSubmitting => _status == RegistrationStatus.submitting;

  // Data wali (step 1)
  final Map<String, dynamic> waliData = {
    'wali_nama_depan': '',
    'wali_nama_belakang': '',
    'wali_nik': '',
    'wali_kk': '',
    'wali_telepon': '',
    'wali_email': '',
    'wali_jenis_kelamin': 'laki-laki',
    'wali_sebagai': '',
    'wali_alamat_ktp': '',
    'wali_alamat_domisili': '',
  };

  // Data santri (step 2)
  final Map<String, dynamic> santriData = {
    'santri_nama_depan': '',
    'santri_nama_belakang': '',
    'santri_nisn': '',
    'santri_nik': '',
    'santri_jenis_kelamin': 'laki-laki',
    'santri_alamat': '',
    'santri_tempat_lahir': '',
    'santri_tanggal_lahir': '',
    'santri_telepon': '',
    'program_id': null,
  };

  // Riwayat pendidikan (step 3)
  final Map<String, dynamic> pendidikanData = {
    'pendidikan_sekolah_asal': '',
    'pendidikan_alamat_sekolah': '',
    'pendidikan_nomor_ijazah': '',
    'pendidikan_jenjang_sebelumnya': null,
    'madrasah_sekolah_asal': '',
    'madrasah_alamat_sekolah': '',
    'madrasah_nomor_ijazah': '',
    'madrasah_jenjang_sebelumnya': null,
  };

  // Dokumen (step 4) — disimpan sebagai MultipartFile saat submit
  final Map<String, dynamic> dokumenData = {
    'dokumen_foto_santri': null,
    'dokumen_ijazah': null,
    'dokumen_opsional': <dynamic>[],
  };

  // Reset state setelah sukses / gagal total
  void resetStatus() {
    _status = RegistrationStatus.initial;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  // Simpan data wali
  void saveWali(Map<String, dynamic> data) {
    waliData.addAll(data);
    notifyListeners();
  }

  // Simpan data santri
  void saveSantri(Map<String, dynamic> data) {
    santriData.addAll(data);
    notifyListeners();
  }

  // Simpan riwayat pendidikan
  void savePendidikan(Map<String, dynamic> data) {
    pendidikanData.addAll(data);
    notifyListeners();
  }

  // Simpan dokumen
  void saveDokumen(String key, dynamic value) {
    dokumenData[key] = value;
    notifyListeners();
  }

  /// Submit pendaftaran ke backend (multipart/form-data).
  Future<bool> submit() async {
    _status = RegistrationStatus.submitting;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      // Siapkan FormData
      final formDataMap = <String, dynamic>{};
      formDataMap.addAll(waliData);
      formDataMap.addAll(santriData);
      formDataMap.addAll(pendidikanData);
      // Bersihkan nilai kosong / null agar tidak trigger validasi
      formDataMap.removeWhere((_, v) => v == null || (v is String && v.isEmpty));

      final dio = DioClient().dio;
      final formData = FormData.fromMap(formDataMap);

      // Lampirkan file dokumen jika ada
      final foto = dokumenData['dokumen_foto_santri'];
      if (foto != null && foto is MultipartFile) {
        formData.files.add(MapEntry('dokumen_foto_santri', foto));
      }
      final ijazah = dokumenData['dokumen_ijazah'];
      if (ijazah != null && ijazah is MultipartFile) {
        formData.files.add(MapEntry('dokumen_ijazah', ijazah));
      }
      final opsional = dokumenData['dokumen_opsional'];
      if (opsional is List && opsional.isNotEmpty) {
        for (final file in opsional) {
          if (file is MultipartFile) {
            formData.files.add(MapEntry('dokumen_opsional[]', file));
          }
        }
      }

      final response = await dio.post(
        ApiEndpoints.smpRegistration,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _status = RegistrationStatus.success;
        _successMessage =
            response.data?['message'] ?? 'Pendaftaran berhasil dikirim!';
        notifyListeners();
        return true;
      } else {
        throw Exception(response.data?['message'] ?? 'Pendaftaran gagal.');
      }
    } on DioException catch (e) {
      _status = RegistrationStatus.error;
      _errorMessage = _parseDioError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _status = RegistrationStatus.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  String _parseDioError(DioException e) {
    if (e.response != null && e.response?.data != null) {
      final d = e.response!.data;
      if (d is Map) {
        if (d['message'] != null) return d['message'].toString();
        if (d['errors'] != null && d['errors'] is Map) {
          final errMap = d['errors'] as Map;
          final firstKey = errMap.keys.first;
          final val = errMap[firstKey];
          if (val is List && val.isNotEmpty) return val.first.toString();
          return val.toString();
        }
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
