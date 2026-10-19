import 'dart:convert';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_stroke.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_terrain_draft_test.dart' show spatialPathDraft;
import '../support/spatial_environment_fixture.dart';

void main() {
  for (final length in [1, 3, 5]) {
    test(
      'Studio paints previews erases one cell and reopens clipped band $length',
      () {
        final draft = spatialPathDraft();
        final preset = draft.previewPreset;
        final pattern = ProjectSmartTilePattern(
          id: 'clipped-floor',
          name: 'Sol intérieur',
          usage: preset.usage,
          width: 1,
          height: length,
          repeatMode: SmartTilePatternRepeatMode.stamp,
          cells: [
            for (var z = 0; z < length; z++)
              SmartTilePatternCell(
                x: 0,
                y: z,
                parts: [
                  SmartTileVisualPart(
                    source: SmartTileVisualSource.model3d(
                      modelId: draft.manifest.models3d.single.id,
                      offsetX: 20,
                      offsetZ: 20 - z.toDouble(),
                      followTerrain: false,
                    ),
                    spatialClip: SmartTileSpatialClip(
                      left: 0,
                      top: 0,
                      right: 1,
                      bottom: 1,
                    ),
                  ),
                ],
              ),
          ],
        );
        final project = ProjectManifest(
          name: 'Clipped floor',
          version: ProjectVersion.v9,
          maps: const [
            ProjectMapEntry(id: 'a', name: 'Room', relativePath: 'maps/a.json'),
          ],
          tilesets: const [],
          models3d: draft.manifest.models3d,
          settings: ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile(),
          ),
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: [
              ProjectSmartTileMaterial(
                id: preset.defaultMaterialId,
                name: 'Sol',
                connectionGroupId: 'floor',
              ),
            ],
            presets: [preset],
            patterns: [pattern],
          ),
        );
        final map = spatialEnvironmentMap();
        final document = EditableMapDocument(
          MapWorkspaceDocument(
            map: map,
            mapId: map.id,
            revision: 'clipped-floor',
          ),
        );
        final view = MapWorkspaceViewState()
          ..prepareTerrainPainting(preset)
          ..selectTerrainPattern(pattern);
        addTearDown(view.dispose);
        final commands = MapEditingCommands(document, project);
        final stroke = MapCanvasStroke.start(
          map: map,
          project: project,
          view: view,
          commands: commands,
          origin: const GridPos(x: 2, y: 2),
        )!;
        expect(document.current, map);
        expect(
          resolveSpatialSmartTileInstances(
            map: stroke.preview,
            catalog: project.smartTileCatalog,
          ),
          hasLength(length),
        );
        document.commit(stroke.commit());
        final placed = document.current;
        final before = resolveSpatialSmartTileInstances(
          map: placed,
          catalog: project.smartTileCatalog,
        );
        expect(
          before.every(
            (instance) => instance.clip != null && !instance.blocksMovement,
          ),
          isTrue,
        );
        view.tool = StudioMapTool.erase;
        final erasedIndex = length ~/ 2;
        final erase = MapCanvasStroke.start(
          map: placed,
          project: project,
          view: view,
          commands: commands,
          origin: GridPos(x: 2, y: 2 + erasedIndex),
        )!;
        document.commit(erase.commit());
        final remaining = resolveSpatialSmartTileInstances(
          map: document.current,
          catalog: project.smartTileCatalog,
        );
        expect(
          remaining.where((instance) => instance.clip != null),
          [
            for (var i = 0; i < before.length; i++)
              if (i != erasedIndex) before[i],
          ],
        );
        final projected = projectSpatialSmartTileModels(
          map: document.current,
          catalog: project.smartTileCatalog,
        );
        final reopened = MapData.fromJson(
          jsonDecode(jsonEncode(projected.toJson())) as Map<String, dynamic>,
        );
        expect(reopened.spatialScene!.instances, remaining);
        document.restore(redo: false);
        expect(document.current, placed);
      },
    );
  }
}
