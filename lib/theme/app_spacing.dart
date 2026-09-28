/// Shared spacing and corner-radius scale.
///
/// Every screen should use these constants instead of hard-coded numbers so
/// the layout rhythm stays consistent across the app.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double huge = 44;

  /// Default horizontal padding for page content. Generous, to give the
  /// layouts the spacious feel the design calls for.
  static const double pageHorizontal = 20;

  /// Phone-first content cap. Only takes effect on tablets and foldables so
  /// text never stretches into unreadable lines.
  static const double maxContentWidth = 720;

  /// Minimum height for tappable elements, per Material touch-target guidance.
  static const double minTapTarget = 48;
}

/// Corner radii. KidZone is deliberately very rounded: pill-shaped buttons
/// and generously curved cards.
class AppRadius {
  const AppRadius._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
  static const double xl = 32;
  static const double pill = 999;
}
