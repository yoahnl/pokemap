import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_terrain_settings_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_terrain_draft_test.dart';

void main() {
  test('path behavior can be configured before painting and undone', () {
    final draft = spatialPathDraft();
    final preset = draft.previewPreset.copyWith(
      status: SmartTilePresetStatus.published,
    );
    final project = draft.manifest.copyWith(
      version: ProjectVersion.v9,
      elements: const [],
      tilesets: const [],
      settings: draft.manifest.settings.copyWith(
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: const [
        ProjectMapEntry(id: 'a', name: 'Map', relativePath: 'maps/a.json'),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: draft.draft.materials,
        presets: [preset],
      ),
      encounterTables: const [
        ProjectEncounterTable(
          id: 'grass',
          name: 'Herbes de la route',
          encounterKind: EncounterKind.walk,
          entries: [
            ProjectEncounterEntry(speciesId: 'zubat', minLevel: 2, maxLevel: 4),
          ],
        ),
      ],
    );
    final map = MapData(
      version: ProjectVersion.v9,
      id: 'a',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    );
    final commands = MapTerrainSettingsCommands(document, project);
    expect(
      commands.animation(preset, SmartTileAnimationActivation.onEnter),
      isTrue,
    );
    expect(document.error, isNull);
    final layer = document.current.layers.whereType<SmartTileLayer>().single;
    expect(layer.animationActivation, SmartTileAnimationActivation.onEnter);
    expect(smartTileSemanticCells(layer), everyElement(0));
    expect(commands.encounter(preset, 'grass'), isTrue);
    final configured = document.current.layers
        .whereType<SmartTileLayer>()
        .single;
    expect(configured.encounterBehavior!.encounter.encounterTableId, 'grass');
    expect(configured.encounterBehavior!.materialId, preset.defaultMaterialId);
    expect(document.current.gameplayZones, isEmpty);
    MapValidator.validate(document.current, projectDialogueContext: project);
    expect(commands.encounter(preset, ''), isTrue);
    expect(
      document.current.layers
          .whereType<SmartTileLayer>()
          .single
          .encounterBehavior,
      isNull,
    );
    document.restore(redo: false);
    expect(
      document.current.layers
          .whereType<SmartTileLayer>()
          .single
          .encounterBehavior,
      configured.encounterBehavior,
    );
    expect(document.current.spatialScene, map.spatialScene);
  });

  test('terrain animation choices preserve the selected model transform', () {
    final base = spatialPathDraft();
    final original = base.manifest.models3d.single;
    final animated = ProjectModel3dEntry(
      id: original.id,
      name: original.name,
      sourceAssetId: original.sourceAssetId,
      relativePath: original.relativePath,
      inspection: Model3dInspection(
        bounds: original.inspection.bounds,
        meshCount: 1,
        triangleCount: 4,
        animations: [
          Model3dAnimation(index: 0, name: 'Passage', durationSeconds: .6),
        ],
      ),
    );
    final draft = TerrainDraftController.resume(
      manifest: base.manifest.copyWith(models3d: [animated]),
      draft: base.draft,
    );
    draft.assignModel(
      animated,
      scale: 1.5,
      offsetX: .25,
      offsetY: .5,
      offsetZ: .75,
      quarterTurns: 1,
    );
    final previous = draft.partFor(0)!;
    expect(draft.setSelectedModelAnimation(0), isTrue);
    final animatedPart = draft.partFor(0)!;
    final source = animatedPart.source as SmartTileModel3dSource;
    expect(source.animationIndex, 0);
    expect(source.scale, 1.5);
    expect(source.offsetX, .25);
    expect(source.offsetY, .5);
    expect(source.offsetZ, .75);
    expect(animatedPart.transform, previous.transform);
    expect(draft.setSelectedModelAnimation(null), isTrue);
    expect(
      (draft.partFor(0)!.source as SmartTileModel3dSource).animationIndex,
      isNull,
    );
    expect(base.manifest.models3d.single.inspection.animations, isEmpty);
  });
}
