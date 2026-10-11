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
  bool _isSubmittingTopUp = false;

  AccountBalance? _currentAccount;
  BillSummary? _billSummary;
  List<AccountMovementItem> _movements = [];
  List<TopUpRequestItem> _topUpHistory = [];
  List<PaymentPackageBrief> _availablePackages = [];

  String? _errorMessage;

  // Getters
  bool get isLoadingAccount => _isLoadingAccount;
  bool get isLoadingBills => _isLoadingBills;
  bool get isLoadingMovements => _isLoadingMovements;
  bool get isLoadingTopUps => _isLoadingTopUps;
  bool get isLoadingPackages => _isLoadingPackages;
  bool get isSubmittingTopUp => _isSubmittingTopUp;

  bool get isLoadingGeneral =>
      _isLoadingAccount || _isLoadingBills || _isLoadingMovements;

  AccountBalance? get currentAccount => _currentAccount;
  BillSummary? get billSummary => _billSummary;
  List<AccountMovementItem> get movements => _movements;
  List<TopUpRequestItem> get topUpHistory => _topUpHistory;
  List<PaymentPackageBrief> get availablePackages => _availablePackages;
  String? get errorMessage => _errorMessage;

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
        _currentAccount = AccountBalance.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
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

  /// Ambil riwayat pengajuan top-up berdasarkan NIS
  Future<bool> fetchTopUpHistory(String nis) async {
    if (nis.isEmpty) return false;
    _isLoadingTopUps = true;
    notifyListeners();

    try {
      final url = ApiEndpoints.bankTopUpByAccount.replaceAll('{nis}', nis);
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

  /// Ambil paket pembayaran aktif dari bank-santri
  Future<bool> fetchAvailablePackages() async {
    _isLoadingPackages = true;
    notifyListeners();

    try {
      final response = await _dio.get(
        ApiEndpoints.bankPaymentPackages,
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

  /// Kirim pengajuan top-up via transfer bank beserta upload bukti
  Future<({bool success, String message})> submitBankTransferTopUp({
    required String accountNumber,
    required int paymentPackageId,
    required double amount,
    required String filePath,
    String? notes,
  }) async {
    _isSubmittingTopUp = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'account_number': accountNumber,
        'payment_package_id': paymentPackageId,
        'amount': amount.toInt(),
        'notes': notes ?? '',
        'payment_proof': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        ApiEndpoints.bankTopUpBankTransfer,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      _isSubmittingTopUp = false;
      notifyListeners();

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Refresh riwayat top-up
        fetchTopUpHistory(accountNumber);
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
  Future<void> refreshAll(String nis) async {
    if (nis.isEmpty) return;
    await Future.wait([
      fetchAccount(nis),
      fetchBills(nis),
      fetchMovements(nis),
      fetchTopUpHistory(nis),
      if (_availablePackages.isEmpty) fetchAvailablePackages(),
    ]);
  }

  /// Reset state ketika santri berganti atau logout
  void reset() {
    _currentAccount = null;
    _billSummary = null;
    _movements = [];
    _topUpHistory = [];
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
