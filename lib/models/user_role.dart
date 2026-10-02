import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The two roles the app supports. The chosen role decides which dashboard
/// and navigation tree the user lands in.
enum UserRole {
  parent,
  child;

  String get label => switch (this) {
    UserRole.parent => 'Parent',
    UserRole.child => 'Child',
  };

  String get description => switch (this) {
    UserRole.parent => 'Plan activities, track progress and set healthy limits.',
    UserRole.child => 'See today\'s plan, play learning games and earn points.',
  };

  IconData get icon => switch (this) {
    UserRole.parent => Icons.shield_moon_outlined,
    UserRole.child => Icons.child_care_outlined,
  };

  /// Strong colour for icons and text belonging to this role.
  Color get accent => switch (this) {
    UserRole.parent => AppColors.parentAccent,
    UserRole.child => AppColors.childAccent,
  };

  /// Pastel partner of [accent], used for fills, blobs and illustrations.
  Color get tint => switch (this) {
    UserRole.parent => AppColors.sky,
    UserRole.child => AppColors.mint,
  };

  /// Value stored in Firestore (`parent` / `child`).
  String get firestoreValue => name;

  static UserRole fromFirestore(String? value) {
    if (value == UserRole.child.firestoreValue) return UserRole.child;
    return UserRole.parent;
  }
}
