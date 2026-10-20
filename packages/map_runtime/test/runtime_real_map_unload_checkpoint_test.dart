import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';

const _ids = ['a', 'b', 'c', 'd', 'e'];
final _identity = GameIdentity(
  gameId: 'org.example.unload',
  gameVersion: '1.0.0',
  projectFormat: ProjectFormat.v1,
  saveFormat: 1,
  compatibilityId: 'unload-v1',
);
const _profile = RuntimeResourceProfile(
  maximumResidentBytes: 16 * 1024,
  maximumTransientBytes: 32 * 1024,
  maximumConcurrentDecodes: 1,
  maximumEncodedBytes: 1024,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final partitioned in [false, true]) {
    testWidgets(
      'real map eviction preserves pixels and checkpoint, partitioned=$partitioned',
      (tester) async {
        await tester.runAsync(() async {
          final fixture = await _Fixture.create(partitioned);
          final first = await fixture.open(tester, _envelope(_initialState()));
          final observed = _Observed();
          observed.record(first.game);
          final originalLayer = _layers(first.game, 'a').first;
          final originalBundle = originalLayer.bundle;
          final originalImage = originalLayer.tileImagesByTilesetId['a']!;
          final originalPixels = await _pixels(originalImage);
          expect(originalImage.width * originalImage.height * 4, 4096);
          expect(
            first
                .game
                .overworldInteractionSnapshot
                .primaryAction
                ?.request
                .targetId,
            'remember',
          );
          expect(
            first.runtime.handleInput(
              const RuntimeInputEvent.press(RuntimeInputControl.primary),
            ),
            isTrue,
          );
          first.runtime.handleInput(
            const RuntimeInputEvent.release(RuntimeInputControl.primary),
          );
          await _until(
            tester,
            first.game,
            () => _remembered(first.game) && _settled(first.game),
          );

          for (final id in _ids.skip(1)) {
            await _walkToMap(tester, first, id, RuntimeInputControl.right);
            observed.record(first.game);
            _expectBudget(first.game.resourceBudget);
          }
          await _until(
            tester,
            first.game,
            () =>
                !first.game.debugIsMapLoaded('a') &&
                !first.game.debugIsMapLoaded('b') &&
                !originalLayer.isMounted &&
                originalImage.isDisposed,
          );
          expect(_layers(first.game, 'a'), isEmpty);
          expect(_layers(first.game, 'b'), isEmpty);
          expect(_remembered(first.game), isTrue);
          expect(first.game.gameStateSnapshot.trainerProfile.money, 1234);

          for (final id in _ids.reversed.skip(1)) {
            await _walkToMap(tester, first, id, RuntimeInputControl.left);
            observed.record(first.game);
            _expectBudget(first.game.resourceBudget);
          }
          final returned = _layers(first.game, 'a').first;
          final returnedImage = returned.tileImagesByTilesetId['a']!;
          expect(identical(returned.bundle, originalBundle), isFalse);
          expect(identical(returnedImage, originalImage), isFalse);
          expect(await _pixels(returnedImage), originalPixels);
          expect(_remembered(first.game), isTrue);
          expect(first.game.gameStateSnapshot.trainerProfile.money, 1234);
          expect(observed.bundles.length, greaterThanOrEqualTo(6));
          expect(observed.images.length, greaterThanOrEqualTo(6));
          expect(observed.layers.length, greaterThanOrEqualTo(12));
          final checkpoint = await first.runtime.captureCheckpoint();
          expect(checkpoint, isNotNull);
          final saved = gameStateFromStrictSaveJson(checkpoint!.state);
          final savedPosition = saved.playerPosition;
          expect(saved.currentMapId, 'a');
          expect(
            saved.narrativeFactRuntimeState.overridesByFactId['remembered'],
            isTrue,
          );
          await first.runtime.dispose();
          await tester.pump();
          await _until(
            tester,
            first.game,
            () => observed.images.every((image) => image.isDisposed),
          );
          expect(first.budget.residentBytes, 0);
          expect(first.budget.transientBytes, 0);
          expect(first.budget.pendingDecodes, 0);
          expect(observed.layers.every((layer) => !layer.isMounted), isTrue);
          expect(
            RuntimeProjectCatalog.ownerOf(originalBundle.manifest),
            isNull,
          );

          final reopened = await fixture.open(
            tester,
            _envelope(saved, checkpoint: checkpoint),
          );
          final reopenedLayer = _layers(reopened.game, 'a').first;
          expect(reopened.game.gameStateSnapshot.currentMapId, 'a');
          expect(reopened.game.gameStateSnapshot.playerPosition, savedPosition);
          expect(_remembered(reopened.game), isTrue);
          expect(reopened.game.gameStateSnapshot.trainerProfile.money, 1234);
          expect(
            await _pixels(reopenedLayer.tileImagesByTilesetId['a']!),
            originalPixels,
          );
          _expectBudget(reopened.budget);
          expect(await reopened.runtime.captureCheckpoint(), isNotNull);
          stdout.writeln(
            'REAL_MAP_UNLOAD_RESULT=${jsonEncode({
              'partitioned': partitioned,
              'route': ['a', 'b', 'c', 'd', 'e', 'd', 'c', 'b', 'a'],
              'observedBundleInstances': observed.bundles.length,
              'observedImageInstances': observed.images.length,
              'observedLayerInstances': observed.layers.length,
              'budgetPeakBytes': first.budget.peakBytes,
              'firstImageDisposed': originalImage.isDisposed,
              'checkpointReopened': true,
            })}',
          );
        });
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  }
}

