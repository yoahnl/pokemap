import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_terrain_settings_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_terrain_draft_test.dart' show spatialPathDraft;

void main() {
  late EditableMapDocument document;
  late ProjectManifest project;
  late ProjectSmartTilePreset preset;
  late MapTerrainSettingsCommands commands;

  setUp(() {
    final draft = spatialPathDraft();
    preset = draft.previewPreset.copyWith(
      status: SmartTilePresetStatus.published,
    );
    project = draft.manifest.copyWith(
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
          name: 'Herbes',
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
    document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: 'a', revision: 'r0'),
    );
    commands = MapTerrainSettingsCommands(document, project);
  });

  test('path settings prepare a native layer without painting any cells', () {
    final source = document.current;
    expect(
      commands.animation(preset, SmartTileAnimationActivation.onEnter),
      isTrue,
    );
    final layer = document.current.layers.whereType<SmartTileLayer>().single;
    expect(layer.animationActivation, SmartTileAnimationActivation.onEnter);
    expect(smartTileSemanticCells(layer).every((value) => value == 0), isTrue);
    expect(document.undoCount, 1);
    MapValidator.validate(document.current, projectDialogueContext: project);
    document.restore(redo: false);
    expect(document.current, source);
  });

  test('encounter settings retain canonical validation and can be cleared', () {
    expect(
      commands.encounter(preset, 'grass', materialId: 'unavailable'),
      isTrue,
    );
    final layer = document.current.layers.whereType<SmartTileLayer>().single;
    expect(layer.encounterBehavior!.materialId, preset.defaultMaterialId);
    expect(layer.encounterBehavior!.encounter.encounterTableId, 'grass');
    expect(document.current.gameplayZones, isEmpty);
    MapValidator.validate(document.current, projectDialogueContext: project);
    final configured = document.current;
    expect(commands.encounter(preset, ''), isTrue);
    expect(
      document.current.layers
          .whereType<SmartTileLayer>()
          .single
          .encounterBehavior,
      isNull,
    );
    document.restore(redo: false);
    expect(document.current, configured);
  });

  test('unknown encounter table does not create a layer or an undo entry', () {
    final source = document.current;
    expect(commands.encounter(preset, 'unknown'), isFalse);
    expect(document.error, contains('n’est plus disponible'));
    expect(document.current, same(source));
    expect(document.canUndo, isFalse);
  });

  test(
    'a saving document rejects path settings without modifying its draft',
    () {
      final source = document.current;
      document.saving = true;
      expect(
        commands.animation(preset, SmartTileAnimationActivation.onEnter),
        isFalse,
      );
      expect(document.current, same(source));
      expect(document.canUndo, isFalse);
    },
  );
}
