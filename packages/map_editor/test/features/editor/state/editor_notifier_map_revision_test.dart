import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/pending_border_save_guard.dart';
import 'package:map_editor/src/features/editor/application/map_activation_coordinator.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('EditorNotifier map revision', () {
    test('normal saves advance the durable revision', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);

      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'First save',
        ),
      );
      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Second save',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath))
            .mapMetadata
            .displayName,
        'Second save',
      );
    });

    test('external edit conflicts and preserves local dirty history', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      final savedBefore = notifier.state.savedMapSnapshot;
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Local edit',
        ),
      );
      final localBeforeSave = notifier.state.activeMap;
      final undoBeforeSave = notifier.state.mapUndoStack;
      await fixture.writeMap(_map(name: 'External edit'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      final outcome = await notifier.saveActiveMap();

      expect(outcome, ActiveMapSaveOutcome.conflict);
      expect(notifier.state.activeMap, localBeforeSave);
      expect(notifier.state.savedMapSnapshot, savedBefore);
      expect(notifier.state.mapUndoStack, undoBeforeSave);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.errorMessage, contains('modifiée en dehors'));
      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
    });

    test('reload after conflict adopts external revision and can save again',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'First local edit',
        ),
      );
      await fixture.writeMap(_map(name: 'External edit'));
      expect(
        await notifier.saveActiveMap(),
        ActiveMapSaveOutcome.conflict,
      );

      expect(
        await notifier.activateMap(
          'maps/alpha.json',
          forceReload: true,
        ),
        MapActivationOutcome.activated,
      );
      expect(notifier.state.activeMap!.name, 'External edit');
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Edit after reload',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath))
            .mapMetadata
            .displayName,
        'Edit after reload',
      );
    });

    test('snapshot activation without an attested revision cannot overwrite',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;

      expect(
        notifier.activateNarrativeEventMapSnapshot(_map(name: 'Snapshot')),
        isTrue,
      );
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Unattested local edit',
        ),
      );
      final beforeBytes = await File(fixture.mapPath).readAsBytes();

      final outcome = await notifier.saveActiveMap();

      expect(outcome, ActiveMapSaveOutcome.conflict);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.errorMessage, contains('recharger'));
      expect(await File(fixture.mapPath).readAsBytes(), beforeBytes);
    });

    test(
        'active-layer tileset assignment is undoable and conflicts only on save',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      expect(notifier.state.activeLayerId, 'base');
      await fixture.writeMap(_map(name: 'External tileset race'));
      final externalBytes = await File(fixture.mapPath).readAsBytes();

      await notifier.assignTilesetToActiveLayer('alternate');

      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.isDirty, isTrue);
      expect(notifier.state.mapUndoStack, hasLength(1));
      expect(notifier.state.activeMap!.layers.first, isA<TileLayer>());
      expect(
        (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
        'alternate',
      );
      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);

      notifier.undoMap();
      expect(
        (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
        'base_tiles',
      );
      notifier.redoMap();
      expect(
        (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
        'alternate',
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.conflict);
      expect(notifier.state.errorMessage, contains('modifiée en dehors'));
      expect(
        (notifier.state.activeMap!.layers.first as TileLayer).tilesetId,
        'alternate',
      );
      expect(await File(fixture.mapPath).readAsBytes(), externalBytes);
    });

    test('active-layer tileset assignment rejects a non-empty layer', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      final map = notifier.state.activeMap!;
      final layer = map.layers.first as TileLayer;
      final occupiedMap = map.copyWith(
        layers: <MapLayer>[
          layer.copyWith(tiles: const <int>[1, 0, 0, 0]),
          ...map.layers.skip(1),
        ],
      );
      notifier.state = notifier.state.copyWith(activeMap: occupiedMap);
      final historyBefore = notifier.state.mapUndoStack;
      final diskBefore = await File(fixture.mapPath).readAsBytes();

      await notifier.assignTilesetToActiveLayer('alternate');

      expect(notifier.state.activeMap, occupiedMap);
      expect(notifier.state.mapUndoStack, historyBefore);
      expect(notifier.state.errorMessage, contains('Videz-la'));
      expect(await File(fixture.mapPath).readAsBytes(), diskBefore);
    });

    test(
        'layer deletion and history transitions activate the matching palette context',
        () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);

      notifier.selectTilesetElementGroupFilter(null);
      notifier.setPaletteCategoryFilter(PaletteCategory.trees);
      notifier.selectPaletteTile(1);
      notifier.setTilesElementsPanelMode(
        TilesElementsPanelMode.placedInstances,
      );
      notifier.addMapLayer(
        kind: MapLayerKind.tile,
        name: 'Details',
        tileTilesetId: 'alternate',
      );
      final detailsLayerId = notifier.state.activeLayerId!;
      notifier.setPaletteCategoryFilter(PaletteCategory.decorations);
      notifier.selectPaletteTile(2);

      notifier.setActiveLayer('base');
      expect(notifier.state.paletteCategoryFilter, PaletteCategory.trees);
      expect(
        notifier.state.tilesElementsPanelMode,
        TilesElementsPanelMode.placedInstances,
      );
      notifier.setActiveLayer(detailsLayerId);
      expect(
        notifier.state.paletteCategoryFilter,
        PaletteCategory.decorations,
      );

      notifier.deleteMapLayer(detailsLayerId);

      expect(notifier.state.activeLayerId, 'base');
      expect(notifier.state.paletteCategoryFilter, PaletteCategory.trees);
      expect(
        notifier.state.tilesElementsPanelMode,
        TilesElementsPanelMode.placedInstances,
      );
      expect(
        notifier.state.paletteSession.contexts.keys,
        isNot(contains(EditorPaletteContextKey(
          mapId: 'alpha',
          layerId: detailsLayerId,
        ))),
      );

      notifier.undoMap();
      expect(notifier.state.activeLayerId, detailsLayerId);
      expect(notifier.getSelectedTilesetEntry()?.id, 'alternate');
      expect(notifier.state.activeBrush, const EditorBrush.none());
      expect(notifier.state.paletteCategoryFilter, isNull);

      notifier.redoMap();
      expect(notifier.state.activeLayerId, 'base');
      expect(notifier.state.paletteCategoryFilter, PaletteCategory.trees);
    });

    test('project replacement clears cached map revisions', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);
      final attestedSnapshot = notifier.state.activeMap!;
      final otherRoot = Directory(p.join(fixture.root.path, 'other_project'));
      await otherRoot.create();
      final otherManifestPath = p.join(otherRoot.path, 'project.json');
      await FileProjectRepository().saveProject(
        const ProjectManifest(
          name: 'Other project',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
        ),
        otherManifestPath,
      );

      expect(
        await notifier.activateProject(otherManifestPath),
        MapActivationOutcome.activated,
      );
      notifier.state = EditorState(
        projectRootPath: fixture.root.path,
        project: fixture.project,
      );
      expect(
        notifier.activateNarrativeEventMapSnapshot(attestedSnapshot),
        isTrue,
      );
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Must stay local',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.conflict);
    });

    test('renaming the active map moves its durable revision', () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;
      await fixture.load(notifier);

      await notifier.renameMap('alpha', 'beta');
      expect(notifier.state.activeMap?.id, 'beta');
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Edited after rename',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      final renamedPath = p.join(fixture.root.path, 'maps', 'beta.json');
      expect(
        (await FileMapRepository().loadMap(renamedPath))
            .mapMetadata
            .displayName,
        'Edited after rename',
      );
    });

    test('newly created map receives a revision for its next save', () async {
      final fixture = await _Fixture.create(projectWithMap: false);
      addTearDown(fixture.dispose);
      final notifier = fixture.notifier;

      await notifier.createMap('alpha', 2, 2);
      expect(notifier.state.activeMap?.id, 'alpha');
      notifier.updateMapMetadata(
        notifier.state.activeMap!.mapMetadata.copyWith(
          displayName: 'Created then edited',
        ),
      );

      expect(await notifier.saveActiveMap(), ActiveMapSaveOutcome.saved);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath))
            .mapMetadata
            .displayName,
        'Created then edited',
      );
    });
  });
}

