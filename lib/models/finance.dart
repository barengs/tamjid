// Model keuangan santri (perbankan, tagihan, mutasi, dan top-up)
// Terhubung dengan backend bank-santri.

class AccountBalance {
  final String accountNumber;
  final String customerName;
  final int? customerId;
  final double balance;
  final String status;
  final String akadType;
  final String? cardNumber;
  final String? openDate;
  final double? dailyWithdrawalLimit;
  final String? productName;

  const AccountBalance({
    required this.accountNumber,
    required this.customerName,
    this.customerId,
    required this.balance,
    required this.status,
    required this.akadType,
    this.cardNumber,
    this.openDate,
    this.dailyWithdrawalLimit,
    this.productName,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;

    return AccountBalance(
      accountNumber: json['account_number']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerId: json['customer_id'] is num ? (json['customer_id'] as num).toInt() : null,
      balance: _toDouble(json['balance']),
      status: json['status']?.toString() ?? 'AKTIF',
      akadType: json['akad_type']?.toString() ?? 'wadiah',
      cardNumber: json['card_number']?.toString(),
      openDate: json['open_date']?.toString(),
      dailyWithdrawalLimit: json['daily_withdrawal_limit'] != null
          ? _toDouble(json['daily_withdrawal_limit'])
          : null,
      productName: product?['name']?.toString() ?? product?['product_name']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class BillItem {
  final int id;
  final String period;
  final double amount;
  final double paidAmount;
  final double remaining;
  final String? dueDate;
  final String status;
  final bool isOverdue;

  const BillItem({
    required this.id,
    required this.period,
    required this.amount,
    required this.paidAmount,
    required this.remaining,
    this.dueDate,
    required this.status,
    required this.isOverdue,
  });

  factory BillItem.fromJson(Map<String, dynamic> json) {
    final amt = AccountBalance._toDouble(json['amount']);
    final paid = AccountBalance._toDouble(json['paid_amount']);
    final rem = json['remaining'] != null
        ? AccountBalance._toDouble(json['remaining'])
        : (amt - paid);

    return BillItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      period: json['period']?.toString() ?? json['bill_period']?.toString() ?? '',
      amount: amt,
      paidAmount: paid,
      remaining: rem > 0 ? rem : 0.0,
      dueDate: json['due_date']?.toString(),
      status: json['status']?.toString().toLowerCase() ?? 'unpaid',
      isOverdue: json['is_overdue'] == true || json['status']?.toString().toLowerCase() == 'overdue',
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPartial => status == 'partial';
  bool get isUnpaid => status == 'unpaid';
}

class BillSummary {
  final String accountNumber;
  final bool hasArrears;
  final double totalArrears;
  final int overdueMonthsCount;
  final String? oldestOverduePeriod;
  final String? newestOverduePeriod;
  final double totalUnpaidAll;
  final List<BillItem> bills;

  const BillSummary({
    required this.accountNumber,
    required this.hasArrears,
    required this.totalArrears,
    required this.overdueMonthsCount,
    this.oldestOverduePeriod,
    this.newestOverduePeriod,
    required this.totalUnpaidAll,
    required this.bills,
  });

  factory BillSummary.fromJson(Map<String, dynamic> json) {
    final billsRaw = json['bills'] as List<dynamic>? ?? [];
    final billsList = billsRaw
        .map((b) => BillItem.fromJson(b as Map<String, dynamic>))
        .toList();

    return BillSummary(
      accountNumber: json['account_number']?.toString() ?? '',
      hasArrears: json['has_arrears'] == true,
      totalArrears: AccountBalance._toDouble(json['total_arrears']),
      overdueMonthsCount: json['overdue_months_count'] is num
          ? (json['overdue_months_count'] as num).toInt()
          : 0,
      oldestOverduePeriod: json['oldest_overdue_period']?.toString(),
      newestOverduePeriod: json['newest_overdue_period']?.toString(),
      totalUnpaidAll: AccountBalance._toDouble(json['total_unpaid_all']),
      bills: billsList,
    );
  }
}

class AccountMovementItem {
  final int id;
  final String accountNumber;
  final String? transactionId;
  final String type; // credit (masuk), debit (keluar)
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String? description;
  final String createdAt;

  const AccountMovementItem({
    required this.id,
    required this.accountNumber,
    this.transactionId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    this.description,
    required this.createdAt,
  });

  factory AccountMovementItem.fromJson(Map<String, dynamic> json) {
    // Di AccountMovement bank-santri:
    // amount, balance_before, balance_after
    // jika balance_after >= balance_before -> kredit (masuk), sebaliknya debit
    final before = AccountBalance._toDouble(json['balance_before']);
    final after = AccountBalance._toDouble(json['balance_after']);
    final inferredType = (after >= before) ? 'credit' : 'debit';

    return AccountMovementItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      accountNumber: json['account_number']?.toString() ?? '',
      transactionId: json['transaction_id']?.toString(),
      type: json['type']?.toString() ?? inferredType,
      amount: AccountBalance._toDouble(json['amount']),
      balanceBefore: before,
      balanceAfter: after,
      description: json['description']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  bool get isCredit => type.toLowerCase() == 'credit';
  bool get isDebit => type.toLowerCase() == 'debit';
}

class PaymentPackageItemDetail {
  final int id;
  final String itemName;
  final String category;
  final double amount;
  final bool isSaku;

  const PaymentPackageItemDetail({
    required this.id,
    required this.itemName,
    required this.category,
    required this.amount,
    required this.isSaku,
  });

  factory PaymentPackageItemDetail.fromJson(Map<String, dynamic> json) {
    return PaymentPackageItemDetail(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      itemName: json['item_name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'lainnya',
      amount: AccountBalance._toDouble(json['amount']),
      isSaku: json['is_saku'] == true || json['is_saku'] == 1,
    );
  }
}

class TransactionItemAddon {
  final int id;
  final String itemName;
  final double defaultAmount;
  final String? description;
  final bool isActive;

  const TransactionItemAddon({
    required this.id,
    required this.itemName,
    required this.defaultAmount,
    this.description,
    required this.isActive,
  });

  factory TransactionItemAddon.fromJson(Map<String, dynamic> json) {
    return TransactionItemAddon(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      itemName: json['item_name']?.toString() ?? '',
      defaultAmount: AccountBalance._toDouble(json['default_amount']),
      description: json['description']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }
}

class PaymentPackageBrief {
  final int id;
  final String packageCode;
  final String packageName;
  final String? description;
  final String? academicYear;
  final String? semester;
  final double totalAmount;
  final double sakuAmount;
  final bool isActive;
  final List<PaymentPackageItemDetail> items;

  const PaymentPackageBrief({
    required this.id,
    required this.packageCode,
    required this.packageName,
    this.description,
    this.academicYear,
    this.semester,
    required this.totalAmount,
    required this.sakuAmount,
    required this.isActive,
    this.items = const [],
  });

  factory PaymentPackageBrief.fromJson(Map<String, dynamic> json) {
    return PaymentPackageBrief(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      packageCode: json['package_code']?.toString() ?? '',
      packageName: json['package_name']?.toString() ?? '',
      description: json['description']?.toString(),
      academicYear: json['academic_year']?.toString(),
      semester: json['semester']?.toString(),
      totalAmount: AccountBalance._toDouble(json['total_amount']),
      sakuAmount: AccountBalance._toDouble(json['saku_amount']),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      items: json['items'] is List
          ? (json['items'] as List)
              .map((it) => PaymentPackageItemDetail.fromJson(it as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }
}

class TopUpRequestItem {
  final int id;
  final String accountNumber;
  final int? paymentPackageId;
  final String? packageName;
  final double amount;
  final String channel;
  final String status;
  final String? paymentRef;
  final String? paymentProof;
  final String? notes;
  final String createdAt;
  final String? verifiedAt;

  const TopUpRequestItem({
    required this.id,
    required this.accountNumber,
    this.paymentPackageId,
    this.packageName,
    required this.amount,
    required this.channel,
    required this.status,
    this.paymentRef,
    this.paymentProof,
    this.notes,
    required this.createdAt,
    this.verifiedAt,
  });

  factory TopUpRequestItem.fromJson(Map<String, dynamic> json) {
    final pkg = json['package'] as Map<String, dynamic>?;

    return TopUpRequestItem(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      accountNumber: json['account_number']?.toString() ?? '',
      paymentPackageId: json['payment_package_id'] is num
          ? (json['payment_package_id'] as num).toInt()
          : null,
      packageName: pkg?['package_name']?.toString(),
      amount: AccountBalance._toDouble(json['amount']),
      channel: json['channel']?.toString() ?? 'bank_transfer',
      status: json['status']?.toString().toLowerCase() ?? 'pending',
      paymentRef: json['payment_ref']?.toString(),
      paymentProof: json['payment_proof']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      verifiedAt: json['verified_at']?.toString(),
    );
  }

  bool get isWaitingVerification =>
      status == 'waiting_verification' || status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed' || status == 'rejected';
}
