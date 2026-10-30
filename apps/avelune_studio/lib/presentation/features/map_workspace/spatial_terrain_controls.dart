import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/spatial_terrain_stroke.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'spatial_ramp_editor.dart';
import 'spatial_ledge_editor.dart';
import 'spatial_fishing_editor.dart';
import 'spatial_terrain_surface_editor.dart';

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
            key: const ValueKey('spatial-relief-shape'),
            label: 'Forme du relief',
            value: view.spatialContinuousTerrain ? 'surface' : 'blocks',
            options: const {'blocks': 'Blocs', 'surface': 'Surface continue'},
            onChanged: document.saving
                ? null
                : (value) {
                    view.spatialContinuousTerrain = value == 'surface';
                    view.terrainSurfacePreview = null;
                    onChanged();
                  },
          ),
          const SizedBox(height: 12),
          if (view.spatialContinuousTerrain) ...[
            StudioSelect(
              key: const ValueKey('spatial-surface-model-heights'),
              label: 'Décors déjà placés',
              value: view.spatialSurfaceReanchorInstances ? 'follow' : 'keep',
              options: const {
                'follow': 'Suivre la hauteur du terrain',
                'keep': 'Conserver leur hauteur',
              },
              onChanged: document.saving
                  ? null
                  : (value) {
                      view.spatialSurfaceReanchorInstances = value == 'follow';
                      view.terrainSurfacePreview = null;
                      onChanged();
                    },
            ),
            const SizedBox(height: 12),
            StudioDraftField(
              key: const ValueKey('spatial-surface-low-level'),
              label: 'Hauteur basse',
              value: view.spatialSurfaceLowLevel,
              enabled: !document.saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                view.spatialSurfaceLowLevel = value;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            StudioDraftField(
              key: const ValueKey('spatial-surface-high-level'),
              label: 'Hauteur haute',
              value: view.spatialSurfaceHighLevel,
              enabled: !document.saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (value) {
                view.spatialSurfaceHighLevel = value;
                onChanged();
              },
            ),
            const SizedBox(height: 12),
            StudioSelect(
              label: 'Montée vers',
              value: view.spatialSurfaceDirection.name,
              options: const {
                'north': 'Le haut de la carte',
                'south': 'Le bas de la carte',
                'east': 'La droite de la carte',
                'west': 'La gauche de la carte',
              },
              onChanged: document.saving
                  ? null
                  : (value) {
                      view.spatialSurfaceDirection = SpatialRampDirection.values
                          .byName(value);
                      onChanged();
                    },
            ),
            const SizedBox(height: 8),
            const StudioNotice(
              'Glissez pour dessiner une surface. Deux hauteurs identiques créent un replat. Le terrain peint suit sa forme. La gomme supprime entièrement les surfaces touchées.',
            ),
            const SizedBox(height: 12),
            SpatialTerrainSurfaceEditor(
              document: document,
              view: view,
              onChanged: onChanged,
            ),
          ] else ...[
            StudioSelect(
              label: 'Hauteur du relief',
              value: '${view.spatialTerrainLevel}',
              options: {
                for (
                  var level = 0;
                  level <= MapSpatialScene.maximumTerrainLevel;
                  level++
                )
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
          ],
        ] else if (view.spatialTerrainMode == SpatialTerrainMode.ramp) ...[
          const StudioNotice(
            'Glissez du bas vers le haut, entre deux sols de hauteurs différentes. Les cases dessinées forment la pente ; ses deux extrémités doivent toucher les sols.',
          ),
          const SizedBox(height: 8),
          Text(
            '${scene.navigation.ramps.length} ${scene.navigation.ramps.length == 1 ? "pente" : "pentes"} · La gomme retire une pente.',
          ),
          const SizedBox(height: 12),
          SpatialRampEditor(
            document: document,
            project: project,
            view: view,
            onChanged: onChanged,
          ),
        ] else
          const StudioNotice(
            'Le sol et les chemins suivent le relief et les pentes. Leur peinture ne change pas la hauteur.',
          ),
        const SizedBox(height: 16),
        SpatialFishingEditor(
          document: document,
          project: project,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        SpatialLedgeEditor(
          document: document,
          project: project,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
        StudioSelect(
          label: 'Parois du relief',
          value: scene.generateCliffs ? 'generated' : 'models',
          options: const {
            'generated': 'Générées avec le terrain',
            'models': 'Réalisées avec des décors 3D',
          },
          onChanged: document.saving
              ? null
              : (value) {
                  try {
                    document.commit(
                      const SpatialMapOperations().configureTerrainAppearance(
                        document.current,
                        cliffFrame: scene.cliffFrame,
                        generateCliffs: value == 'generated',
                      ),
                    );
                  } on Object catch (failure) {
                    document.error = failure.toString();
                  }
                  onChanged();
                },
        ),
        if (!scene.generateCliffs) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'Les décors 3D dessinent les falaises. Le relief continue de gérer les hauteurs et les collisions.',
          ),
        ],
        const SizedBox(height: 12),
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
