import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Builds the Material 3 themes used by KidZone.
///
/// The components stay standard Material 3 underneath; the theme is what gives
/// them the soft, rounded, storybook feel — pill buttons, deeply curved cards,
/// warm cream surfaces and a larger-than-default type scale.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
          primaryContainer: AppColors.sand,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.parentAccent,
          onSecondary: Colors.white,
          tertiary: AppColors.sunshine,
          onTertiary: AppColors.ink,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          surfaceContainerLowest: AppColors.surface,
          surfaceContainerLow: AppColors.cream,
          surfaceContainerHighest: AppColors.sand,
          onSurfaceVariant: AppColors.inkSoft,
          outlineVariant: AppColors.outline,
          error: AppColors.danger,
        );

    return _build(
      scheme: scheme,
      scaffoldBackground: AppColors.cream,
      textPrimary: AppColors.ink,
      textSecondary: AppColors.inkSoft,
    );
  }

  static ThemeData dark() {
    final ColorScheme scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: AppColors.primarySoft,
          onPrimary: AppColors.creamDark,
          surface: AppColors.surfaceDark,
          onSurface: AppColors.inkDark,
          surfaceContainerHighest: AppColors.outlineDark,
          onSurfaceVariant: AppColors.inkSoftDark,
          outlineVariant: AppColors.outlineDark,
          error: AppColors.danger,
        );

    return _build(
      scheme: scheme,
      scaffoldBackground: AppColors.creamDark,
      textPrimary: AppColors.inkDark,
      textSecondary: AppColors.inkSoftDark,
    );
  }

  static ThemeData _build({
    required ColorScheme scheme,
    required Color scaffoldBackground,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final ThemeData base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final TextTheme textTheme = _textTheme(
      base.textTheme,
      textPrimary,
      textSecondary,
    );

    final RoundedRectangleBorder pillShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: scheme.brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg + 2,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        labelStyle: textTheme.bodyMedium?.copyWith(color: textSecondary),
        border: _inputBorder(scheme.outlineVariant),
        enabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme.primary, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 56),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          textStyle: textTheme.labelLarge,
          shape: pillShape,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 56),
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: textTheme.labelLarge,
          shape: pillShape,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 56),
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant, width: 1.5),
          textStyle: textTheme.labelLarge,
          shape: pillShape,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSpacing.minTapTarget),
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
          shape: pillShape,
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(
            AppSpacing.minTapTarget,
            AppSpacing.minTapTarget,
          ),
          foregroundColor: textPrimary,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide.none,
        labelStyle: textTheme.labelMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        shape: pillShape,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        indicatorShape: const CircleBorder(),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelMedium,
        ),
      ),

      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.14),
        selectedLabelTextStyle: textTheme.labelMedium,
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: textSecondary,
        ),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: textSecondary,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 12,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: AppSpacing.xl,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1.5}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  /// Friendly type scale: bigger than the Material default, heavier headings
  /// and relaxed line height so young readers can follow the text easily.
  static TextTheme _textTheme(
    TextTheme base,
    Color primary,
    Color secondary,
  ) {
    return base
        .apply(bodyColor: primary, displayColor: primary)
        .copyWith(
          headlineLarge: base.headlineLarge?.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.2,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            fontSize: 29,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.22,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.25,
          ),
          titleLarge: base.titleLarge?.copyWith(
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
          titleMedium: base.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          titleSmall: base.titleSmall?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: base.bodyLarge?.copyWith(fontSize: 17, height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(fontSize: 15.5, height: 1.5),
          bodySmall: base.bodySmall?.copyWith(
            fontSize: 14,
            color: secondary,
            height: 1.45,
          ),
          labelLarge: base.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
          labelMedium: base.labelMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        );
  }
}
