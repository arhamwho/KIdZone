import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_routes.dart';
import '../../widgets/kidzone_mark.dart';
import '../../widgets/soft_background.dart';

/// Branded launch screen.
///
/// After the entrance animation, the app checks Firebase Auth and the
/// Firestore user profile, then routes to login or the matching dashboard.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller
      ..addStatusListener(_onStatusChanged)
      ..forward();
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _continueFromSplash();
    }
  }

  Future<void> _continueFromSplash() async {
    if (!mounted) return;

    // Widget tests pump the app without calling main(), so Firebase may not
    // be initialized. Treat that as logged out.
    if (Firebase.apps.isEmpty) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    try {
      final UserModel? profile = await AuthService.instance.loadSignedInProfile();
      if (!mounted) return;
      if (profile != null) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.homeFor(profile.role),
        );
        return;
      }
    } catch (_) {
      if (!mounted) return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_onStatusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SoftBackground(
      showDecorations: false,
      quiet: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const KidZoneMark(size: 196),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Care, learn and play together',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
