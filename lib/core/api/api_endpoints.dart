/// Konfigurasi URL backend untuk aplikasi mobile Tamjid.
/// - smp-be (akademik, kesiswaan, kamtib, perizinan, pendaftaran)
/// - bank-santri (keuangan, tabungan, tagihan, top-up)
class ApiEndpoints {
  // --- smp-be (Port 8000) ---
  static const String smpBase = 'https://api.tamjid.or.id';

  // Auth
  static const String smpLogin = '$smpBase/api/auth/login';
  static const String smpRegister = '$smpBase/api/auth/register';
  static const String smpProfile = '$smpBase/api/auth/profile';
  static const String smpRefresh = '$smpBase/api/auth/refresh';
  static const String smpLogout = '$smpBase/api/auth/logout';
  static const String smpForgotPassword = '$smpBase/api/auth/forgot-password';

  // Profil & Santri
  static const String smpParentByNik = '$smpBase/api/main/parent/nik/{nik}/cek';
  static const String smpStudentDetail = '$smpBase/api/main/student/{id}';
  static const String smpUpdateParentPhoto =
      '$smpBase/api/main/parent/{id}/update-photo';

  // Pendaftaran Santri Baru (PSB)
  static const String smpRegistration = '$smpBase/api/main/registration';
  static const String smpRegistrationList = '$smpBase/api/main/registration';

  // Kedisiplinan & Kesantrian
  static const String smpStudentViolations =
      '$smpBase/api/main/student-violation/student/{id}';
  static const String smpStudentLeaves =
      '$smpBase/api/main/student-leave/student/{id}/report';
  static const String smpLeaveTypes =
      '$smpBase/api/main/leave-type';
  static const String smpCreateLeave =
      '$smpBase/api/main/student-leave';
  static const String smpPresence =
      '$smpBase/api/main/presence';

  // --- bank-santri (Port 8001) ---
  static const String bankBase = 'https://bank.tamjid.or.id';

  // Rekening & Saldo
  static const String bankAccount = '$bankBase/api/main/account/{nis}';
  static const String bankAccountTransactions =
      '$bankBase/api/main/account/{nis}/transactions';

  // Tagihan
  static const String bankBills = '$bankBase/api/main/bills/account/{nis}';

  // Top-Up
  static const String bankTopUpBankTransfer =
      '$bankBase/api/main/top-up/bank-transfer';
  static const String bankTopUpByAccount =
      '$bankBase/api/main/top-up/account/{nis}';
  static const String bankPaymentPackages =
      '$bankBase/api/master/payment-package';
}
