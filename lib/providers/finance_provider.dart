import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/api/api_endpoints.dart';
import '../core/api/dio_client.dart';
import '../models/finance.dart';

/// Provider untuk mengelola state data keuangan santri:
/// - Saldo rekening & akad syariah
/// - Tagihan & tunggakan SPP
/// - Mutasi perbankan santri
/// - Pengajuan & riwayat top-up dana
class FinanceProvider extends ChangeNotifier {
  final Dio _dio = DioClient().dio;

  bool _isLoadingAccount = false;
  bool _isLoadingBills = false;
  bool _isLoadingMovements = false;
  bool _isLoadingTopUps = false;
  bool _isLoadingPackages = false;
  bool _isLoadingAddons = false;
  bool _isSubmittingTopUp = false;

  AccountBalance? _currentAccount;
  final Map<String, AccountBalance?> _accountsByNis = {};
  final Map<int, AccountBalance?> _accountsByStudentId = {};

  BillSummary? _billSummary;
  List<AccountMovementItem> _movements = [];
  List<TopUpRequestItem> _topUpHistory = [];
  List<PaymentPackageBrief> _availablePackages = [];
  List<TransactionItemAddon> _availableAddons = [];

  String? _errorMessage;

  // Getters
  bool get isLoadingAccount => _isLoadingAccount;
  bool get isLoadingBills => _isLoadingBills;
  bool get isLoadingMovements => _isLoadingMovements;
  bool get isLoadingTopUps => _isLoadingTopUps;
  bool get isLoadingPackages => _isLoadingPackages;
  bool get isLoadingAddons => _isLoadingAddons;
  bool get isSubmittingTopUp => _isSubmittingTopUp;

  bool get isLoadingGeneral =>
      _isLoadingAccount || _isLoadingBills || _isLoadingMovements;

  AccountBalance? get currentAccount => _currentAccount;

  /// Mengambil data saldo untuk santri tertentu (berdasarkan NIS atau ID)
  /// Menghindari kebocoran data saldo santri lain saat beralih kartu.
  AccountBalance? getAccountFor({String? nis, int? studentId}) {
    if (nis != null && nis.isNotEmpty && _accountsByNis.containsKey(nis)) {
      return _accountsByNis[nis];
    }
    if (studentId != null && studentId > 0 && _accountsByStudentId.containsKey(studentId)) {
      return _accountsByStudentId[studentId];
    }
    if (_currentAccount != null) {
      if (nis != null && nis.isNotEmpty && _currentAccount!.accountNumber == nis) {
        return _currentAccount;
      }
    }
    return null;
  }
  BillSummary? get billSummary => _billSummary;
  List<AccountMovementItem> get movements => _movements;
  List<TopUpRequestItem> get topUpHistory => _topUpHistory;
  List<PaymentPackageBrief> get availablePackages => _availablePackages;
  List<TransactionItemAddon> get availableAddons => _availableAddons;
  String? get errorMessage => _errorMessage;

  /// Ambil seluruh data keuangan santri via endpoint proxy resmi smp-be
  /// Menggunakan token JWT smp-be wali untuk mengambil data rekening,
  /// riwayat transaksi, dan tagihan/tunggakan langsung dari bank-santri.
  Future<bool> fetchStudentFinanceProxy({required int studentId, required String nis}) async {
    if (studentId <= 0) return false;
    _isLoadingAccount = true;
    _isLoadingBills = true;
    _isLoadingMovements = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiEndpoints.smpStudentFinance.replaceAll('{id}', studentId.toString());
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final rawData = response.data['data'] as Map<String, dynamic>?;
        if (rawData != null) {
          // 1. Akun & Saldo
          if (rawData['account'] is Map<String, dynamic>) {
            final acc = AccountBalance.fromJson(
              rawData['account'] as Map<String, dynamic>,
            );
            _currentAccount = acc;
            if (nis.isNotEmpty) _accountsByNis[nis] = acc;
            _accountsByStudentId[studentId] = acc;
          } else {
            _currentAccount = null;
            if (nis.isNotEmpty) _accountsByNis[nis] = null;
            _accountsByStudentId[studentId] = null;
          }

          // 2. Tagihan & Tunggakan
          if (rawData['arrears'] is Map<String, dynamic>) {
            _billSummary = BillSummary.fromJson(
              rawData['arrears'] as Map<String, dynamic>,
            );
          }

          // 3. Transaksi / Mutasi
          if (rawData['transactions'] is List) {
            final txList = rawData['transactions'] as List;
            _movements = txList
                .map((item) =>
                    AccountMovementItem.fromJson(item as Map<String, dynamic>))
                .toList();
          }

          _isLoadingAccount = false;
          _isLoadingBills = false;
          _isLoadingMovements = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error fetchStudentFinanceProxy, falling back to direct endpoints: $e');
      _errorMessage = 'Gagal memuat keuangan: ${_extractErrorMessage(e)}';
    }

    _isLoadingAccount = false;
    _isLoadingBills = false;
    _isLoadingMovements = false;
    notifyListeners();

    // Fallback jika proxy belum tersedia / error
    if (nis.isNotEmpty) {
      await fetchAccount(nis);
      await fetchBills(nis);
      await fetchMovements(nis);
      return _currentAccount != null;
    }

    return false;
  }

