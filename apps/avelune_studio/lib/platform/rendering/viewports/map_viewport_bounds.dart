import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

class MapViewportBounds extends StatelessWidget {
  const MapViewportBounds({super.key, required this.map});
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
      ),
    );
  }
}
