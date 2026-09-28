import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum ActivityType {
  homework,
  exercise,
  meal,
  sleep,
  learning,
  other;

  String get label => switch (this) {
    ActivityType.homework => 'Homework',
    ActivityType.exercise => 'Exercise',
    ActivityType.meal => 'Meal',
    ActivityType.sleep => 'Sleep',
    ActivityType.learning => 'Learning',
    ActivityType.other => 'Other',
  };

  IconData get icon => switch (this) {
    ActivityType.homework => Icons.menu_book_outlined,
    ActivityType.exercise => Icons.directions_run_rounded,
    ActivityType.meal => Icons.restaurant_outlined,
    ActivityType.sleep => Icons.bedtime_outlined,
    ActivityType.learning => Icons.extension_outlined,
    ActivityType.other => Icons.flag_outlined,
  };

  Color get tint => switch (this) {
    ActivityType.homework => AppColors.sky,
    ActivityType.exercise => AppColors.mint,
    ActivityType.meal => AppColors.sunshine,
    ActivityType.sleep => AppColors.lavender,
    ActivityType.learning => AppColors.peach,
    ActivityType.other => AppColors.blush,
  };

  Color get ink => switch (this) {
    ActivityType.homework => AppColors.skyInk,
    ActivityType.exercise => AppColors.mintInk,
    ActivityType.meal => AppColors.sunshineInk,
    ActivityType.sleep => AppColors.lavenderInk,
    ActivityType.learning => AppColors.categoryInkPalette[0],
    ActivityType.other => AppColors.categoryInkPalette[1],
  };

  String get firestoreValue => name;

  static ActivityType fromFirestore(String? value) {
    return ActivityType.values.firstWhere(
      (ActivityType type) => type.name == value,
      orElse: () => ActivityType.other,
    );
  }
}