  /// Ambil data akun & saldo santri berdasarkan NIS
  Future<bool> fetchAccount(String nis) async {
    if (nis.isEmpty) return false;
    _isLoadingAccount = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final url = ApiEndpoints.bankAccount.replaceAll('{nis}', nis);
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final acc = AccountBalance.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _currentAccount = acc;
        _accountsByNis[nis] = acc;
        _isLoadingAccount = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat saldo: ${_extractErrorMessage(e)}';
    }

    _isLoadingAccount = false;
    notifyListeners();
    return false;
  }

  /// Ambil ringkasan tagihan & tunggakan SPP berdasarkan NIS
  Future<bool> fetchBills(String nis) async {
    if (nis.isEmpty) return false;
    _isLoadingBills = true;
    notifyListeners();

    try {
      final url = ApiEndpoints.bankBills.replaceAll('{nis}', nis);
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        _billSummary = BillSummary.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        _isLoadingBills = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchBills: $e');
    }

    _isLoadingBills = false;
    notifyListeners();
    return false;
  }

  /// Ambil mutasi transaksi santri berdasarkan NIS
  Future<bool> fetchMovements(String nis) async {
    if (nis.isEmpty) return false;
    _isLoadingMovements = true;
    notifyListeners();

    try {
      final url = ApiEndpoints.bankAccountTransactions.replaceAll('{nis}', nis);
      final response = await _dio.get(url, queryParameters: {'per_page': 30});

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        final list = (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data is List ? data : []);

        _movements = list
            .map((item) =>
                AccountMovementItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoadingMovements = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchMovements: $e');
    }

    _isLoadingMovements = false;
    notifyListeners();
    return false;
  }

  /// Ambil riwayat pengajuan top-up berdasarkan NIS atau via proxy SMPT
  Future<bool> fetchTopUpHistory(String nis, {int? studentId}) async {
    if (nis.isEmpty && (studentId == null || studentId <= 0)) return false;
    _isLoadingTopUps = true;
    notifyListeners();

    try {
      final url = (studentId != null && studentId > 0)
          ? ApiEndpoints.smpStudentTopUpHistory.replaceAll('{id}', studentId.toString())
          : ApiEndpoints.bankTopUpByAccount.replaceAll('{nis}', nis);

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        final list = (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data is List ? data : []);

        _topUpHistory = list
            .map((item) =>
                TopUpRequestItem.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoadingTopUps = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchTopUpHistory: $e');
    }

    _isLoadingTopUps = false;
    notifyListeners();
    return false;
  }

  /// Ambil paket pembayaran aktif dari proxy SMPT atau bank-santri
  Future<bool> fetchAvailablePackages({int? studentId}) async {
    _isLoadingPackages = true;
    notifyListeners();

    try {
      final url = (studentId != null && studentId > 0)
          ? ApiEndpoints.smpStudentPackages.replaceAll('{id}', studentId.toString())
          : ApiEndpoints.bankPaymentPackages;

      final response = await _dio.get(
        url,
        queryParameters: {'is_active': true, 'per_page': 50},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        final list = (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data is List ? data : []);

        _availablePackages = list
            .map((item) =>
                PaymentPackageBrief.fromJson(item as Map<String, dynamic>))
            .toList();
        _isLoadingPackages = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchAvailablePackages: $e');
    }

    _isLoadingPackages = false;
    notifyListeners();
    return false;
  }

  /// Ambil item fasilitas add-on aktif dari proxy SMPT
  Future<bool> fetchAvailableAddons({int? studentId}) async {
    if (studentId == null || studentId <= 0) return false;
    _isLoadingAddons = true;
    notifyListeners();

    try {
      final url = ApiEndpoints.smpStudentAddons.replaceAll('{id}', studentId.toString());
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'];
        final list = (data is Map && data['data'] is List)
            ? data['data'] as List
            : (data is List ? data : []);

        _availableAddons = list
            .map((item) =>
                TransactionItemAddon.fromJson(item as Map<String, dynamic>))
            .where((item) => item.isActive)
            .toList();
        _isLoadingAddons = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error fetchAvailableAddons: $e');
    }

    _isLoadingAddons = false;
    notifyListeners();
    return false;
  }

  /// Kirim pengajuan top-up via transfer bank beserta upload bukti
  Future<({bool success, String message})> submitBankTransferTopUp({
    required int studentId,
    required String accountNumber,
    int? paymentPackageId,
    List<int>? addonItemIds,
    required double amount,
    required String filePath,
    String? notes,
  }) async {
    _isSubmittingTopUp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fileName = filePath.split('/').last;
      final mapData = <String, dynamic>{
        'account_number': accountNumber,
        'amount': amount.toInt(),
        'payment_proof': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      };

      if (paymentPackageId != null && paymentPackageId > 0) {
        mapData['payment_package_id'] = paymentPackageId;
      }

      if (addonItemIds != null && addonItemIds.isNotEmpty) {
        mapData['addon_item_ids'] = jsonEncode(addonItemIds);
      }

      if (notes != null && notes.trim().isNotEmpty) {
        mapData['notes'] = notes.trim();
      }

      final formData = FormData.fromMap(mapData);

      final url = (studentId > 0)
          ? ApiEndpoints.smpStudentSubmitTopUp.replaceAll('{id}', studentId.toString())
          : ApiEndpoints.bankTopUpBankTransfer;

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      _isSubmittingTopUp = false;
      notifyListeners();

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh riwayat top-up
        fetchTopUpHistory(accountNumber, studentId: studentId);
        return (
          success: true,
          message: response.data['message']?.toString() ??
              'Bukti transfer berhasil dikirim. Menunggu verifikasi admin.',
        );
      } else {
        return (
          success: false,
          message: response.data['message']?.toString() ?? 'Gagal mengirim pengajuan.',
        );
      }
    } catch (e) {
      _isSubmittingTopUp = false;
      final msg = _extractErrorMessage(e);
      _errorMessage = msg;
      notifyListeners();
      return (success: false, message: msg);
    }
  }

  /// Refresh seluruh data keuangan santri secara bersamaan
  Future<void> refreshAll(String nis, {int? studentId}) async {
    if (nis.isEmpty && (studentId == null || studentId <= 0)) return;

    // Segera sinkronkan _currentAccount ke data santri ini (jika sudah ada di cache)
    // atau reset ke null agar tidak menampilkan saldo santri sebelumnya saat swipe!
    if (nis.isNotEmpty && _accountsByNis.containsKey(nis)) {
      _currentAccount = _accountsByNis[nis];
    } else if (studentId != null && _accountsByStudentId.containsKey(studentId)) {
      _currentAccount = _accountsByStudentId[studentId];
    } else {
      _currentAccount = null;
    }
    _isLoadingAccount = true;
    notifyListeners();

    if (studentId != null && studentId > 0) {
      await Future.wait([
        fetchStudentFinanceProxy(studentId: studentId, nis: nis),
        fetchTopUpHistory(nis, studentId: studentId),
        fetchAvailablePackages(studentId: studentId),
        fetchAvailableAddons(studentId: studentId),
      ]);
    } else {
      await Future.wait([
        fetchAccount(nis),
        fetchBills(nis),
        fetchMovements(nis),
        fetchTopUpHistory(nis),
        if (_availablePackages.isEmpty) fetchAvailablePackages(),
      ]);
    }
  }

  /// Reset state ketika santri berganti atau logout
  void reset() {
    _currentAccount = null;
    _accountsByNis.clear();
    _accountsByStudentId.clear();
    _billSummary = null;
    _movements = [];
    _topUpHistory = [];
    _availableAddons = [];
    _errorMessage = null;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map) {
          if (data['message'] != null) return data['message'].toString();
          if (data['error'] != null) return data['error'].toString();
        }
      }
      return error.message ?? 'Terjadi kesalahan jaringan';
    }
    return error.toString();
  }
}
