import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/spatial_terrain_stroke.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_preview.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'map_terrain_patterns.dart';

class MapTerrainToolPanel extends StatelessWidget {
  const MapTerrainToolPanel({
    super.key,
    required this.document,
    required this.project,
    required this.visuals,
    required this.view,
    required this.onChanged,
  });
  final EditableMapDocument document;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final preset = view.terrain;
    final patterns = preset == null
        ? <ProjectSmartTilePattern>[]
        : availableTerrainPatterns(
            project: project,
            map: document.current,
            preset: preset,
          );
    final selectedPattern = patterns
        .where((pattern) => pattern.id == view.terrainPatternId)
        .firstOrNull;
    final materials = {
      for (final material in project.smartTileCatalog.materials)
        if (preset?.allowedMaterialIds.contains(material.id) == true)
          material.id: material.name,
    };
    final item = resourceCatalog(project)
        .where(
          (item) => item.kind == ResourceKind.terrains && item.id == preset?.id,
        )
        .firstOrNull;
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (document.current.spatialScene != null)
            for (final mode in SpatialTerrainMode.values)
              StudioButton(
                label: switch (mode) {
                  SpatialTerrainMode.ground => 'Sol',
                  SpatialTerrainMode.relief => 'Relief',
                  SpatialTerrainMode.ramp => 'Pente',
                },
                secondary: view.spatialTerrainMode != mode,
                onPressed: () {
                  view.spatialTerrainMode = mode;
                  view.tool = StudioMapTool.terrain;
                  onChanged();
                },
              ),
          if (document.current.spatialScene != null &&
              view.spatialTerrainMode == SpatialTerrainMode.relief)
            SizedBox(
              width: 160,
              child: StudioSelect(
                label: 'Hauteur',
                value: '${view.spatialTerrainLevel}',
                options: {
                  for (
                    var level = 0;
                    level <= MapSpatialScene.maximumTerrainLevel;
                    level++
                  )
                    '$level': '$level ${level == 1 ? "bloc" : "blocs"}',
                },
                onChanged: document.saving
                    ? null
                    : (value) {
                        view.spatialTerrainLevel = int.parse(value);
                        onChanged();
                      },
              ),
            ),
          if (item != null &&
              (document.current.spatialScene == null ||
                  view.spatialTerrainMode == SpatialTerrainMode.ground))
            SizedBox(
              width: 36,
              height: 36,
              child: resourcePreview(item, project, visuals, size: 36),
            ),
          if (document.current.spatialScene == null ||
              view.spatialTerrainMode == SpatialTerrainMode.ground)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 200),
              child: Text(
                preset?.name ?? 'Choisissez un terrain',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          StudioButton(
            key: const ValueKey('terrain-paint'),
            label: 'Pinceau',
            icon: Icons.brush_outlined,
            secondary: view.tool != StudioMapTool.terrain,
            onPressed:
                preset == null &&
                    (document.current.spatialScene == null ||
                        view.spatialTerrainMode == SpatialTerrainMode.ground)
                ? null
                : () {
                    view.tool = StudioMapTool.terrain;
                    onChanged();
                  },
          ),
          if (preset != null &&
              materials.length > 1 &&
              (document.current.spatialScene == null ||
                  view.spatialTerrainMode == SpatialTerrainMode.ground))
            SizedBox(
              width: 210,
              child: StudioSelect(
                key: const ValueKey('terrain-material-picker'),
                label: 'Matière',
                value:
                    preset.allowedMaterialIds.contains(view.terrainMaterialId)
                    ? view.terrainMaterialId
                    : preset.defaultMaterialId,
                options: materials,
                onChanged: document.saving || selectedPattern != null
                    ? null
                    : (id) {
                        if (!preset.allowedMaterialIds.contains(id) ||
                            !materials.containsKey(id)) {
                          return;
                        }
                        view.terrainMaterialId = id;
                        onChanged();
                      },
              ),
            ),
          if (preset != null &&
              (document.current.spatialScene == null ||
                  view.spatialTerrainMode == SpatialTerrainMode.ground))
            SizedBox(
              width: 240,
              child: StudioSelect(
                key: const ValueKey('terrain-pattern-picker'),
                label: 'Motif',
                value: selectedPattern?.id ?? '',
                options: {
                  '': 'Peinture libre',
                  for (final pattern in patterns) pattern.id: pattern.name,
                },
                onChanged: document.saving || patterns.isEmpty
                    ? null
                    : (id) {
                        view.selectTerrainPattern(
                          patterns
                              .where((pattern) => pattern.id == id)
                              .firstOrNull,
                        );
                        onChanged();
                      },
              ),
            ),
          if (selectedPattern != null &&
              (document.current.spatialScene == null ||
                  view.spatialTerrainMode == SpatialTerrainMode.ground))
            SizedBox(
              width: 170,
              child: StudioSelect(
                key: const ValueKey('terrain-pattern-mode'),
                label: 'Placement',
                value:
                    (selectedPattern.repeatMode ==
                                SmartTilePatternRepeatMode.stamp
                            ? SmartTilePatternSelectionKind.stamp
                            : view.terrainPatternMode)
                        .name,
                options: {
                  'stamp': 'Tampon',
                  if (selectedPattern.repeatMode ==
                      SmartTilePatternRepeatMode.tiled) ...{
                    'line': 'Ligne',
                    'rectangle': 'Rectangle',
                  },
                },
                onChanged: document.saving || view.tool != StudioMapTool.terrain
                    ? null
                    : (id) {
                        view.terrainPatternMode = SmartTilePatternSelectionKind
                            .values
                            .firstWhere((mode) => mode.name == id);
                        onChanged();
                      },
              ),
            ),
          StudioButton(
            key: const ValueKey('terrain-erase'),
            label: 'Gomme',
            icon: Icons.cleaning_services_outlined,
            secondary: view.tool != StudioMapTool.erase,
            onPressed: () {
              view.tool = StudioMapTool.erase;
              onChanged();
            },
          ),
          StudioButton(
            key: const ValueKey('terrain-highlight-toggle'),
            label: 'Surbrillance',
            icon: Icons.visibility_outlined,
            secondary: !view.highlightTerrain,
            onPressed: () {
              view.highlightTerrain = !view.highlightTerrain;
              onChanged();
            },
          ),
        ],
      ),
    );
  }
}
