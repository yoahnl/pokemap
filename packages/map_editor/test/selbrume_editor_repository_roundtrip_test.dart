import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/application/map_canvas_object_hit_test.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

const _canonicalMapRelativePaths = <String, String>{
  'map_bourg_selbrume': 'maps/map_bourg_selbrume.json',
  'map_port_brisants': 'maps/map_port_brisants.json',
  'map_bois_chaise_brume': 'maps/map_bois_chaise_brume.json',
  'map_marais_salants': 'maps/map_marais_salants.json',
  'map_passage_dames': 'maps/map_passage_dames.json',
  'map_phare_exterieur': 'maps/map_phare_exterieur.json',
  'map_phare_interieur': 'maps/map_phare_interieur.json',
  'map_sommet_phare': 'maps/map_sommet_phare.json',
  'map_cabane_gardien': 'maps/map_cabane_gardien.json',
  'map_maison_joueur': 'maps/map_maison_joueur.json',
};

const _canonicalDialogueRelativePaths = <String>[
  'dialogues/g.yarn',
  'dialogues/test.yarn',
  'dialogues/lysa_port.yarn',
  'dialogues/lysa_port_after_win.yarn',
  'dialogues/lysa_port_after_loss.yarn',
  'dialogues/mael_intro.yarn',
  'dialogues/port_alert.yarn',
  'dialogues/mado.yarn',
  'dialogues/soline.yarn',
  'dialogues/marais_clues.yarn',
  'dialogues/lighthouse.yarn',
  'dialogues/ending_port.yarn',
  'dialogues/goelise_port.yarn',
  'dialogues/yvon_cabin.yarn',
  'dialogues/mael_after_mission.yarn',
  'dialogues/mael_epilogue.yarn',
  'dialogues/lysa_after_loss.yarn',
  'dialogues/mado_after_crystals.yarn',
  'dialogues/soline_after_passage.yarn',
  'dialogues/soline_epilogue.yarn',
  'dialogues/fisher_after_return.yarn',
  'dialogues/fisher_after_keep.yarn',
  'dialogues/yvon_after_cabin.yarn',
  'dialogues/fisher_epilogue.yarn',
];

final _fixtureRelativePaths = <String>[
  'project.json',
  ..._canonicalMapRelativePaths.values,
  ..._canonicalDialogueRelativePaths,
];

const _canonicalPlacementCounts = <String, int>{
  'map_bourg_selbrume': 84,
  'map_port_brisants': 43,
  'map_bois_chaise_brume': 12,
  'map_marais_salants': 22,
  'map_passage_dames': 13,
  'map_phare_exterieur': 10,
  'map_phare_interieur': 175,
  'map_sommet_phare': 23,
  'map_cabane_gardien': 50,
  'map_maison_joueur': 43,
};

