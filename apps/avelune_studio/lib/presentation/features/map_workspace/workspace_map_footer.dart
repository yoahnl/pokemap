import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'map_workspace_visuals.dart';
import 'workspace_resource_diagnostics.dart';

/// What the canvas cannot show but the game still honours, kept under the map
/// so an author never mistakes a preview limit for lost data.
class WorkspaceMapFooter extends StatelessWidget {
  const WorkspaceMapFooter({
    super.key,
    required this.visuals,
    required this.map,
  });
  final MapWorkspaceVisuals visuals;
  final MapData? map;

  bool get _hasVisibleBorders =>
      map?.layers.any((layer) => layer is BorderLayer && layer.isVisible) ==
      true;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasVisibleBorders)
          const Tooltip(
            message:
                'Les bordures restent conservées et rendues dans le test du jeu.',
            child: Text(
              'Bordures non prévisualisées · visibles dans le test du jeu',
              key: ValueKey('map-border-notice'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        WorkspaceResourceDiagnostics(visuals: visuals),
      ],
    ),
  );
}
