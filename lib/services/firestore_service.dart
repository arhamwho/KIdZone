import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/child_model.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';
import 'firestore_errors.dart';

/// Cloud Firestore access for profiles, families and children.
///
/// Passwords are never written. Real-time updates use snapshot streams.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  static final FirestoreService instance = FirestoreService();

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  CollectionReference<Map<String, dynamic>> get _families =>
      _db.collection('families');

  CollectionReference<Map<String, dynamic>> _children(String familyId) =>
      _families.doc(familyId).collection('children');

  Future<void> createUserProfile(UserModel user) async {
    try {
      await _users.doc(user.uid).set(user.toMap(isCreate: true));
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _users
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          if (!doc.exists) return null;
          return UserModel.fromFirestore(doc);
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Future<FamilyModel> createFamily({
    required String parentId,
    required String familyName,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc = _families.doc();
      final FamilyModel family = FamilyModel(
        familyId: doc.id,
        parentId: parentId,
        familyName: familyName,
      );
      await doc.set(family.toMap(isCreate: true));
      return family;
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<FamilyModel?> getFamily(String familyId) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await _families
          .doc(familyId)
          .get();
      if (!doc.exists) return null;
      return FamilyModel.fromFirestore(doc);
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Stream<FamilyModel?> watchFamily(String familyId) {
    return _families
        .doc(familyId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          if (!doc.exists) return null;
          return FamilyModel.fromFirestore(doc);
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  /// Writes `users/{uid}` and `families/{familyId}/children/{uid}`.
  /// Does not store a password.
  Future<ChildModel> addChild({
    required String familyId,
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      final ChildModel child = ChildModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        familyId: familyId,
      );
      final UserModel profile = UserModel(
        uid: uid,
        name: child.name,
        email: child.email,
        role: UserRole.child,
        familyId: familyId,
      );

      final WriteBatch batch = _db.batch();
      batch.set(_users.doc(uid), profile.toMap(isCreate: true));
      batch.set(_children(familyId).doc(uid), child.toMap(isCreate: true));
      await batch.commit();
      return child;
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<List<ChildModel>> getChildren(String familyId) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await _children(
        familyId,
      ).get();
      return _sortedChildren(snapshot.docs);
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Stream<List<ChildModel>> watchChildren(String familyId) {
    return _children(familyId)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              _sortedChildren(snapshot.docs),
        )
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  List<ChildModel> _sortedChildren(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final List<ChildModel> children = docs
        .map(ChildModel.fromFirestore)
        .toList();
    children.sort((ChildModel a, ChildModel b) {
      final DateTime aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });
    return children;
  }

  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? familyId,
    bool? locationSharingEnabled,
    int? dailyScreenLimitMinutes,
    bool touchLastActive = false,
  }) async {
    try {
      final Map<String, dynamic> patch = <String, dynamic>{};
      if (name != null) patch['name'] = name;
      if (familyId != null) patch['familyId'] = familyId;
      if (locationSharingEnabled != null) {
        patch['locationSharingEnabled'] = locationSharingEnabled;
      }
      if (dailyScreenLimitMinutes != null) {
        patch['dailyScreenLimitMinutes'] = dailyScreenLimitMinutes;
      }
      if (touchLastActive) {
        patch['lastActiveAt'] = FieldValue.serverTimestamp();
      }
      if (patch.isEmpty) return;
      await _users.doc(uid).update(patch);
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  CollectionReference<Map<String, dynamic>> activities(String familyId) =>
      _families.doc(familyId).collection('activities');

  CollectionReference<Map<String, dynamic>> locations(String familyId) =>
      _families.doc(familyId).collection('locations');

  CollectionReference<Map<String, dynamic>> screenTime(String familyId) =>
      _families.doc(familyId).collection('screenTime');

  CollectionReference<Map<String, dynamic>> gameProgress(String familyId) =>
      _families.doc(familyId).collection('gameProgress');

  CollectionReference<Map<String, dynamic>> points(String familyId) =>
      _families.doc(familyId).collection('points');

  CollectionReference<Map<String, dynamic>> wallets(String familyId) =>
      _families.doc(familyId).collection('wallets');

  CollectionReference<Map<String, dynamic>> walletTransactions({
    required String familyId,
    required String childId,
  }) => wallets(familyId).doc(childId).collection('transactions');

  CollectionReference<Map<String, dynamic>> messages(String familyId) =>
      _families.doc(familyId).collection('messages');

  CollectionReference<Map<String, dynamic>> reminders(String familyId) =>
      _families.doc(familyId).collection('reminders');
}
