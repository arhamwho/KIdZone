import 'package:flutter/material.dart';

import '../models/child_model.dart';
import '../theme/app_spacing.dart';
import 'feature_tile.dart';

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
    if (children.length < 2) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (final ChildModel child in children) ...<Widget>[
            InkWell(
              onTap: () => onSelected(child.uid),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Column(
                  children: <Widget>[
                    PersonAvatar(
                      name: child.name,
                      size: PersonAvatar.chip,
                      selected: child.uid == selectedId,
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      child.name.split(RegExp(r'\s+')).first,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
