import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/family_session.dart';
import '../services/location_service.dart';
import '../utils/app_routes.dart';

/// Shared 40×40 white circle used for logout and back so they line up.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  static const double size = 40;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x14082A4D),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(
          width: size,
          height: size,
        ),
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, color: AppColors.ink, size: 18),
      ),
    );
  }
}

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      tooltip: 'Log out',
      icon: Icons.logout_rounded,
      onPressed: () async {
        await LocationService.instance.stopSharing();
        FamilySession.instance.clear();
        await AuthService.instance.logout();
        if (!context.mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (Route<dynamic> route) => false,
        );
      },
    );
  }
}

class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleIconButton(
      tooltip: 'Back',
      icon: Icons.arrow_back_ios_new_rounded,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
