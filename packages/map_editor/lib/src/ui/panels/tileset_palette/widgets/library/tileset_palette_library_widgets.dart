part of 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

// These widgets are purely presentational slices of the palette library.
// Keeping them local avoids inventing new public APIs for one panel.

class _CategoryTreeRow extends StatelessWidget {
  final int depth;
  final bool selected;
  final String label;
  final bool hasChildren;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback? onToggleExpanded;
  final Color? accentOverride;

  const _CategoryTreeRow({
    required this.depth,
    required this.selected,
    required this.label,
    required this.hasChildren,
    required this.expanded,
    required this.onTap,
    this.onToggleExpanded,
    this.accentOverride,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.pokeMapColors;
    final accent = accentOverride ?? colors.brandPrimary;
    final labelColor = colors.textPrimary;
    final background =
        selected ? colors.surfaceSelected : EditorPaintColors.transparent;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        color: background,
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            SizedBox(width: 10.0 * depth),
            SizedBox(
              width: 22,
              child: hasChildren
                  ? EditorToolbarIconButton(
                      onPressed: onToggleExpanded,
                      icon: expanded
                          ? CupertinoIcons.chevron_down
                          : CupertinoIcons.chevron_right,
                      iconSize: 14,
                      color: accent,
                    )
                  : const SizedBox.shrink(),
            ),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? accent : labelColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
