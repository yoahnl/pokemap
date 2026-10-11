import 'package:flutter/material.dart';

import '../buttons/studio_tool.dart';
import 'studio_badge.dart';

class StudioFilterTag extends StatelessWidget {
  const StudioFilterTag({
    super.key,
    required this.label,
    required this.onRemove,
  });
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: StudioBadge(label)),
      const SizedBox(width: 4),
      StudioTool(
        label: 'Retirer le filtre $label',
        icon: Icons.close,
        onPressed: onRemove,
      ),
    ],
  );
}
