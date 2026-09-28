import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/onboarding_content.dart';
import '../../models/onboarding_page_data.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_routes.dart';
import '../../utils/responsive.dart';
import '../../widgets/illustration_scene.dart';
import '../../widgets/page_dots.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_background.dart';

/// Three-page introduction shown once before sign-in.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  bool get _isLastPage => _index == onboardingPages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _next() {
    if (_isLastPage) {
      _goToLogin();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OnboardingPageData current = onboardingPages[_index];

    return SoftBackground(
      tint: current.color,
      showDecorations: false,
      quiet: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ResponsiveContainer(
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: _isLastPage
                      ? const SizedBox(height: AppSpacing.minTapTarget)
                      : TextButton(
                          onPressed: _goToLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                            textStyle: theme.textTheme.labelMedium,
                            minimumSize: const Size(
                              AppSpacing.minTapTarget,
                              AppSpacing.minTapTarget,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                          child: const Text('Skip'),
                        ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingPages.length,
                    onPageChanged: (int i) => setState(() => _index = i),
                    itemBuilder: (BuildContext context, int i) =>
                        _OnboardingPage(data: onboardingPages[i]),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PageDots(count: onboardingPages.length, activeIndex: _index),
                const SizedBox(height: AppSpacing.xl),
                PrimaryButton(
                  label: _isLastPage ? 'Get Started' : 'Next',
                  icon: Icons.arrow_forward_rounded,
                  onPressed: _next,
                  expand: true,
                  compact: true,
                ),
                if (_index == 0)
                  const SizedBox(height: AppSpacing.xl)
                else ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  SecondaryButton(
                    label: 'Back',
                    icon: Icons.arrow_back_rounded,
                    onPressed: _back,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double artSize = math.min(constraints.maxWidth * 0.72, 236.0);

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                IllustrationScene(
                  key: ValueKey<String>(data.title),
                  icon: data.icon,
                  color: data.color,
                  iconColor: data.iconColor,
                  accents: data.accents,
                  accentScale: 0.16,
                  size: artSize,
                  animate: false,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(height: 1.25),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    data.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkSoft,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
