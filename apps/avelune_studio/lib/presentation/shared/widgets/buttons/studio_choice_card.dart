import 'package:flutter/material.dart';
import '../../../theme/studio_tokens.dart';

class StudioChoiceCard extends StatelessWidget {
  const StudioChoiceCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.selected,
    required this.onPressed,
    this.preview,
  });
  final String title, description;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
          side: BorderSide(color: selected ? colors.primary : colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(StudioMetrics.panelPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preview != null) ...[preview!, const SizedBox(height: 12)],
                Row(
                  children: [
                    Icon(selected ? Icons.check_circle : icon, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
