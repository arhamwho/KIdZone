import 'package:flutter/material.dart';

/// KidZone's pastel palette.
///
/// The system pairs a deep terracotta for anything interactive or text-bearing
/// with soft peach, blush and cream for surfaces and decoration. That split
/// keeps the app warm and playful while still clearing WCAG AA contrast —
/// pastels are used for fills, never for text on light backgrounds.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------- Brand
  /// Primary interactive colour. White text on this clears 4.7:1.
  static const Color primary = Color(0xFFC44C39);

  /// Soft peach used for tinted fills, badges and illustration shapes.
  static const Color primarySoft = Color(0xFFF4A48F);

  // ------------------------------------------------------------- Pastels
  static const Color peach = Color(0xFFFBC4A8);
  static const Color blush = Color(0xFFF6B8BE);
  static const Color sunshine = Color(0xFFF3C969);
  static const Color mint = Color(0xFF7CC6AE);
  static const Color sky = Color(0xFF8CB6E8);
  static const Color lavender = Color(0xFFB7A8E0);

  // Darker partners of the pastels above, for icons and text that sit on top
  // of them. Pastels are never used for text on a light background.
  static const Color mintInk = Color(0xFF2F7A63);
  static const Color skyInk = Color(0xFF3B6FA8);
  static const Color sunshineInk = Color(0xFF96701A);
  static const Color lavenderInk = Color(0xFF6A5AA8);

  // --------------------------------------------------------- Role accents
  /// Parent side leans calm and informative.
  static const Color parentAccent = Color(0xFF4A7FC1);

  /// Child side uses the warm brand colour.
  static const Color childAccent = Color(0xFFC44C39);

  // -------------------------------------------------------------- Status
  static const Color success = Color(0xFF3F8F63);
  static const Color warning = Color(0xFFC9861E);
  static const Color danger = Color(0xFFC0453C);
  static const Color info = Color(0xFF4A7FC1);

  // ------------------------------------------------------ Neutrals (light)
  static const Color cream = Color(0xFFFFF8F2);
  static const Color sand = Color(0xFFFDEDE1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color outline = Color(0xFFF0DFD2);
  static const Color ink = Color(0xFF3B2B26);
  static const Color inkSoft = Color(0xFF7C6A62);

  // ------------------------------------------------------- Neutrals (dark)
  static const Color creamDark = Color(0xFF1E1A19);
  static const Color surfaceDark = Color(0xFF2A2422);
  static const Color outlineDark = Color(0xFF453B37);
  static const Color inkDark = Color(0xFFF4EAE4);
  static const Color inkSoftDark = Color(0xFFBCAAA2);

  /// Soft fills used to colour-code subjects, activity types and game tiles.
  static const List<Color> categoryPalette = <Color>[
    peach,
    blush,
    sunshine,
    mint,
    sky,
    lavender,
  ];

  /// Darker partners of [categoryPalette], safe to use for text and icons
  /// sitting on top of the matching pastel fill.
  static const List<Color> categoryInkPalette = <Color>[
    Color(0xFFB25A32),
    Color(0xFFB04A57),
    Color(0xFF96701A),
    Color(0xFF2F7A63),
    Color(0xFF3B6FA8),
    Color(0xFF6A5AA8),
  ];

  static Color categoryAt(int index) =>
      categoryPalette[index.abs() % categoryPalette.length];

  static Color categoryInkAt(int index) =>
      categoryInkPalette[index.abs() % categoryInkPalette.length];
}
