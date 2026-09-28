import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/family_session.dart';
import '../services/location_service.dart';
import '../utils/app_routes.dart';

/// App-bar action that signs out and returns to login without leaving a
/// back-stack of dashboards behind.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Log out',
      icon: const Icon(Icons.logout_rounded),
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
