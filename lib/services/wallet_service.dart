import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/wallet_model.dart';
import '../utils/firestore_codec.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';

class WalletService {
  WalletService({FirestoreService? firestore})
    : _db = firestore ?? FirestoreService.instance;

  static final WalletService instance = WalletService();

  final FirestoreService _db;
  final Set<String> _inFlight = <String>{};

  Stream<WalletModel> watchWallet({
    required String familyId,
    required String childId,
  }) {
    return _db
        .wallets(familyId)
        .doc(childId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          if (!doc.exists) return WalletModel.empty(childId);
          return WalletModel.fromFirestore(doc);
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Stream<List<WalletTransactionModel>> watchTransactions({
    required String familyId,
    required String childId,
  }) {
    return _db
        .walletTransactions(familyId: familyId, childId: childId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<WalletTransactionModel> items = snapshot.docs
              .map(WalletTransactionModel.fromFirestore)
              .toList();
          items.sort((WalletTransactionModel a, WalletTransactionModel b) {
            final DateTime left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final DateTime right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
          return items;
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Future<void> ensureWallet({
    required String familyId,
    required String childId,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> ref = _db
          .wallets(familyId)
          .doc(childId);
      await FirebaseFirestore.instance.runTransaction((Transaction tx) async {
        final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
        if (snap.exists) return;
        tx.set(ref, <String, dynamic>{
          'childId': childId,
          'balance': 0,
          'allowanceAmount': 0,
          'allowanceFrequency': AllowanceFrequency.weekly.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> sendMoney({
    required String familyId,
    required String childId,
    required String parentId,
    required int amount,
    required String note,
    WalletTransactionType type = WalletTransactionType.pocketMoney,
  }) async {
    if (amount <= 0) {
      throw const FirestoreException('Enter an amount greater than zero.');
    }
    await _credit(
      familyId: familyId,
      childId: childId,
      parentId: parentId,
      amount: amount,
      type: type,
      note: note.trim(),
    );
  }

  Future<void> setAllowance({
    required String familyId,
    required String childId,
    required String parentId,
    required int amount,
    required AllowanceFrequency frequency,
  }) async {
    if (amount < 0) {
      throw const FirestoreException('Allowance cannot be negative.');
    }
    try {
      await ensureWallet(familyId: familyId, childId: childId);
      await _db.wallets(familyId).doc(childId).set(
        <String, dynamic>{
          'childId': childId,
          'allowanceAmount': amount,
          'allowanceFrequency': frequency.firestoreValue,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await applyDueAllowance(
        familyId: familyId,
        childId: childId,
        parentId: parentId,
      );
    } catch (error) {
      if (error is FirestoreException) rethrow;
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> applyDueAllowance({
    required String familyId,
    required String childId,
    required String parentId,
  }) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> snap = await _db
          .wallets(familyId)
          .doc(childId)
          .get();
      if (!snap.exists) return;
      final WalletModel wallet = WalletModel.fromFirestore(snap);
      if (wallet.allowanceAmount <= 0) return;
      final String period = periodKey(wallet.allowanceFrequency);
      if (wallet.lastAllowancePeriod == period) return;
      await _credit(
        familyId: familyId,
        childId: childId,
        parentId: parentId,
        amount: wallet.allowanceAmount,
        type: WalletTransactionType.allowance,
        note: '${wallet.allowanceFrequency.label} allowance',
        transactionId: 'allowance_$period',
        lastAllowancePeriod: period,
      );
    } catch (error) {
      if (error is FirestoreException) rethrow;
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> _credit({
    required String familyId,
    required String childId,
    required String parentId,
    required int amount,
    required WalletTransactionType type,
    required String note,
    String? transactionId,
    String? lastAllowancePeriod,
  }) async {
    final DocumentReference<Map<String, dynamic>> walletRef = _db
        .wallets(familyId)
        .doc(childId);
    final String id =
        transactionId ??
        _db.walletTransactions(familyId: familyId, childId: childId).doc().id;
    if (!_inFlight.add('$familyId/$childId/$id')) return;
    try {
      await FirebaseFirestore.instance.runTransaction((Transaction tx) async {
        final DocumentReference<Map<String, dynamic>> txRef = walletRef
            .collection('transactions')
            .doc(id);
        final DocumentSnapshot<Map<String, dynamic>> existing = await tx.get(
          txRef,
        );
        if (existing.exists) return;
        final DocumentSnapshot<Map<String, dynamic>> walletSnap = await tx.get(
          walletRef,
        );
        final Map<String, dynamic> data =
            walletSnap.data() ?? <String, dynamic>{};
        final int balance = (data['balance'] as num?)?.toInt() ?? 0;
        final int next = balance + amount;
        if (next < 0) {
          throw const FirestoreException('Balance cannot go below zero.');
        }
        tx.set(walletRef, <String, dynamic>{
          'childId': childId,
          'balance': next,
          'allowanceAmount':
              (data['allowanceAmount'] as num?)?.toInt() ?? 0,
          'allowanceFrequency':
              data['allowanceFrequency'] as String? ??
              AllowanceFrequency.weekly.firestoreValue,
          'lastAllowancePeriod': ?lastAllowancePeriod,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        tx.set(txRef, <String, dynamic>{
          'transactionId': id,
          'type': type.firestoreValue,
          'amount': amount,
          'note': note,
          'createdBy': parentId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (error) {
      if (error is FirestoreException) rethrow;
      throw FirestoreException(friendlyFirestoreMessage(error));
    } finally {
      _inFlight.remove('$familyId/$childId/$id');
    }
  }

  static String periodKey(AllowanceFrequency frequency, [DateTime? now]) {
    final DateTime date = now ?? DateTime.now();
    switch (frequency) {
      case AllowanceFrequency.daily:
        return dateKey(date);
      case AllowanceFrequency.monthly:
        return '${date.year}-${date.month.toString().padLeft(2, '0')}';
      case AllowanceFrequency.weekly:
        final DateTime monday = date.subtract(
          Duration(days: date.weekday - 1),
        );
        return 'w-${dateKey(monday)}';
    }
  }
}
