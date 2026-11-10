import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/coordination/map_editing_input_session.dart';
import '../../../features/map_workspace/coordination/map_editing_shortcuts.dart';
import '../../../features/map_workspace/coordination/map_editing_viewport_session.dart';
import '../../../features/map_workspace/coordination/spatial_map_neighbor_session.dart';
import '../contracts/map_workspace_visuals.dart';
import 'map_editing_viewport_2d.dart';
import 'spatial_map_editing_viewport.dart';

class MapEditingSurface extends StatelessWidget {
  const MapEditingSurface({
    super.key,
    required this.controller,
    required this.visuals,
    required this.view,
    required this.input,
    required this.onChanged,
    this.neighbors,
    this.onZoneDrawn,
    this.onSave,
    this.busy = false,
  });

  final MapWorkspaceController controller;
  final MapWorkspaceVisuals visuals;
  final MapEditingViewportSession view;
  final MapEditingInputSession input;
  final SpatialMapNeighborSession? neighbors;
  final ValueChanged<MapRect>? onZoneDrawn;
  final VoidCallback? onSave;
  final VoidCallback onChanged;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final document = controller.active;
    final project = controller.project;
    if (document == null || project == null) return const SizedBox();
    return ListenableBuilder(
      listenable: input,
      builder: (_, _) {
        void guarded(VoidCallback action) {
          if (busy || !input.editingAvailable) return;
          action();
          onChanged();
        }

        return CallbackShortcuts(
          bindings: mapEditingShortcuts(
            controller,
            view,
            guarded,
            onSave: onSave,
            contextAt: input.contextAt,
          ),
          child: FocusScope(
            autofocus: true,
            onKeyEvent: (_, event) {
              if (!input.contextOpen) return KeyEventResult.ignored;
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                input.dismiss();
              }
              return KeyEventResult.handled;
            },
            child: ExcludeFocus(
              excluding: input.contextOpen,
              child: IgnorePointer(
                ignoring: input.contextOpen,
                child: document.current.spatialScene == null
                    ? MapEditingViewport2D(
                        key: ValueKey(document.base.mapId),
                        document: document,
                        gestureGeneration: 0,
                        project: project,
                        visuals: visuals,
                        view: view,
                        onChanged: onChanged,
                        onZoneDrawn: onZoneDrawn,
                        onContextMenu: (cell, _) => input.open(cell),
                      )
                    : SpatialMapEditingViewport(
                        key: ValueKey(document.base.mapId),
                        document: document,
                        project: project,
                        visuals: visuals,
                        view: view,
                        controller: controller,
                        neighbors: neighbors?.neighbors ?? const [],
                        neighborDecorations: neighbors?.decorations ?? const [],
                        exteriorContextReady: neighbors?.ready ?? true,
                        onChanged: onChanged,
                        onContextMenu: (cell, _) => input.open(cell),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
