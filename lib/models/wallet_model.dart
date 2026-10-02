import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_codec.dart';

enum AllowanceFrequency { daily, weekly, monthly }

extension AllowanceFrequencyX on AllowanceFrequency {
  String get firestoreValue => name;

  String get label => switch (this) {
    AllowanceFrequency.daily => 'Daily',
    AllowanceFrequency.weekly => 'Weekly',
    AllowanceFrequency.monthly => 'Monthly',
  };

  static AllowanceFrequency fromFirestore(String? value) {
    return AllowanceFrequency.values.firstWhere(
      (AllowanceFrequency item) => item.name == value,
      orElse: () => AllowanceFrequency.weekly,
    );
  }
}

class WalletModel {
  const WalletModel({
    required this.childId,
    required this.balance,
    required this.allowanceAmount,
    required this.allowanceFrequency,
    this.lastAllowancePeriod,
    this.updatedAt,
  });

  final String childId;
  final int balance;
  final int allowanceAmount;
  final AllowanceFrequency allowanceFrequency;
  final String? lastAllowancePeriod;
  final DateTime? updatedAt;

  factory WalletModel.empty(String childId) {
    return WalletModel(
      childId: childId,
      balance: 0,
      allowanceAmount: 0,
      allowanceFrequency: AllowanceFrequency.weekly,
    );
  }

  factory WalletModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return WalletModel(
      childId: data['childId'] as String? ?? doc.id,
      balance: (data['balance'] as num?)?.toInt() ?? 0,
      allowanceAmount: (data['allowanceAmount'] as num?)?.toInt() ?? 0,
      allowanceFrequency: AllowanceFrequencyX.fromFirestore(
        data['allowanceFrequency'] as String?,
      ),
      lastAllowancePeriod: data['lastAllowancePeriod'] as String?,
      updatedAt: readDate(data['updatedAt']),
    );
  }

  String get nextAllowanceLabel {
    if (allowanceAmount <= 0) return 'No allowance set';
    return '${formatRupees(allowanceAmount)} · ${allowanceFrequency.label}';
  }
}

enum WalletTransactionType { pocketMoney, allowance, payment, adjustment }

extension WalletTransactionTypeX on WalletTransactionType {
  String get firestoreValue => switch (this) {
    WalletTransactionType.pocketMoney => 'pocket_money',
    WalletTransactionType.allowance => 'allowance',
    WalletTransactionType.payment => 'payment',
    WalletTransactionType.adjustment => 'adjustment',
  };

  String get label => switch (this) {
    WalletTransactionType.pocketMoney => 'Pocket Money',
    WalletTransactionType.allowance => 'Allowance',
    WalletTransactionType.payment => 'Payment',
    WalletTransactionType.adjustment => 'Adjustment',
  };

  static WalletTransactionType fromFirestore(String? value) {
    return switch (value) {
      'allowance' => WalletTransactionType.allowance,
      'payment' => WalletTransactionType.payment,
      'adjustment' => WalletTransactionType.adjustment,
      _ => WalletTransactionType.pocketMoney,
    };
  }
}

class WalletTransactionModel {
  const WalletTransactionModel({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.note,
    required this.createdBy,
    this.createdAt,
  });

  final String transactionId;
  final WalletTransactionType type;
  final int amount;
  final String note;
  final String createdBy;
  final DateTime? createdAt;

  factory WalletTransactionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return WalletTransactionModel(
      transactionId: data['transactionId'] as String? ?? doc.id,
      type: WalletTransactionTypeX.fromFirestore(data['type'] as String?),
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      note: data['note'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: readDate(data['createdAt']),
    );
  }
}
