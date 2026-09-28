import 'package:cloud_firestore/cloud_firestore.dart';

/// A family owned by one parent.
class FamilyModel {
  const FamilyModel({
    required this.familyId,
    required this.parentId,
    required this.familyName,
    this.createdAt,
  });

  final String familyId;
  final String parentId;
  final String familyName;
  final DateTime? createdAt;

  factory FamilyModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return FamilyModel(
      familyId: data['familyId'] as String? ?? doc.id,
      parentId: data['parentId'] as String? ?? '',
      familyName: data['familyName'] as String? ?? 'Family',
      createdAt: _readDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap({required bool isCreate}) {
    return <String, dynamic>{
      'familyId': familyId,
      'parentId': parentId,
      'familyName': familyName,
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