List<MapLayersComponent> _layers(PlayableMapGame game, String mapId) => game
    .world
    .children
    .whereType<MapLayersComponent>()
    .where((layer) => layer.bundle.map.id == mapId && layer.isMounted)
    .toList();

bool _remembered(PlayableMapGame game) =>
    game
        .gameStateSnapshot
        .narrativeFactRuntimeState
        .overridesByFactId['remembered'] ==
    true;

bool _settled(PlayableMapGame game) =>
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugHasPendingMapTransition &&
    !game.debugIsPlayerStepping &&
    game.inputAuthoritySnapshot.acceptsOverworldInput &&
    _neighbors(game.gameStateSnapshot.currentMapId)
        .every(game.debugIsMapLoaded) &&
    game.resourceBudget.activeDecodes == 0 &&
    game.resourceBudget.pendingDecodes == 0;

Iterable<String> _neighbors(String mapId) sync* {
  final index = _ids.indexOf(mapId);
  if (index > 0) yield _ids[index - 1];
  if (index >= 0 && index < _ids.length - 1) yield _ids[index + 1];
}

void _expectBudget(RuntimeResourceBudget budget) {
  expect(budget.residentBytes, lessThanOrEqualTo(16 * 1024));
  expect(budget.transientBytes, 0);
  expect(budget.activeDecodes, 0);
  expect(budget.pendingDecodes, 0);
  expect(budget.peakBytes, lessThanOrEqualTo(48 * 1024));
}

Future<void> _until(
  WidgetTester tester,
  PlayableMapGame game,
  bool Function() done,
) async {
  for (var tick = 0; tick < 1600; tick++) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 16));
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Map journey did not settle: ${game.gameStateSnapshot.currentMapId} '
    '${game.gameStateSnapshot.playerPosition} '
    'resident=${game.resourceBudget.residentBytes} '
    'transient=${game.resourceBudget.transientBytes}',
  );
}

Future<void> _walkToMap(
  WidgetTester tester,
  _OpenSession session,
  String target,
  RuntimeInputControl direction,
) async {
  expect(
    session.runtime.handleInput(RuntimeInputEvent.press(direction)),
    isTrue,
  );
  try {
    await _until(
      tester,
      session.game,
      () => session.game.gameStateSnapshot.currentMapId == target,
    );
  } finally {
    session.runtime.handleInput(RuntimeInputEvent.release(direction));
  }
  await _until(tester, session.game, () => _settled(session.game));
}

Future<Uint8List> _pixels(RuntimeTilesetImage image) async {
  final recorder = ui.PictureRecorder();
  image.drawImageRect(
    ui.Canvas(recorder),
    const ui.Rect.fromLTWH(0, 0, 32, 32),
    const ui.Rect.fromLTWH(0, 0, 32, 32),
    ui.Paint(),
  );
  final picture = recorder.endRecording();
  final raster = await picture.toImage(32, 32);
  try {
    final bytes = await raster.toByteData();
    return Uint8List.fromList(bytes!.buffer.asUint8List());
  } finally {
    raster.dispose();
    picture.dispose();
  }
}

GameState _initialState() => const GameState(
  saveId: '00000000-0000-4000-8000-000000000031',
  currentMapId: 'a',
  playerPosition: GridPos(x: 0, y: 1),
  playerFacing: EntityFacing.east,
  trainerProfile: TrainerProfile(name: 'Player', money: 1234),
);

SaveEnvelope _envelope(GameState state, {GameSessionCheckpoint? checkpoint}) =>
    const GameStateSaveEnvelopeMapper().create(
      identity: _identity,
      profileId: 'player',
      slotId: 'slot',
      saveId: state.saveId,
      createdAt: checkpoint?.createdAt ?? DateTime.utc(2026, 10, 20),
      updatedAt: checkpoint?.updatedAt ?? DateTime.utc(2026, 10, 20),
      status: SaveStatus.active,
      playTimeSeconds: checkpoint?.playTimeSeconds ?? 0,
      gameState: state,
    );

final class _Observed {
  final bundles = Set<RuntimeMapBundle>.identity();
  final images = Set<RuntimeTilesetImage>.identity();
  final layers = Set<MapLayersComponent>.identity();

  void record(PlayableMapGame game) {
    for (final layer in game.world.children.whereType<MapLayersComponent>()) {
      if (!layer.isMounted) continue;
      layers.add(layer);
      bundles.add(layer.bundle);
      images.addAll(layer.tileImagesByTilesetId.values);
    }
  }
}

final class _OpenSession {
  const _OpenSession(this.runtime, this.game, this.budget);
  final PlayableMapGameSessionRuntime runtime;
  final PlayableMapGame game;
  final RuntimeResourceBudget budget;
}

