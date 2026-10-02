import 'package:flutter/material.dart';

/// Visual system matched to the family-monitor reference: airy blue canvas,
/// saturated feature tiles, and navy type.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF4B8BFF);
  static const Color primarySoft = Color(0xFF8BB4FF);

  static const Color peach = Color(0xFFFFE0C2);
  static const Color blush = Color(0xFFFFD6DE);
  static const Color sunshine = Color(0xFFF5C044);
  static const Color mint = Color(0xFF2ECF9A);
  static const Color sky = Color(0xFF5B9BFF);
  static const Color lavender = Color(0xFF7B6EFF);

  static const Color mintInk = Color(0xFF0F7A58);
  static const Color skyInk = Color(0xFF1E4F9A);
  static const Color sunshineInk = Color(0xFF8A5A00);
  static const Color lavenderInk = Color(0xFF3F338F);

  static const Color parentAccent = Color(0xFF4B8BFF);
  static const Color childAccent = Color(0xFF7B6EFF);

  static const Color tileBlue = Color(0xFF5B9BFF);
  static const Color tileOrange = Color(0xFFF5C044);
  static const Color tilePurple = Color(0xFF7B6EFF);
  static const Color tileGreen = Color(0xFF2ECF9A);

  static const Color success = Color(0xFF2ECF9A);
  static const Color warning = Color(0xFFF5C044);
  static const Color danger = Color(0xFFE0565B);
  static const Color info = Color(0xFF4B8BFF);

  static const Color cream = Color(0xFFEAF3FC);
  static const Color sand = Color(0xFFD7E6F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFE4EDF6);
  static const Color ink = Color(0xFF1C2B4A);
  static const Color inkSoft = Color(0xFF7A8699);

  static const Color creamDark = Color(0xFF121826);
  static const Color surfaceDark = Color(0xFF1C2433);
  static const Color outlineDark = Color(0xFF334056);
  static const Color inkDark = Color(0xFFF3F7FC);
  static const Color inkSoftDark = Color(0xFFB3BCC9);

  static const List<Color> categoryPalette = <Color>[
    tileBlue,
    tileOrange,
    tilePurple,
    tileGreen,
    peach,
    blush,
  ];

  static const List<Color> categoryInkPalette = <Color>[
    Color(0xFF1E4F9A),
    Color(0xFF8A5A00),
    Color(0xFF3F338F),
    Color(0xFF0F7A58),
    Color(0xFFB25A32),
    Color(0xFFB04A57),
  ];

  static Color categoryAt(int index) =>
      categoryPalette[index.abs() % categoryPalette.length];

  static Color categoryInkAt(int index) =>
      categoryInkPalette[index.abs() % categoryInkPalette.length];

  static Color avatarColor(String key) {
    const List<Color> colors = <Color>[
      tileBlue,
      tileOrange,
      tilePurple,
      tileGreen,
    ];
    return colors[key.hashCode.abs() % colors.length];
  }
}
