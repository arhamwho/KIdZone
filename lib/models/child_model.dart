import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_role.dart';

/// A child who belongs to a family. Passwords are never stored here.
class ChildModel {
  const ChildModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.familyId,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final String familyId;
  final DateTime? createdAt;

  UserRole get role => UserRole.child;

  factory ChildModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return ChildModel.fromMap(data, doc.id);
  }

  factory ChildModel.fromMap(Map<String, dynamic> data, String uid) {
    return ChildModel(
      uid: data['uid'] as String? ?? uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      familyId: data['familyId'] as String? ?? '',
      createdAt: _readDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap({required bool isCreate}) {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'role': UserRole.child.firestoreValue,
      'familyId': familyId,
      'createdAt': isCreate
          ? FieldValue.serverTimestamp()
          : (createdAt == null
                ? FieldValue.serverTimestamp()
                : Timestamp.fromDate(createdAt!)),
    };
  }
}

DateTime? _readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
