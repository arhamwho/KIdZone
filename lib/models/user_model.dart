import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_codec.dart';
import 'user_role.dart';

/// Signed-in KidZone user.
///
/// Passwords are never stored here. Firebase Authentication is the only
/// place credentials live.
class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.familyId,
    this.createdAt,
    this.locationSharingEnabled = false,
    this.dailyScreenLimitMinutes = 120,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? familyId;
  final DateTime? createdAt;
  final bool locationSharingEnabled;
  final int dailyScreenLimitMinutes;

  UserModel copyWith({
    String? name,
    UserRole? role,
    String? familyId,
    DateTime? createdAt,
    bool? locationSharingEnabled,
    int? dailyScreenLimitMinutes,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      createdAt: createdAt ?? this.createdAt,
      locationSharingEnabled:
          locationSharingEnabled ?? this.locationSharingEnabled,
      dailyScreenLimitMinutes:
          dailyScreenLimitMinutes ?? this.dailyScreenLimitMinutes,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return UserModel.fromMap(data, doc.id);
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: data['uid'] as String? ?? uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromFirestore(data['role'] as String?),
      familyId: data['familyId'] as String?,
      createdAt: readDate(data['createdAt']),
      locationSharingEnabled: data['locationSharingEnabled'] as bool? ?? false,
      dailyScreenLimitMinutes:
          (data['dailyScreenLimitMinutes'] as num?)?.toInt() ?? 120,
    );
  }

  Map<String, dynamic> toMap({required bool isCreate}) {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.firestoreValue,
      'familyId': familyId,
      'locationSharingEnabled': locationSharingEnabled,
      'dailyScreenLimitMinutes': dailyScreenLimitMinutes,
      'createdAt': writeDate(isCreate: isCreate, existing: createdAt),
    };
  }
}
