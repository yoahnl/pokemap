import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

const _spatialZoomStep = 240.0;
const _flatZoomStep = 1.25;

class MapBuilderStatusBar extends StatelessWidget {
  const MapBuilderStatusBar({
    super.key,
    required this.toolLabel,
    required this.view,
    required this.spatial,
    required this.onChanged,
  });

  final String toolLabel;
  final MapEditingViewportSession? view;
  final bool spatial;
  final VoidCallback onChanged;

  void _zoom(bool closer) {
    final view = this.view;
    if (view == null) return;
    if (spatial) {
      view.spatialSceneController?.dolly(
        closer ? _spatialZoomStep : -_spatialZoomStep,
      );
    } else {
      view.viewport.zoomBy(closer ? _flatZoomStep : 1 / _flatZoomStep);
    }
    onChanged();
  }

  void _recenter() {
    final view = this.view;
    if (view == null) return;
    if (spatial) {
      view.spatialSceneController?.reset();
    } else {
      view.recenter?.call();
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final view = this.view;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Ink(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Text(toolLabel, key: const ValueKey('map-status-tool'), style: muted),
          const Spacer(),
          IconButton(
            key: const ValueKey('map-status-grid'),
            tooltip: 'Afficher la grille',
            iconSize: 18,
            isSelected: view?.grid ?? false,
            onPressed: view == null
                ? null
                : () {
                    view.grid = !view.grid;
                    onChanged();
                  },
            icon: const Icon(Icons.grid_on_outlined),
          ),
          IconButton(
            key: const ValueKey('map-status-zoom-out'),
            tooltip: 'Réduire le zoom',
            iconSize: 18,
            onPressed: view == null ? null : () => _zoom(false),
            icon: const Icon(Icons.remove),
          ),
          if (!spatial && view != null)
            Text(
              '${(view.scale * 100).round()} %',
              key: const ValueKey('map-status-zoom'),
              style: muted,
            ),
          IconButton(
            key: const ValueKey('map-status-zoom-in'),
            tooltip: 'Augmenter le zoom',
            iconSize: 18,
            onPressed: view == null ? null : () => _zoom(true),
            icon: const Icon(Icons.add),
          ),
          IconButton(
            key: const ValueKey('map-status-recenter'),
            tooltip: 'Recentrer la carte',
            iconSize: 18,
            onPressed: view == null ? null : _recenter,
            icon: const Icon(Icons.center_focus_strong_outlined),
          ),
        ],
      ),
    );
  }
}
