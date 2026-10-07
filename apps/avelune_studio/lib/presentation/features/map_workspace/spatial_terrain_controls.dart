import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/spatial_terrain_stroke.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';

class SpatialTerrainControls extends StatelessWidget {
  const SpatialTerrainControls({
    super.key,
    required this.document,
    required this.project,
    required this.view,
    required this.visuals,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceViewState view;
  final MapWorkspaceVisuals visuals;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final scene = document.current.spatialScene!;
    final frame = scene.cliffFrame;
    final atlases = project.smartTileCatalog.atlases
        .where(
          (atlas) =>
              (atlas.columns == 1 && atlas.rows == 1 ||
                  atlas.id == frame?.atlasId) &&
              project.tilesets.any((image) => image.id == atlas.tilesetId),
        )
        .toList();
    final selected = atlases
        .where((atlas) => atlas.id == frame?.atlasId)
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (view.spatialTerrainMode == SpatialTerrainMode.relief) ...[
          StudioSelect(
            label: 'Hauteur du relief',
            value: '${view.spatialTerrainLevel}',
            options: {
              for (var level = 0; level <= 32; level++)
                '$level': level == 0
                    ? 'Sol · 0 bloc'
                    : '$level ${level == 1 ? "bloc" : "blocs"}',
            },
            onChanged: (value) {
              view.spatialTerrainLevel = int.parse(value);
              onChanged();
            },
          ),
          const SizedBox(height: 12),
          const StudioNotice(
            'Peignez les cases à cette hauteur. La gomme remet le relief au sol.',
          ),
        ] else if (view.spatialTerrainMode == SpatialTerrainMode.ramp) ...[
          const StudioNotice(
            'Glissez du bas vers le haut, entre deux sols de hauteurs différentes. Les cases dessinées forment la pente ; ses deux extrémités doivent toucher les sols.',
          ),
          const SizedBox(height: 8),
          Text(
            '${scene.navigation.ramps.length} ${scene.navigation.ramps.length == 1 ? "pente" : "pentes"} · La gomme retire une pente.',
          ),
        ] else
          const StudioNotice(
            'Le sol et les chemins suivent le relief et les pentes. Leur peinture ne change pas la hauteur.',
          ),
        const SizedBox(height: 16),
        StudioSelect(
          label: 'Texture des falaises',
          value: frame?.atlasId ?? 'none',
          options: {
            'none': 'Sans texture',
            for (final atlas in atlases) atlas.id: atlas.name,
          },
          onChanged: document.saving
              ? null
              : (value) {
                  try {
                    document.commit(
                      const SpatialMapOperations().configureTerrainAppearance(
                        document.current,
                        cliffFrame: value == 'none'
                            ? null
                            : SmartTileFrameRef(
                                atlasId: value,
                                column: 0,
                                row: 0,
                              ),
                      ),
                    );
                  } on Object catch (failure) {
                    document.error = failure.toString();
                  }
                  onChanged();
                },
        ),
        if (selected != null && visuals is ResourceWorkspaceVisuals) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 80,
            child: (visuals as ResourceWorkspaceVisuals).atlasPreview(
              selected.tilesetId,
            ),
          ),
        ],
        if (atlases.isEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Ajoutez une texture de paroi dans Ressources, avec un atlas d’une seule case.',
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
