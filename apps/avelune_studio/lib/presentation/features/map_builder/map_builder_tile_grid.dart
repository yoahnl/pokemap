import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

class MapBuilderTile<T> {
  const MapBuilderTile({
    required this.value,
    required this.icon,
    required this.label,
    required this.key,
  });

  final T value;
  final IconData icon;
  final String label;
  final Key key;
}

class MapBuilderTileGrid<T> extends StatelessWidget {
  const MapBuilderTileGrid({
    super.key,
    required this.tiles,
    required this.selected,
    required this.onSelected,
    this.columns = 3,
  });

  final List<MapBuilderTile<T>> tiles;
  final T? selected;
  final ValueChanged<T>? onSelected;
  final int columns;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var start = 0; start < tiles.length; start += columns)
        Padding(
          padding: EdgeInsets.only(top: start == 0 ? 0 : StudioSpacing.xs),
          child: Row(
            children: [
              for (var index = start; index < start + columns; index++) ...[
                if (index > start) const SizedBox(width: StudioSpacing.xs),
                Expanded(
                  child: index < tiles.length
                      ? _Tile(
                          tile: tiles[index],
                          selected: tiles[index].value == selected,
                          onTap: switch (onSelected) {
                            final onSelected? => () => onSelected(
                              tiles[index].value,
                            ),
                            null => null,
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
    ],
  );
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.tile,
    required this.selected,
    required this.onTap,
  });

  final MapBuilderTile<Object?> tile;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: tile.label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: tile.key,
          borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
          onTap: onTap,
          child: Ink(
            height: 64,
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tile.icon, size: 20, color: foreground),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.xs,
                  ),
                  child: Text(
                    tile.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? scheme.onPrimaryContainer : null,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