void main() {
  group('Selbrume editor file repositories round-trip', () {
    test(
      'loads, saves, and reloads the canonical manifest and all ten maps '
      'without semantic drift',
      () async {
        final sourceRoot = _resolveSelbrumeSourceRoot();
        final sourceSnapshot = await _snapshotFixtureFiles(sourceRoot);
        final fixture = await _copyRepositoryFixture(sourceRoot);
        _protectSourceAndDeleteFixtureAfterTest(
          sourceRoot: sourceRoot,
          sourceSnapshot: sourceSnapshot,
          fixture: fixture,
        );

        final projectRepository = FileProjectRepository();
        final mapRepository = FileMapRepository();
        final manifestPath = p.join(fixture.root.path, 'project.json');

        final loadedManifest =
            await projectRepository.loadProject(manifestPath);
        expect(
          {
            for (final entry in loadedManifest.maps)
              entry.id: entry.relativePath,
          },
          _canonicalMapRelativePaths,
        );

        final loadedMaps = await _loadCanonicalMaps(
          repository: mapRepository,
          fixtureRoot: fixture.root,
          manifest: loadedManifest,
        );
        expect(loadedMaps, hasLength(_canonicalMapRelativePaths.length));

        // Saving through the real repositories is the editor persistence
        // boundary Task 18 needs to prove. Assets are deliberately not copied:
        // these repositories own JSON validation/serialization and never read
        // referenced raster files while loading or saving a manifest or map.
        for (final entry in loadedManifest.maps) {
          await mapRepository.saveMap(
            loadedMaps[entry.id]!,
            p.join(fixture.root.path, entry.relativePath),
            projectDialogueContext: loadedManifest,
          );
        }
        await projectRepository.saveProject(loadedManifest, manifestPath);

        final reloadedManifest =
            await projectRepository.loadProject(manifestPath);
        final reloadedMaps = await _loadCanonicalMaps(
          repository: mapRepository,
          fixtureRoot: fixture.root,
          manifest: reloadedManifest,
        );

        // Freezed value equality compares the complete typed object graph, so
        // formatting-only JSON changes remain allowed while semantic loss is
        // rejected for both the manifest and every MapData instance.
        expect(reloadedManifest, loadedManifest);
        expect(reloadedMaps, loadedMaps);
        expect(await _snapshotFixtureFiles(sourceRoot), sourceSnapshot);
      },
    );

    test(
      'writes edited values only inside the disposable copy and leaves the '
      'workspace source byte-identical',
      () async {
        final sourceRoot = _resolveSelbrumeSourceRoot();
        final sourceSnapshot = await _snapshotFixtureFiles(sourceRoot);
        final fixture = await _copyRepositoryFixture(sourceRoot);
        _protectSourceAndDeleteFixtureAfterTest(
          sourceRoot: sourceRoot,
          sourceSnapshot: sourceSnapshot,
          fixture: fixture,
        );

        final projectRepository = FileProjectRepository();
        final mapRepository = FileMapRepository();
        final manifestPath = p.join(fixture.root.path, 'project.json');
        final manifest = await projectRepository.loadProject(manifestPath);
        final firstEntry = manifest.maps.singleWhere(
          (entry) => entry.id == 'map_bourg_selbrume',
        );
        final mapPath = p.join(fixture.root.path, firstEntry.relativePath);
        final map = await mapRepository.loadMap(mapPath);

        const temporaryProjectName = 'Selbrume - copie de test uniquement';
        const temporaryMapName = 'Bourg - copie de test uniquement';
        final editedManifest = manifest.copyWith(name: temporaryProjectName);
        final editedMap = map.copyWith(name: temporaryMapName);

        await projectRepository.saveProject(editedManifest, manifestPath);
        await mapRepository.saveMap(
          editedMap,
          mapPath,
          projectDialogueContext: editedManifest,
        );

        expect(
          (await projectRepository.loadProject(manifestPath)).name,
          temporaryProjectName,
        );
        expect((await mapRepository.loadMap(mapPath)).name, temporaryMapName);

        // This guard catches a future path-resolution regression that would
        // redirect editor saves from the fixture back into workspace Selbrume.
        expect(await _snapshotFixtureFiles(sourceRoot), sourceSnapshot);
        expect(
          (await projectRepository.loadProject(
            p.join(sourceRoot.path, 'project.json'),
          ))
              .name,
          isNot(temporaryProjectName),
        );
        expect(
          (await mapRepository.loadMap(
            p.join(sourceRoot.path, firstEntry.relativePath),
          ))
              .name,
          isNot(temporaryMapName),
        );
      },
    );

    test(
      'real EditorNotifier sessions retain all 475 placements after an edit',
      () async {
        final sourceRoot = _resolveSelbrumeSourceRoot();
        final sourceSnapshot = await _snapshotFixtureFiles(sourceRoot);
        final fixture = await _copyRepositoryFixture(sourceRoot);
        _protectSourceAndDeleteFixtureAfterTest(
          sourceRoot: sourceRoot,
          sourceSnapshot: sourceSnapshot,
          fixture: fixture,
        );

        final projectRepository = FileProjectRepository();
        final manifestPath = p.join(fixture.root.path, 'project.json');
        final manifest = await projectRepository.loadProject(manifestPath);

        for (final entry in manifest.maps) {
          final firstSession = ProviderContainer();
          final notifier = firstSession.read(editorNotifierProvider.notifier);
          notifier.state = EditorState(
            projectRootPath: fixture.root.path,
            project: manifest,
          );
          await notifier.loadMap(entry.relativePath);
          final loaded = notifier.state.activeMap!;
          final expectedCount = _canonicalPlacementCounts[entry.id];
          expect(expectedCount, isNotNull, reason: entry.id);
          expect(loaded.placedElements, hasLength(expectedCount!));
          if (entry.id == 'map_port_brisants') {
            _expectPromotedGoeliseNest(loaded);
          }

          final pathLayers = loaded.layers.whereType<PathLayer>().toList();
          if (pathLayers.isNotEmpty) {
            final pathLayer = pathLayers.first;
            notifier.setPathLayerAnimationMode(
              layerId: pathLayer.id,
              mode: pathLayer.animationMode == PathAnimationMode.alwaysActive
                  ? PathAnimationMode.triggered
                  : PathAnimationMode.alwaysActive,
            );
          } else {
            final layer = loaded.layers.first;
            notifier.setMapLayerOpacity(
              layer.id,
              layer.opacity == 1 ? 0.99 : 1,
            );
          }
          await notifier.saveActiveMap();
          expect(notifier.state.errorMessage, isNull, reason: entry.id);
          firstSession.dispose();

          final secondSession = ProviderContainer();
          final verifier = secondSession.read(editorNotifierProvider.notifier);
          verifier.state = EditorState(
            projectRootPath: fixture.root.path,
            project: manifest,
          );
          await verifier.loadMap(entry.relativePath);
          expect(
            verifier.state.activeMap!.placedElements,
            loaded.placedElements,
            reason: entry.id,
          );
          if (entry.id == 'map_port_brisants') {
            _expectPromotedGoeliseNest(verifier.state.activeMap!);
          }
          expect(verifier.state.isDirty, isFalse, reason: entry.id);
          secondSession.dispose();
        }

        expect(
          _canonicalPlacementCounts.values.reduce((a, b) => a + b),
          475,
        );
        expect(await _snapshotFixtureFiles(sourceRoot), sourceSnapshot);
      },
    );

    test(
      'Gate 6 session saves and reopens exact layer collision move and rotation edits',
      () async {
        final sourceRoot = _resolveSelbrumeSourceRoot();
        final sourceSnapshot = await _snapshotFixtureFiles(sourceRoot);
        final fixture = await _copyRepositoryFixture(sourceRoot);
        _protectSourceAndDeleteFixtureAfterTest(
          sourceRoot: sourceRoot,
          sourceSnapshot: sourceSnapshot,
          fixture: fixture,
        );

        const mapId = 'map_port_brisants';
        const collisionLayerId = 'l_collisions';
        const collisionCell = GridPos(x: 6, y: 0);
        const placementId = 'pe_port_rock_small_south_mid';
        const placementLayerId = 'l_tile_port_ref_structures';
        const placementElementId = 'el_port_ref_rock_small';
        const destination = GridPos(x: 12, y: 30);
        final projectPath = p.join(fixture.root.path, 'project.json');
        final firstProjectRepository = FileProjectRepository();
        final manifest = await firstProjectRepository.loadProject(projectPath);
        final mapEntry = manifest.maps.singleWhere(
          (entry) => entry.id == mapId,
        );
        final mapPath = p.join(fixture.root.path, mapEntry.relativePath);

        // The first editor session owns every mutation. Repository-level
        // rewrites would miss the real history/dirty/save transition that this
        // Gate 6 journey is intended to certify.
        final firstSession = ProviderContainer();
        final editor = firstSession.read(editorNotifierProvider.notifier);
        editor.state = EditorState(
          projectRootPath: fixture.root.path,
          project: manifest,
        );
        await editor.loadMap(mapEntry.relativePath);
        final original = editor.state.activeMap!;
        final originalLayerIds = _layerIds(original);
        final originalCollision = _collisionLayer(
          original,
          collisionLayerId,
        ).collisions;
        final collisionIndex =
            collisionCell.y * original.size.width + collisionCell.x;
        expect(originalCollision[collisionIndex], isFalse);
        final originalPlacement = _placedElement(original, placementId);
        expect(originalPlacement.pos, const GridPos(x: 11, y: 31));
        expect(originalPlacement.quarterTurns, 0);

        editor.moveMapLayerGroupUp(collisionLayerId);
        final reorderedLayerIds = _layerIds(editor.state.activeMap!);
        final originalCollisionLayerIndex =
            originalLayerIds.indexOf(collisionLayerId);
        expect(originalCollisionLayerIndex, greaterThan(0));
        expect(
          reorderedLayerIds.indexOf(collisionLayerId),
          originalCollisionLayerIndex - 1,
        );
        expect(
          reorderedLayerIds[originalCollisionLayerIndex],
          originalLayerIds[originalCollisionLayerIndex - 1],
        );

        // Explicit single-tile mode prevents an old palette brush footprint
        // from turning this certification into a multi-cell collision edit.
        editor.setActiveLayer(collisionLayerId);
        editor.setCollisionBrushSizeMode(CollisionBrushSizeMode.singleTile);
        editor.beginMapStroke();
        editor.paintCollisionAt(collisionCell);
        editor.endMapStroke();
        final editedCollision = _collisionLayer(
          editor.state.activeMap!,
          collisionLayerId,
        ).collisions;
        expect(
          <int>[
            for (var index = 0; index < editedCollision.length; index += 1)
              if (editedCollision[index] != originalCollision[index]) index,
          ],
          <int>[collisionIndex],
        );
        expect(editedCollision[collisionIndex], isTrue);

        editor.selectPlacedElementInstance(
          instanceId: placementId,
          elementId: placementElementId,
          layerId: placementLayerId,
        );
        final beforeMove = editor.state.activeMap!;
        final moved = editor.commitCanvasObjectMove(
          sourceMap: beforeMove,
          target: const MapCanvasObjectTarget(
            kind: MapCanvasObjectKind.placedElement,
            id: placementId,
            layerId: placementLayerId,
            anchor: GridPos(x: 11, y: 31),
            size: GridSize(width: 1, height: 1),
          ),
          destinationAnchor: destination,
        );
        expect(moved, isTrue);
        expect(
          editor.setPlacedElementInstanceQuarterTurns(
            instanceId: placementId,
            quarterTurns: 1,
          ),
          isTrue,
        );

        final expected = editor.state.activeMap!;
        expect(editor.state.mapUndoStack, hasLength(4));
        expect(editor.state.isDirty, isTrue);
        expect(_layerIds(expected), reorderedLayerIds);
        expect(_placedElement(expected, placementId).pos, destination);
        expect(_placedElement(expected, placementId).quarterTurns, 1);

        await editor.saveActiveMap();
        expect(editor.state.errorMessage, isNull);
        expect(editor.state.isDirty, isFalse);
        expect(editor.state.savedMapSnapshot, expected);
        firstSession.dispose();

        // Closing the first session is material: both repositories below are
        // fresh instances and therefore cannot satisfy the assertion from an
        // in-memory editor snapshot or repository cache.
        final reopenedProjectRepository = FileProjectRepository();
        final reopenedMapRepository = FileMapRepository();
        final reopenedManifest =
            await reopenedProjectRepository.loadProject(projectPath);
        final repositoryReopen = await reopenedMapRepository.loadMap(mapPath);
        expect(repositoryReopen, expected);

        final secondSession = ProviderContainer();
        addTearDown(secondSession.dispose);
        final reopenedEditor =
            secondSession.read(editorNotifierProvider.notifier);
        reopenedEditor.state = EditorState(
          projectRootPath: fixture.root.path,
          project: reopenedManifest,
        );
        await reopenedEditor.loadMap(mapEntry.relativePath);
        final reopened = reopenedEditor.state.activeMap!;
        expect(reopened, expected);
        expect(reopenedEditor.state.savedMapSnapshot, expected);
        expect(reopenedEditor.state.isDirty, isFalse);
        expect(_layerIds(reopened), reorderedLayerIds);
        expect(
          _collisionLayer(reopened, collisionLayerId).collisions,
          editedCollision,
        );
        expect(_placedElement(reopened, placementId).pos, destination);
        expect(_placedElement(reopened, placementId).quarterTurns, 1);

        // map_runtime's production file loader owns these same shared steps.
        // Repeating that contract here proves the saved document is directly
        // consumable without adding the forbidden map_editor -> map_runtime
        // dependency or substituting a fake runtime.
        final durableJson = jsonDecode(await File(mapPath).readAsString())
            as Map<String, dynamic>;
        final runtimeContractMap =
            MapData.fromJson(migrateMapDataJson(durableJson));
        MapValidator.validate(
          runtimeContractMap,
          projectDialogueContext: reopenedManifest,
        );
        expect(
          buildMapVisualCompositionPlan(runtimeContractMap).canCompose,
          isTrue,
        );
        expect(runtimeContractMap, expected);
        expect(await _snapshotFixtureFiles(sourceRoot), sourceSnapshot);
      },
    );
  });
}

