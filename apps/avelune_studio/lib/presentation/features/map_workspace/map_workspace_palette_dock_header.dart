import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/buttons/studio_button.dart';

class MapWorkspacePaletteDockHeader extends StatelessWidget {
  const MapWorkspacePaletteDockHeader({
    super.key,
    required this.kind,
    required this.collapsed,
    required this.onKindChanged,
    required this.onToggle,
    required this.onResize,
    required this.onOpenFullPalette,
    this.compact = false,
  });

  final String kind;
  final bool collapsed;
  final bool compact;
  final ValueChanged<String> onKindChanged;
  final VoidCallback onToggle;
  final ValueChanged<double> onResize;
  final VoidCallback onOpenFullPalette;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(kind == 'Terrains' ? Icons.terrain : Icons.category_outlined),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          tooltip: 'Changer la palette',
          initialValue: kind,
          onSelected: onKindChanged,
          itemBuilder: (_) => [
            for (final value in const [
              'Décors',
              'Terrains',
              'Tuiles',
              'Personnages',
              'Passages',
            ])
              PopupMenuItem(value: value, child: Text(value)),
          ],
          child: Row(
            children: [
              Text(kind, style: Theme.of(context).textTheme.titleSmall),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        Expanded(
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeUpDown,
            child: GestureDetector(
              key: const ValueKey('palette-resize-handle'),
              behavior: HitTestBehavior.opaque,
              onVerticalDragUpdate: (details) => onResize(details.delta.dy),
              child: SizedBox(
                height: 32,
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color.outline,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (compact)
          StudioTool(
            label: 'Bibliothèque',
            icon: Icons.folder_outlined,
            onPressed: onOpenFullPalette,
          )
        else
          StudioButton(
            label: 'Bibliothèque',
            icon: Icons.folder_outlined,
            secondary: true,
            onPressed: onOpenFullPalette,
          ),
        const SizedBox(width: 8),
        StudioTool(
          label: collapsed ? 'Déployer' : 'Réduire',
          icon: collapsed ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          onPressed: onToggle,
        ),
      ],
    );
  }
}
