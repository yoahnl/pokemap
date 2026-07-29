import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

import '../../design_system/design_system.dart';

/// Compact, design-system-only controls for the world-map viewport.
class MapCanvasNavigationControls extends StatelessWidget {
  const MapCanvasNavigationControls({
    super.key,
    required this.zoom,
    required this.onZoomOut,
    required this.onZoomIn,
    required this.onFit,
    required this.onActualSize,
    required this.onCenter,
  });

  final double zoom;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomIn;
  final VoidCallback onFit;
  final VoidCallback onActualSize;
  final VoidCallback onCenter;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      child: PokeMapCard(
        padding: const EdgeInsets.all(4),
        borderRadius: 8,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PokeMapIconButton(
              key: const ValueKey<String>('map-navigation-zoom-out'),
              onPressed: onZoomOut,
              icon: const Icon(CupertinoIcons.minus),
              tooltip: 'Zoom arrière',
              variant: PokeMapIconButtonVariant.soft,
            ),
            const SizedBox(width: 4),
            PokeMapBadge(label: '${(zoom * 100).round()} %'),
            const SizedBox(width: 4),
            PokeMapIconButton(
              key: const ValueKey<String>('map-navigation-zoom-in'),
              onPressed: onZoomIn,
              icon: const Icon(CupertinoIcons.plus),
              tooltip: 'Zoom avant',
              variant: PokeMapIconButtonVariant.soft,
            ),
            const SizedBox(width: 6),
            PokeMapButton(
              key: const ValueKey<String>('map-navigation-fit'),
              onPressed: onFit,
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              child: const Text('Ajuster'),
            ),
            const SizedBox(width: 2),
            PokeMapButton(
              key: const ValueKey<String>('map-navigation-actual-size'),
              onPressed: onActualSize,
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              child: const Text('100 %'),
            ),
            const SizedBox(width: 2),
            PokeMapButton(
              key: const ValueKey<String>('map-navigation-center'),
              onPressed: onCenter,
              variant: PokeMapButtonVariant.ghost,
              size: PokeMapButtonSize.small,
              child: const Text('Centrer'),
            ),
          ],
        ),
      ),
    );
  }
}
