import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_routes.dart';
import 'kid_card.dart';

class FamilyToolsCard extends StatelessWidget {
  const FamilyToolsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SectionHeader(title: 'Family'),
        const SizedBox(height: AppSpacing.md),
        KidCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            children: <Widget>[
              _Row(
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.tileGreen,
                title: 'Pocket Money',
                subtitle: 'Wallet & allowance',
                route: AppRoutes.pocketMoney,
              ),
              _Row(
                icon: Icons.chat_bubble_outline_rounded,
                color: AppColors.tileBlue,
                title: 'Messages',
                subtitle: 'Family chat',
                route: AppRoutes.familyMessages,
              ),
              _Row(
                icon: Icons.alarm_outlined,
                color: AppColors.tilePurple,
                title: 'Reminders',
                subtitle: 'Homework & sleep',
                route: AppRoutes.reminders,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: color),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).pushNamed(route),
    );
  }
}
