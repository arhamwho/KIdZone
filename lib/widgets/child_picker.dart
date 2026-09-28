import 'package:flutter/material.dart';

import '../models/child_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class ChildPicker extends StatelessWidget {
  const ChildPicker({
    super.key,
    required this.children,
    required this.selectedId,
    required this.onSelected,
  });

  final List<ChildModel> children;
  final String? selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final ChildModel child in children) ...<Widget>[
            ChoiceChip(
              selected: child.uid == selectedId,
              label: Text(child.name),
              selectedColor: AppColors.sky.withValues(alpha: 0.35),
              onSelected: (_) => onSelected(child.uid),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
