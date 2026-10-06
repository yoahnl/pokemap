import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class MapCanvasSurfaceBounds extends StatelessWidget {
  const MapCanvasSurfaceBounds({super.key, required this.map});
  final MapData map;

  @override
  Widget build(BuildContext context) {
    final empty =
        map.layers.isEmpty &&
        map.placedElements.isEmpty &&
        map.entities.isEmpty &&
        map.warps.isEmpty &&
        map.triggers.isEmpty;
    final colors = Theme.of(context).colorScheme;
    return IgnorePointer(
      child: DecoratedBox(
        key: const ValueKey('map-surface-bounds'),
        decoration: BoxDecoration(
          color: empty ? colors.surfaceContainer : null,
          border: Border.all(color: colors.outlineVariant, width: 1),
        ),
        child: empty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Carte vide · choisissez un terrain ou un décor dans la palette.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
