import 'package:flutter/material.dart';

class StudioPaletteCard extends StatelessWidget {
  const StudioPaletteCard({
    super.key,
    required this.name,
    required this.preview,
    required this.selected,
    required this.onTap,
    this.maxNameLines = 1,
  });
  final String name;
  final Widget preview;
  final bool selected;
  final VoidCallback onTap;
  final int maxNameLines;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: name,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Semantics(
            selected: selected,
            button: true,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  Expanded(child: Center(child: preview)),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: maxNameLines,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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
