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
    final accent = accentOverride ?? CupertinoTheme.of(context).primaryColor;
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final background = selected
        ? accent.withValues(alpha: 0.14)
        : EditorPaintColors.transparent;
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

class _ProjectElementCard extends StatelessWidget {
  final ui.Image image;
  final ProjectElementEntry element;
  final int tileWidth;
  final int tileHeight;
  final bool selected;
  final Color selectionAccent;
  final String categoryPath;
  final String tilesetName;
  final String groupLabel;
  final String tilesetGroupLabel;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProjectElementCard({
    required this.image,
    required this.element,
    required this.tileWidth,
    required this.tileHeight,
    required this.selected,
    required this.selectionAccent,
    required this.categoryPath,
    required this.tilesetName,
    required this.groupLabel,
    required this.tilesetGroupLabel,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final sep = CupertinoColors.separator.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final labelColor = CupertinoColors.label.resolveFrom(context);
    final tertiary = CupertinoColors.placeholderText.resolveFrom(context);
    final baseColor = selected
        ? selectionAccent.withValues(alpha: 0.1)
        : EditorPaintColors.transparent;
    final collisionCellCount = element.collisionProfile?.cells.length ?? 0;
    final meta2 = [
      groupLabel,
      tilesetGroupLabel,
      'Type: ${_elementPresetLabel(element.presetKind)}',
      'Collision: $collisionCellCount',
      if (element.recommendedLayerId != null &&
          element.recommendedLayerId!.isNotEmpty)
        'Calque : ${element.recommendedLayerId}',
    ].join(' · ');
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? selectionAccent : sep,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: sep),
                ),
                child: _PaletteRectPreview(
                  image: image,
                  source: element.frames.primarySource,
                  tileWidth: tileWidth,
                  tileHeight: tileHeight,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    element.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$categoryPath · $tilesetName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: secondary, fontSize: 10),
                  ),
                  Text(
                    meta2,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: tertiary, fontSize: 10),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: Colors.transparent,
              child: PopupMenuButton<int>(
                tooltip: 'Actions',
                padding: EdgeInsets.zero,
                splashRadius: 14,
                offset: const Offset(0, 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                  side: BorderSide(
                    color: selectionAccent.withValues(alpha: 0.45),
                  ),
                ),
                color: EditorChrome.islandFillElevated(context),
                elevation: 3,
                itemBuilder: (ctx) => [
                  PopupMenuItem<int>(
                    value: 0,
                    child: Text(
                      'Modifier',
                      style: TextStyle(color: labelColor),
                    ),
                  ),
                  PopupMenuItem<int>(
                    value: 1,
                    child: Text(
                      'Supprimer',
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed.resolveFrom(
                          ctx,
                        ),
                      ),
                    ),
                  ),
                ],
                onSelected: (i) {
                  if (i == 0) {
                    onEdit();
                  } else if (i == 1) {
                    onDelete();
                  }
                },
                child: SizedBox(
                  width: 36,
                  height: 28,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: EditorChrome.largeIslandSurfaceColor(
                        context,
                        tint: selectionAccent.withValues(alpha: 0.12),
                      ),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: selectionAccent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      CupertinoIcons.ellipsis_vertical,
                      size: 16,
                      color: labelColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaletteTileCell extends StatelessWidget {
  final ui.Image image;
  final int tileId;
  final int tileWidth;
  final int tileHeight;
  final int columns;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteTileCell({
    required this.image,
    required this.tileId,
    required this.tileWidth,
    required this.tileHeight,
    required this.columns,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = CupertinoTheme.of(context).primaryColor;
    final sep = CupertinoColors.separator.resolveFrom(context);
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: selected ? accent : sep),
        ),
        child: _PaletteTilePreview(
          image: image,
          tileId: tileId,
          tileWidth: tileWidth,
          tileHeight: tileHeight,
          columns: columns,
        ),
      ),
    );
  }
}

String _elementPresetLabel(ElementPresetKind kind) {
  switch (kind) {
    case ElementPresetKind.generic:
      return 'Generic';
    case ElementPresetKind.tree:
      return 'Tree';
    case ElementPresetKind.building:
      return 'Building';
    case ElementPresetKind.rock:
      return 'Rock';
    case ElementPresetKind.cliff:
      return 'Cliff';
    case ElementPresetKind.tallDecoration:
      return 'Tall deco';
  }
}
