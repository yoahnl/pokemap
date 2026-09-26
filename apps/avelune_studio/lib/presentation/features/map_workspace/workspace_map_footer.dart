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
    required this.showMapNotice,
  });
  final MapWorkspaceVisuals visuals;
  final MapData? map;
  final bool showMapNotice;

  bool get _hasVisibleBorders =>
      map?.layers.any((layer) => layer is BorderLayer && layer.isVisible) ==
      true;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showMapNotice && _hasVisibleBorders)
          ListenableBuilder(
            listenable: visuals,
            builder: (context, _) {
              final MapBorderPreviewVisuals? preview =
                  visuals is MapBorderPreviewVisuals
                  ? visuals as MapBorderPreviewVisuals
                  : null;
              if (preview != null) {
                if (preview.borderPreviewIssue case final issue?) {
                  return Tooltip(
                    message: issue,
                    child: const Text(
                      'Bordures indisponibles · voir les diagnostics',
                      key: ValueKey('map-border-notice'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }
                if (preview.borderPreviewLoading) {
                  return const Text(
                    'Chargement des bordures…',
                    key: ValueKey('map-border-notice'),
                  );
                }
                if (preview.borderPreviewReady) return const SizedBox.shrink();
              }
              return const Tooltip(
                message:
                    'Les bordures restent conservées et rendues dans le test du jeu.',
                child: Text(
                  'Bordures non prévisualisées · visibles dans le test du jeu',
                  key: ValueKey('map-border-notice'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        WorkspaceResourceDiagnostics(visuals: visuals),
      ],
    ),
  );
}