List<String> _layerIds(MapData map) =>
    map.layers.map((layer) => layer.id).toList(growable: false);

CollisionLayer _collisionLayer(MapData map, String id) =>
    map.layers.whereType<CollisionLayer>().singleWhere(
          (layer) => layer.id == id,
        );

MapPlacedElement _placedElement(MapData map, String id) =>
    map.placedElements.singleWhere((placement) => placement.id == id);

void _expectPromotedGoeliseNest(MapData map) {
  expect(
    map.placedElements.map((placement) => placement.id),
    isNot(contains('pe_port_nid_goelise')),
  );
  final nest = map.entities.singleWhere(
    (entity) => entity.id == 'goelise_nest_proxy',
  );
  expect(nest.editorVisual?.elementId, 'el_port_ref_nest');
}

Future<Map<String, MapData>> _loadCanonicalMaps({
  required FileMapRepository repository,
  required Directory fixtureRoot,
  required ProjectManifest manifest,
}) async {
  final maps = <String, MapData>{};
  for (final entry in manifest.maps) {
    final expectedRelativePath = _canonicalMapRelativePaths[entry.id];
    expect(expectedRelativePath, isNotNull,
        reason: 'Unexpected map ${entry.id}');
    expect(entry.relativePath, expectedRelativePath);

    final map = await repository.loadMap(
      p.join(fixtureRoot.path, entry.relativePath),
    );
    expect(map.id, entry.id);
    maps[entry.id] = map;
  }
  return maps;
}

