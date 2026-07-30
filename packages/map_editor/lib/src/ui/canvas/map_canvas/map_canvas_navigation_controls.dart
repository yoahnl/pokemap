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

  static const double _wideLayoutMinWidth = 480;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _wideLayoutMinWidth ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5;
        return MouseRegion(
          cursor: SystemMouseCursors.basic,
          child: PokeMapCard(
            padding: const EdgeInsets.all(4),
            borderRadius: 8,
            child: compact ? _buildCompactControls() : _buildWideControls(),
          ),
        );
      },
    );
  }

  Widget _buildWideControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildZoomControls(),
        const SizedBox(width: 6),
        PokeMapButton(
          key: const ValueKey<String>('map-navigation-fit'),
          onPressed: onFit,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.compact,
          child: const Text('Ajuster'),
        ),
        const SizedBox(width: 2),
        PokeMapButton(
          key: const ValueKey<String>('map-navigation-actual-size'),
          onPressed: onActualSize,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.compact,
          child: const Text('100 %'),
        ),
        const SizedBox(width: 2),
        PokeMapButton(
          key: const ValueKey<String>('map-navigation-center'),
          onPressed: onCenter,
          variant: PokeMapButtonVariant.ghost,
          size: PokeMapButtonSize.compact,
          child: const Text('Centrer'),
        ),
      ],
    );
  }

  Widget _buildCompactControls() {
    return Wrap(
      alignment: WrapAlignment.end,
      runAlignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 4,
      children: [
        _buildZoomControls(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PokeMapIconButton(
              key: const ValueKey<String>('map-navigation-fit'),
              size: 36,
              onPressed: onFit,
              icon: const Icon(
                CupertinoIcons.arrow_up_left_arrow_down_right,
              ),
              tooltip: 'Ajuster la carte',
            ),
            const SizedBox(width: 2),
            PokeMapIconButton(
              key: const ValueKey<String>('map-navigation-actual-size'),
              size: 36,
              onPressed: onActualSize,
              icon: const Icon(CupertinoIcons.viewfinder),
              tooltip: 'Afficher à 100 %',
            ),
            const SizedBox(width: 2),
            PokeMapIconButton(
              key: const ValueKey<String>('map-navigation-center'),
              size: 36,
              onPressed: onCenter,
              icon: const Icon(CupertinoIcons.scope),
              tooltip: 'Centrer la carte',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildZoomControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PokeMapIconButton(
          key: const ValueKey<String>('map-navigation-zoom-out'),
          size: 36,
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
          size: 36,
          onPressed: onZoomIn,
          icon: const Icon(CupertinoIcons.plus),
          tooltip: 'Zoom avant',
          variant: PokeMapIconButtonVariant.soft,
        ),
      ],
    );
  }
}