final class _Fixture {
  _Fixture({
    required this.root,
    required this.project,
    required this.mapPath,
    required this.container,
  });

  static Future<_Fixture> create({bool projectWithMap = true}) async {
    final root =
        await Directory.systemTemp.createTemp('pokemap_map_revision_editor_');
    final mapPath = p.join(root.path, 'maps', 'alpha.json');
    final project = _project(projectWithMap: projectWithMap);
    // DS-05 lifecycle operations journal an exact durable manifest revision.
    // This fixture previously constructed an impossible half-persisted editor
    // session (project only in memory, map on disk), so materialize the same
    // project.json that a real EditorNotifier session is opened from.
    await FileProjectRepository().saveProject(
      project,
      p.join(root.path, 'project.json'),
    );
    if (projectWithMap) {
      await FileMapRepository().saveMap(
        _map(name: 'Baseline'),
        mapPath,
        projectDialogueContext: project,
      );
    }
    final container = ProviderContainer();
    final fixture = _Fixture(
      root: root,
      project: project,
      mapPath: mapPath,
      container: container,
    );
    fixture.notifier.state = EditorState(
      projectRootPath: root.path,
      project: project,
    );
    return fixture;
  }

  final Directory root;
  final ProjectManifest project;
  final String mapPath;
  final ProviderContainer container;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> load(EditorNotifier notifier) async {
    expect(
      await notifier.activateMap('maps/alpha.json'),
      MapActivationOutcome.activated,
    );
  }

  Future<void> writeMap(MapData map) {
    return FileMapRepository().saveMap(
      map,
      mapPath,
      projectDialogueContext: project,
    );
  }

  Future<void> dispose() async {
    container.dispose();
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

ProjectManifest _project({required bool projectWithMap}) => ProjectManifest(
      name: 'DS-03 editor',
      maps: projectWithMap
          ? const <ProjectMapEntry>[
              ProjectMapEntry(
                id: 'alpha',
                name: 'Alpha',
                relativePath: 'maps/alpha.json',
              ),
            ]
          : const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'base_tiles',
          name: 'Base tiles',
          relativePath: 'tilesets/base.png',
          scope: TilesetScope.global,
        ),
        ProjectTilesetEntry(
          id: 'alternate',
          name: 'Alternate',
          relativePath: 'tilesets/alternate.png',
          scope: TilesetScope.global,
        ),
      ],
    );

MapData _map({required String name}) => MapData(
      id: 'alpha',
      name: name,
      version: ProjectVersion.v6,
      size: const GridSize(width: 2, height: 2),
      tilesetId: 'base_tiles',
      layers: const <MapLayer>[
        TileLayer(
          id: 'base',
          name: 'Base',
          tilesetId: 'base_tiles',
          tiles: <int>[0, 0, 0, 0],
        ),
        CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: <bool>[false, false, false, false],
        ),
      ],
    );