Future<_SelbrumeFixture> _copyRepositoryFixture(Directory sourceRoot) async {
  final temporaryParent = await Directory.systemTemp.createTemp(
    'selbrume_editor_repository_roundtrip_',
  );
  final fixtureRoot = Directory(p.join(temporaryParent.path, 'selbrume'));

  // Copy only the files consumed by the production repositories and the
  // snapshot-aware save path. Keeping this fixture minimal makes the test
  // fast without replacing either persistence boundary with mocks.
  for (final relativePath in _fixtureRelativePaths) {
    final source = File(p.join(sourceRoot.path, relativePath));
    if (!await source.exists()) {
      throw StateError('Missing Selbrume fixture file: ${source.path}');
    }
    final destination = File(p.join(fixtureRoot.path, relativePath));
    await destination.parent.create(recursive: true);
    await source.copy(destination.path);
  }

  return _SelbrumeFixture(
    root: fixtureRoot,
    temporaryParent: temporaryParent,
  );
}

void _protectSourceAndDeleteFixtureAfterTest({
  required Directory sourceRoot,
  required Map<String, List<int>> sourceSnapshot,
  required _SelbrumeFixture fixture,
}) {
  addTearDown(() async {
    // Run the source-integrity assertion even when an earlier expectation
    // fails, so a regression can never hide a write to workspace content.
    try {
      expect(await _snapshotFixtureFiles(sourceRoot), sourceSnapshot);
    } finally {
      if (await fixture.temporaryParent.exists()) {
        await fixture.temporaryParent.delete(recursive: true);
      }
    }
  });
}

Future<Map<String, List<int>>> _snapshotFixtureFiles(Directory root) async {
  return <String, List<int>>{
    for (final relativePath in _fixtureRelativePaths)
      relativePath: await File(p.join(root.path, relativePath)).readAsBytes(),
  };
}

Directory _resolveSelbrumeSourceRoot() {
  var candidate = Directory.current.absolute;
  while (true) {
    final projectFile =
        File(p.join(candidate.path, 'selbrume', 'project.json'));
    final editorPubspec =
        File(p.join(candidate.path, 'packages', 'map_editor', 'pubspec.yaml'));
    if (projectFile.existsSync() && editorPubspec.existsSync()) {
      return Directory(p.join(candidate.path, 'selbrume'));
    }

    final parent = candidate.parent;
    if (parent.path == candidate.path) {
      throw StateError(
        'Could not resolve repository root from ${Directory.current.path}',
      );
    }
    candidate = parent;
  }
}

final class _SelbrumeFixture {
  const _SelbrumeFixture({
    required this.root,
    required this.temporaryParent,
  });

  final Directory root;
  final Directory temporaryParent;
}