final class _Fixture {
  const _Fixture(this.root);
  final Directory root;
  String get projectFile => '${root.path}/project.json';

  static Future<_Fixture> create(bool partitioned) async {
    final root = await Directory.systemTemp.createTemp('real-map-unload-');
    addTearDown(() => root.delete(recursive: true));
    final fixture = _Fixture(root);
    final project = ProjectManifest(
      name: 'Map unload',
      settings: const ProjectSettings(tileWidth: 32, tileHeight: 32),
      maps: [
        for (final id in _ids)
          ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
      ],
      tilesets: [
        for (final id in _ids)
          ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
      ],
      facts: [NarrativeFactDefinition(id: 'remembered', label: 'Remembered')],
      scenes: [_scene()],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.legacyOnly,
        records: const [],
        legacyClaims: const [],
      ),
    );
    await Directory('${root.path}/maps').create();
    for (var index = 0; index < _ids.length; index++) {
      final id = _ids[index];
      final map = MapData(
        id: id,
        name: id,
        tilesetId: id,
        size: const GridSize(width: 4, height: 3),
        layers: [
          MapLayer.tile(
            id: 'ground',
            name: 'Ground',
            palette: [TileLayerPaletteEntry(tilesetId: id, localTileId: 0)],
            cells: List.filled(12, 1),
          ),
          const MapLayer.object(id: 'objects', name: 'Objects'),
        ],
        connections: [
          if (index > 0)
            MapConnection(
              direction: MapConnectionDirection.west,
              targetMapId: _ids[index - 1],
            ),
          if (index < _ids.length - 1)
            MapConnection(
              direction: MapConnectionDirection.east,
              targetMapId: _ids[index + 1],
            ),
        ],
        events: [
          if (index == 0)
            const MapEventDefinition(
              id: 'remember',
              position: EventPosition(layerId: 'objects', x: 1, y: 1),
              pages: [
                MapEventPage(
                  pageNumber: 0,
                  sceneTarget: MapEventSceneTarget(sceneId: 'remember-scene'),
                ),
              ],
            ),
        ],
      );
      await File('${root.path}/maps/$id.json')
          .writeAsString(jsonEncode(map.toJson()));
      final image = img.Image(width: 32, height: 32);
      for (var y = 0; y < 32; y++) {
        for (var x = 0; x < 32; x++) {
          image.setPixelRgba(x, y, 30 + index * 40, 80 + x, 120 + y, 255);
        }
      }
      final bytes = img.encodePng(image);
      expect(bytes.length, lessThanOrEqualTo(1024));
      await File('${root.path}/$id.png').writeAsBytes(bytes);
    }
    if (partitioned) {
      final publication = PortableCatalogPublication.encodeProject(project);
      await File(fixture.projectFile)
          .writeAsString(jsonEncode(publication.descriptor));
      for (final object in publication.storage.objects.entries) {
        final file = File('${root.path}/catalog/objects/${object.key}.json');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(object.value);
      }
    } else {
      await File(fixture.projectFile)
          .writeAsString(jsonEncode(project.toJson()));
    }
    return fixture;
  }

  Future<_OpenSession> open(WidgetTester tester, SaveEnvelope save) async {
    final catalog = await RuntimeProjectCatalog.open(projectFile);
    final budget = RuntimeResourceBudget(profile: _profile);
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile,
      projectCatalog: catalog,
      resourceBudget: budget,
      mapId: save.state['currentMapId']! as String,
    );
    late PlayableMapGame game;
    final runtime = PlayableMapGameSessionRuntime(
      descriptor: GameSessionDescriptor(
        sessionId: 'unload-session',
        sessionToken: 'secret',
        identity: _identity,
        profileId: 'player',
        slotId: 'slot',
        launchMode: GameSessionLaunchMode.continueGame,
        installedVersionHandle: 'fixture',
        saveReadHandle: 'save',
        runtimeApiVersion: '1.0.0',
        grantedCapabilities: const {'map.v1'},
        locale: 'fr-FR',
        accessibility: const GameSessionAccessibilityOptions(),
      ),
      projectFilePath: () async => projectFile,
      initialSave: () async => save,
      preloadedInitialMap: ({
        required projectFilePath,
        required descriptor,
        required initialSave,
      }) async => RuntimeInitialMapPreloadResult(bundle: bundle),
      mountGame: (mounted) async {
        game = mounted;
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Center(
              child: SizedBox(
                width: 160,
                height: 96,
                child: GameWidget(game: game),
              ),
            ),
          ),
        );
        await game.loaded;
        await tester.pump();
      },
      unmountGame: (_) async => tester.pumpWidget(const SizedBox.shrink()),
    );
    addTearDown(runtime.dispose);
    await runtime.load((_) {});
    await runtime.resume();
    await _until(tester, game, () => _settled(game));
    return _OpenSession(runtime, game, budget);
  }
}

SceneAsset _scene() => SceneAsset(
  id: 'remember-scene',
  name: 'Remember',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'set',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(factId: 'remembered', value: true),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'start-set',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'set',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'set-end',
        fromNodeId: 'set',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);
