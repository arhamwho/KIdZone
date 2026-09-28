import 'package:flutter/material.dart';

import '../widgets/illustration_scene.dart';

/// Content for a single onboarding page.
///
/// Keeping this as a model means the onboarding screen stays a dumb renderer
/// and new pages can be added from `data/onboarding_content.dart` alone.
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
    required this.iconColor,
    this.accents = const <IllustrationAccent>[],
  });

  final String title;
  final String message;
  final IconData icon;

  /// Pastel colour used for the medallion and the page background blob.
  final Color color;

  /// Stronger partner of [color], used for the central icon.
  final Color iconColor;
  final List<IllustrationAccent> accents;
}
