import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const audioEvents = MethodChannel('xyz.luan/audioplayers.global/events');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEvents, (call) async {
      if (call.method != 'listen' && call.method != 'cancel') {
        throw UnsupportedError(call.method);
      }
      return null;
    });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioEvents, null);
  });
  final referencePath = Platform.environment['AVELUNE_LOT6_KANTO_REFERENCE'];
  final fullReference = referencePath != null &&
      (jsonDecode(File(referencePath).readAsStringSync()) as Map)['contentScope'] == 'full';
  testWidgets(
    'published full Kanto world preview walks from authored Route 9 spawn and persists across disk reload',
    (tester) async {
      await tester.runAsync(() async {
        final delivery = Map<String, dynamic>.from(
          jsonDecode(await File(referencePath!).readAsString()) as Map,
        );
        final contentScope = delivery['contentScope'];
        expect(contentScope, isIn(['world', 'full']));
        final worldOnly = contentScope == 'world';
        expect(delivery['kind'], worldOnly
            ? 'kantoWorldFoundationDelivery'
            : 'fullKantoCanonicalConverterDelivery');
        expect(delivery['phase'], 'published');
        expect(delivery['published'], isTrue);
        expect(delivery['verified'], isTrue);
        expect(delivery['sourceUnchanged'], isTrue);
        expect(delivery['sourceScriptsExecuted'], 0);
        expect(delivery['aiSourceInferenceCalls'], 0);
        expect(delivery['mapCount'], 383);
        final projectRoot = delivery['projectPath'] as String;
        expect(path.isAbsolute(projectRoot), isTrue);
        expect(
          await Directory(projectRoot).resolveSymbolicLinks(),
          projectRoot,
        );
        final projectFile = path.join(projectRoot, 'project.json');
        final manifestHash = await _hash(projectFile);
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(383));
        expect(manifest.maps.map((map) => map.id).toSet(), hasLength(383));
        if (worldOnly) {
          expect(manifest.scenes, isEmpty);
          expect(manifest.trainers, isEmpty);
          expect(manifest.encounterTables, isEmpty);
        }
        expect(
          manifest.newGame.enabled,
          isFalse,
          reason: 'lot6.world_preview_only: this qualification does not certify the absent source new-game entrypoint.',
        );
        final previewEntries = manifest.maps
            .where((map) => map.name == 'Route 9')
            .toList();
        expect(
          previewEntries,
          hasLength(1),
          reason: 'lot6.world_preview.route_9_not_unique',
        );
        final entry = previewEntries.single;
        final mapId = entry.id;
        final mapFile = path.join(projectRoot, entry.relativePath);
        final mapHash = await _hash(mapFile);
        final readMapHashes = <String, String>{mapFile: mapHash};
        final firstBundle = await loadRuntimeMapBundle(
          projectFilePath: projectFile,
          mapId: mapId,
        );
        final spawn = resolveInitialPlayerSpawn(
          firstBundle.map,
          tileWidthPx: manifest.settings.tileWidth,
          tileHeightPx: manifest.settings.tileHeight,
        );
        final saveRoot = await Directory.systemTemp.createTemp(
          'lot6-full-kanto-save-',
        );
        final savePath = path.join(saveRoot.path, 'save.json');
        Map<String, Object?> excursionProof = const {
          'connectionVerified': false,
          'centerDoorRoundTripVerified': false,
        };
        PlayableMapGame? game;
        try {
          game = await _start(
            tester,
            firstBundle,
            projectFile,
            _DiskSave(savePath),
          );
          expect(game.gameStateSnapshot.currentMapId, mapId);
          expect(game.debugPlayerGridPosition, spawn.pos);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          final moved = await _walkOneCell(game, firstBundle);
          expect(moved, isNot(spawn.pos));
          expect(game.gameStateSnapshot.currentMapId, mapId);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          excursionProof = worldOnly
              ? await _tryWorldConnection(game, firstBundle, manifest, projectFile, readMapHashes)
              : await _tryCenterExcursion(
            game,
            firstBundle,
            manifest,
            referencePath,
            projectFile,
            readMapHashes,
          );
          final savedMapId = game.gameStateSnapshot.currentMapId;
          final savedPosition = game.debugPlayerGridPosition;
          expect(await game.saveGame(), isTrue);
          final saved = (await _DiskSave(savePath).load())!;
          expect(saved.currentMapId, savedMapId);
          expect(saved.playerPosition, savedPosition);
          expect(
            saved.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
            isEmpty,
          );
          final savedFacts = saved.narrativeFactRuntimeState;
          game.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          game = null;
          final reloadedBundle = await loadRuntimeMapBundle(
            projectFilePath: projectFile,
            mapId: mapId,
          );
          expect(identical(firstBundle, reloadedBundle), isFalse);
          expect(reloadedBundle.manifest.maps, hasLength(383));
          game = await _start(
            tester,
            reloadedBundle,
            projectFile,
            _DiskSave(savePath),
          );
          expect(await game.loadGame(), isTrue);
          await _waitUntil(game, () => _idle(game!));
          expect(game.gameStateSnapshot.currentMapId, savedMapId);
          expect(game.debugPlayerGridPosition, savedPosition);
          expect(game.gameStateSnapshot.narrativeFactRuntimeState, savedFacts);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
          await _ticks(game, 30);
          expect(game.debugPlayerGridPosition, savedPosition);
          final activeBundle = savedMapId == mapId
              ? reloadedBundle
              : await loadRuntimeMapBundle(
                  projectFilePath: projectFile,
                  mapId: savedMapId,
                );
          final afterReload = await _walkOneCell(game, activeBundle);
          expect(afterReload, isNot(savedPosition));
          expect(game.gameStateSnapshot.currentMapId, savedMapId);
          expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
        } finally {
          game?.onRemove();
          await tester.pumpWidget(const SizedBox.shrink());
          await saveRoot.delete(recursive: true);
        }
        expect(await _hash(projectFile), manifestHash);
        expect(await _hash(mapFile), mapHash);
        for (final read in readMapHashes.entries) {
          expect(await _hash(read.key), read.value);
        }
        stdout.writeln(
          jsonEncode({
            'kind': 'lot6FullKantoWorldPreviewRuntimeProof',
            'contentScope': contentScope,
            'mapCount': manifest.maps.length,
            'previewMapId': mapId,
            'previewMapName': entry.name,
            'authoredPreviewSpawn': spawn.pos.toJson(),
            'publicMovementVerified': true,
            'saveAndNewInstanceReloadVerified': true,
            'projectAndActiveMapUnchanged': true,
            'readMapFilesUnchanged': readMapHashes.length,
            'excursion': excursionProof,
            'lot6NativeStartCertified': false,
            'fullCampaignCertified': false,
            'sourceScriptsExecuted': 0,
          }),
        );
      });
    },
    skip: referencePath == null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
  testWidgets('published full Kanto house stairs change floors within Map007',
      (tester) async {
    await tester.runAsync(() async {
      final delivery = jsonDecode(await File(referencePath!).readAsString()) as Map;
      expect(delivery['kind'], 'fullKantoCanonicalConverterDelivery');
      expect(delivery['contentScope'], 'full');
      expect(delivery['phase'], 'published');
      expect(delivery['published'], isTrue);
      expect(delivery['verified'], isTrue);
      expect(delivery['sourceUnchanged'], isTrue);
      expect(delivery['sourceScriptsExecuted'], 0);
      final projectRoot = delivery['projectPath'] as String;
      expect(path.isAbsolute(projectRoot), isTrue);
      expect(await Directory(projectRoot).resolveSymbolicLinks(), projectRoot);
      final projectFile = path.join(projectRoot, 'project.json');
      final projectHash = await _hash(projectFile);
      final manifest = await loadProjectManifestFromFile(projectFile);
      final rows = await _qualifiedEventRows(referencePath, delivery);
      final stairsUp = _qualifiedDoor(manifest, rows, 7, 2);
      final stairsDown = _qualifiedDoor(manifest, rows, 7, 3);
      final mapId = stairsUp.source['mapId'] as String;
      expect(stairsDown.source['mapId'], mapId);
      expect(stairsUp.command.destinationMapId, mapId);
      expect(stairsDown.command.destinationMapId, mapId);
      final exit = rows.singleWhere((row) =>
          (row['locator'] as Map)['mapId'] == 7 &&
          (row['locator'] as Map)['eventId'] == 1);
      final bundle = await loadRuntimeMapBundle(projectFilePath: projectFile, mapId: mapId);
      expect(bundle.map.size, const GridSize(width: 40, height: 20));
      expect(_doorPosition(stairsUp, bundle.map), const GridPos(x: 12, y: 4));
      expect(_doorPosition(stairsDown, bundle.map), const GridPos(x: 30, y: 4));
      final arrivals = {
        'up': bundle.map.warps.singleWhere((warp) => warp.id == stairsUp.command.warpId).pos,
        'down': bundle.map.warps.singleWhere((warp) => warp.id == stairsDown.command.warpId).pos,
      };
      expect(arrivals['up'], const GridPos(x: 31, y: 4));
      expect(arrivals['down'], const GridPos(x: 11, y: 4));
      final mapFile = path.join(projectRoot,
          manifest.maps.singleWhere((entry) => entry.id == mapId).relativePath);
      final mapHash = await _hash(mapFile);
      final spawn = resolveInitialPlayerSpawn(bundle.map,
          tileWidthPx: manifest.settings.tileWidth,
          tileHeightPx: manifest.settings.tileHeight);
      final saveRoot = await Directory.systemTemp.createTemp('lot6-full-stairs-save-');
      PlayableMapGame? game;
      final verified = <String>[];
      var publicInputs = 0;
      try {
        game = await _start(tester, bundle, projectFile,
            _DiskSave(path.join(saveRoot.path, 'save.json')));
        expect(game.debugPlayerGridPosition, spawn.pos);
        expect(game.gameStateSnapshot.currentMapId, mapId);
        final stairs = {'up': stairsUp, 'down': stairsDown};
        while (verified.length < 2) {
          final world = _worldFor(game, bundle.map, manifest);
          var activated = false;
          for (final entry in stairs.entries) {
            if (verified.contains(entry.key)) continue;
            final approaches = _approaches(entry.value, bundle.map, world);
            final route = _pathTo(world, game.debugPlayerGridPosition, approaches.keys.toSet());
            if (route == null) continue;
            await _followPath(game, bundle, route);
            final before = game.debugPlayerGridPosition;
            await _activateDoor(game, approaches[before]!, entry.value,
                expectedPosition: arrivals[entry.key]);
            expect(game.gameStateSnapshot.currentMapId, mapId);
            expect(game.debugPlayerGridPosition, arrivals[entry.key]);
            expect(game.debugPlayerGridPosition, isNot(before));
            verified.add(entry.key);
            publicInputs += route.length + 1;
            activated = true;
            break;
          }
          expect(activated, isTrue,
              reason: 'lot6.stairs.no_safe_public_route: map=$mapId position=${game.debugPlayerGridPosition} verified=$verified');
        }
        expect(verified.toSet(), {'up', 'down'});
      } finally {
        game?.onRemove();
        await tester.pumpWidget(const SizedBox.shrink());
        await saveRoot.delete(recursive: true);
      }
      expect(await _hash(projectFile), projectHash);
      expect(await _hash(mapFile), mapHash);
      stdout.writeln(jsonEncode({
        'kind': 'lot6FullKantoIntramapStairsRuntimeProof', 'contentScope': 'full',
        'sourceMapId': 7, 'mapId': mapId, 'mapSize': {'width': 40, 'height': 20},
        'authoredPreviewSpawn': spawn.pos.toJson(), 'stairsUpVerified': true,
        'stairsDownVerified': true, 'stairsOrder': verified,
        'sameMapFloorTransferVerified': true, 'publicCardinalInputs': publicInputs,
        'projectAndMapUnchanged': true, 'houseExitCertified': false,
        'houseExitObservedQualification': exit['status'],
        'lot6NativeStartCertified': false, 'fullCampaignCertified': false,
        'sourceScriptsExecuted': 0,
      }));
    });
  }, skip: !fullReference, timeout: const Timeout(Duration(minutes: 3)));
}

Future<PlayableMapGame> _start(
  WidgetTester tester,
  RuntimeMapBundle bundle,
  String projectFile,
  FileGameSaveRepository repository,
) async {
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: repository,
  );
  game.onGameResize(Vector2(320, 240));
  game.setDialogueFlutterOverlayPreferred(true);
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: GameWidget<PlayableMapGame>(game: game),
    ),
  );
  await game.toBeLoaded();
  await game.ready();
  game.pauseEngine();
  await _waitUntil(
    game,
    () =>
        game.debugCompletedMapActivationDispatchCount > 0 &&
        _idle(game) &&
        game.inputAuthoritySnapshot.acceptsOverworldInput,
  );
  await _ticks(game, 2);
  await _waitUntil(game, () => _idle(game));
  return game;
}

Future<GridPos> _walkOneCell(
  PlayableMapGame game,
  RuntimeMapBundle bundle,
) async {
  final before = game.debugPlayerGridPosition;
  final renderedBefore = game.debugPlayerWorldTopLeft;
  final world = GameplayWorldState.initial(
    map: bundle.map,
    playerPos: before,
    project: bundle.manifest,
    gameState: game.gameStateSnapshot,
    tileWidth: bundle.manifest.settings.tileWidth,
    tileHeight: bundle.manifest.settings.tileHeight,
  );
  final attempts = <Map<String, Object?>>[];
  for (final (control, direction) in const [
    (RuntimeInputControl.right, Direction.east),
    (RuntimeInputControl.down, Direction.south),
    (RuntimeInputControl.left, Direction.west),
    (RuntimeInputControl.up, Direction.north),
  ]) {
    final target = GridPos(
      x: before.x + direction.dx,
      y: before.y + direction.dy,
    );
    final exclusions = <String>[
      if (world.isBlocked(target.x, target.y)) 'nativeCollisionOrTerrain',
      if (world.isWaterCell(target.x, target.y)) 'water',
      if (bundle.map.gameplayZones.any(
        (zone) =>
            zone.kind == GameplayZoneKind.encounter &&
            gameplayZoneContainsPosition(zone, target),
      ))
        'encounterZone',
      if (bundle.map.warps.any(
        (warp) =>
            target.x >= warp.pos.x - warp.triggerPadding.left &&
            target.x <= warp.pos.x + warp.triggerPadding.right &&
            target.y >= warp.pos.y - warp.triggerPadding.top &&
            target.y <= warp.pos.y + warp.triggerPadding.bottom,
      ))
        'warp',
      if (bundle.map.triggers.any((trigger) => _contains(trigger.area, target)))
        'trigger',
      if (bundle.map.entities.any(
        (entity) =>
            entity.kind != MapEntityKind.spawn &&
            target.x >= entity.pos.x &&
            target.x < entity.pos.x + entity.size.width &&
            target.y >= entity.pos.y &&
            target.y < entity.pos.y + entity.size.height,
      ))
        'entity',
      if (_trainerSees(world, target)) 'trainerLineOfSight',
    ];
    if (exclusions.isNotEmpty) {
      attempts.add({
        'direction': direction.name,
        'target': target.toJson(),
        'exclusions': exclusions,
      });
      continue;
    }
    expect(
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
      isTrue,
    );
    try {
      for (var tick = 0; tick < 50; tick++) {
        if (game.debugPlayerGridPosition != before) break;
        expect(game.gameStateSnapshot.currentMapId, bundle.map.id);
        expect(game.dialoguePresentationListenable.value, isNull);
        game.update(0.016);
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    } finally {
      game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
    }
    await _waitUntil(game, () => !game.debugIsPlayerStepping && _idle(game));
    if (game.debugPlayerGridPosition == before) {
      attempts.add({
        'direction': direction.name,
        'target': target.toJson(),
        'publicInputResult': 'noCommittedStep',
      });
      continue;
    }
    expect(game.debugPlayerGridPosition, target);
    expect(
      game.debugPlayerWorldTopLeft.x,
      closeTo(
        renderedBefore.x + direction.dx * bundle.cellWidth,
        0.001,
      ),
    );
    expect(
      game.debugPlayerWorldTopLeft.y,
      closeTo(
        renderedBefore.y + direction.dy * bundle.cellHeight,
        0.001,
      ),
    );
    expect(game.gameStateSnapshot.currentMapId, bundle.map.id);
    return target;
  }
  fail(
    'No safe public cardinal step from the authored preview/current position $before '
    'on ${bundle.map.id}: ${jsonEncode(attempts)}',
  );
}

bool _contains(MapRect rect, GridPos pos) =>
    pos.x >= rect.pos.x &&
    pos.x < rect.pos.x + rect.size.width &&
    pos.y >= rect.pos.y &&
    pos.y < rect.pos.y + rect.size.height;

const _cardinals = <(RuntimeInputControl, Direction, MapConnectionDirection)>[
  (RuntimeInputControl.right, Direction.east, MapConnectionDirection.east),
  (RuntimeInputControl.down, Direction.south, MapConnectionDirection.south),
  (RuntimeInputControl.left, Direction.west, MapConnectionDirection.west),
  (RuntimeInputControl.up, Direction.north, MapConnectionDirection.north),
];

Future<Map<String, Object?>> _tryWorldConnection(
  PlayableMapGame game,
  RuntimeMapBundle initial,
  ProjectManifest manifest,
  String projectFile,
  Map<String, String> readMapHashes,
) async {
  final initialWorld = _worldFor(game, initial.map, manifest);
  final diagnostics = <Map<String, Object?>>[];
  for (final connection in initial.map.connections) {
    final entry = manifest.maps.singleWhere(
        (entry) => entry.id == connection.targetMapId);
    final file = path.join(path.dirname(projectFile), entry.relativePath);
    readMapHashes[file] = await _hash(file);
    final outside = await loadMapDataFromFile(file,
        projectDialogueContext: manifest);
    final outsideWorld = _worldFor(game, outside, manifest);
    final sizes = {initial.map.id: initial.map.size, outside.id: outside.size};
    final arrivals = <GridPos, GridPos>{};
    for (var y = 0; y < initial.map.size.height; y++) {
      for (var x = 0; x < initial.map.size.width; x++) {
        final border = GridPos(x: x, y: y);
        if (resolveMapConnectionForPosition(map: initial.map,
            sourcePos: border, direction: connection.direction,
            targetMapSizes: sizes) != connection) {
          continue;
        }
        final arrival = resolveConnectedMapTargetPos(sourcePos: border,
            sourceSize: initial.map.size, targetSize: outside.size,
            direction: connection.direction, offset: connection.offset);
        if (arrival != null && _safeCell(outsideWorld, arrival)) {
          arrivals[border] = arrival;
        }
      }
    }
    final search = <String, Object?>{};
    final route = _pathTo(initialWorld, game.debugPlayerGridPosition,
        arrivals.keys.toSet(), diagnostics: search);
    if (route == null) {
      diagnostics.add({'targetMapId': outside.id,
        'direction': connection.direction.name,
        'safeArrivalCount': arrivals.length, ...search});
      continue;
    }
    final border = _endOf(game.debugPlayerGridPosition, route);
    final direction = _cardinals.singleWhere(
        (entry) => entry.$3 == connection.direction).$2;
    await _followPath(game, initial, route);
    await _publicStep(game, direction, outside.id,
        expectedPosition: arrivals[border]);
    expect(game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.connection);
    final reverse = switch (direction) {
      Direction.north => Direction.south,
      Direction.south => Direction.north,
      Direction.east => Direction.west,
      Direction.west => Direction.east,
    };
    await _publicStep(game, reverse, initial.map.id,
        expectedPosition: border);
    expect(game.debugLastCompletedMapActivation?.reason,
        MapActivationReason.connection);
    return {
      'connectionVerified': true,
      'connectionRoundTripVerified': true,
      'centerDoorRoundTripVerified': false,
      'fromMapId': initial.map.id,
      'outsideMapId': outside.id,
      'publicCardinalSteps': route.length + 2,
      'doorsPendingInteractionStage': true,
    };
  }
  return {
    'connectionVerified': false,
    'centerDoorRoundTripVerified': false,
    'limitedProof': 'No safe connection route; movement and save/reload only.',
    'diagnostics': diagnostics,
  };
}

Future<Map<String, Object?>> _tryCenterExcursion(
  PlayableMapGame game,
  RuntimeMapBundle initial,
  ProjectManifest manifest,
  String referencePath,
  String projectFile,
  Map<String, String> readMapHashes,
) async {
  final delivery = jsonDecode(await File(referencePath).readAsString()) as Map;
  final rows = await _qualifiedEventRows(referencePath, delivery);
  final maps = <String, MapData>{initial.map.id: initial.map};
  Future<MapData> readMap(String id) async {
    if (maps.containsKey(id)) return maps[id]!;
    final entry = manifest.maps.singleWhere((entry) => entry.id == id);
    final file = path.join(path.dirname(projectFile), entry.relativePath);
    readMapHashes[file] = await _hash(file);
    return maps[id] = await loadMapDataFromFile(
      file,
      projectDialogueContext: manifest,
    );
  }

  _Door door(int sourceMapId, int sourceEventId) =>
      _qualifiedDoor(manifest, rows, sourceMapId, sourceEventId);

  for (final connection in initial.map.connections) {
    await readMap(connection.targetMapId);
  }
  final diagnostics = <Map<String, Object?>>[];
  for (final (outsideSource, outsideEvent, insideSource) in const [
    (21, 1, 22),
    (100, 8, 102),
  ]) {
    final entrance = door(outsideSource, outsideEvent);
    final exit = door(insideSource, 1);
    final outsideId = entrance.source['mapId'] as String;
    final insideId = exit.source['mapId'] as String;
    expect(entrance.command.destinationMapId, insideId);
    expect(exit.command.destinationMapId, outsideId);
    final connections = initial.map.connections
        .where((connection) => connection.targetMapId == outsideId)
        .toList();
    if (connections.length != 1) {
      diagnostics.add({
        'sourceMapId': outsideSource,
        'reason': 'noUniqueDirectConnection',
      });
      continue;
    }
    final connection = connections.single;
    final outside = await readMap(outsideId);
    final inside = await readMap(insideId);
    final initialWorld = _worldFor(game, initial.map, manifest);
    final outsideWorld = _worldFor(game, outside, manifest);
    final insideWorld = _worldFor(game, inside, manifest);
    final borderArrivals = <GridPos, GridPos>{};
    final targetSizes = {for (final map in maps.values) map.id: map.size};
    for (var y = 0; y < initial.map.size.height; y++) {
      for (var x = 0; x < initial.map.size.width; x++) {
        final border = GridPos(x: x, y: y);
        if (resolveMapConnectionForPosition(
              map: initial.map,
              sourcePos: border,
              direction: connection.direction,
              targetMapSizes: targetSizes,
            ) !=
            connection) {
          continue;
        }
        final arrival = resolveConnectedMapTargetPos(
          sourcePos: border,
          sourceSize: initial.map.size,
          targetSize: outside.size,
          direction: connection.direction,
          offset: connection.offset,
        );
        if (arrival != null && _safeCell(outsideWorld, arrival)) {
          borderArrivals[border] = arrival;
        }
      }
    }
    final entranceApproaches = _approaches(entrance, outside, outsideWorld);
    final outsidePaths = <GridPos, List<(Direction, GridPos)>>{};
    final toBorder = _pathTo(
      initialWorld,
      game.debugPlayerGridPosition,
      borderArrivals.keys.toSet(),
      acceptsGoal: (border) {
        final continuation = _pathTo(
          outsideWorld,
          borderArrivals[border]!,
          entranceApproaches.keys.toSet(),
        );
        if (continuation == null) {
          return false;
        }
        outsidePaths[border] = continuation;
        return true;
      },
    );
    final border = toBorder == null
        ? null
        : _endOf(game.debugPlayerGridPosition, toBorder);
    final arrival = border == null ? null : borderArrivals[border];
    final toEntrance = border == null ? null : outsidePaths[border];
    final insideArrival = inside.warps
        .singleWhere((warp) => warp.id == entrance.command.warpId)
        .pos;
    final exitApproaches = _approaches(exit, inside, insideWorld);
    final toExit = _safeCell(insideWorld, insideArrival)
        ? _pathTo(insideWorld, insideArrival, exitApproaches.keys.toSet())
        : null;
    final steps =
        (toBorder?.length ?? 513) +
        (toEntrance?.length ?? 513) +
        (toExit?.length ?? 513) +
        3;
    if (toBorder == null ||
        toEntrance == null ||
        toExit == null ||
        steps > 512) {
      diagnostics.add({
        'sourceMapId': outsideSource,
        'reason': 'noSafeBoundedRoute',
        'safeArrivalBorderCandidates': borderArrivals.length,
        'toBorderSteps': toBorder?.length,
        'toEntranceSteps': toEntrance?.length,
        'toExitSteps': toExit?.length,
        'maximumSteps': 512,
      });
      continue;
    }
    await _followPath(game, initial, toBorder);
    final crossing = _cardinals
        .singleWhere((entry) => entry.$3 == connection.direction)
        .$2;
    await _publicStep(game, crossing, outsideId, expectedPosition: arrival);
    expect(
      game.debugLastCompletedMapActivation?.reason,
      MapActivationReason.connection,
    );
    final outsideBundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile,
      mapId: outsideId,
    );
    await _followPath(game, outsideBundle, toEntrance);
    await _activateDoor(
      game,
      entranceApproaches[game.debugPlayerGridPosition]!,
      entrance,
    );
    expect(game.debugPlayerGridPosition, insideArrival);
    final insideBundle = await loadRuntimeMapBundle(
      projectFilePath: projectFile,
      mapId: insideId,
    );
    await _followPath(game, insideBundle, toExit);
    await _activateDoor(
      game,
      exitApproaches[game.debugPlayerGridPosition]!,
      exit,
    );
    return {
      'connectionVerified': true,
      'centerDoorRoundTripVerified': true,
      'fromMapId': initial.map.id,
      'outsideMapId': outsideId,
      'insideMapId': insideId,
      'entranceEventId': entrance.eventId,
      'exitEventId': exit.eventId,
      'publicCardinalSteps': steps,
      'returnPosition': game.debugPlayerGridPosition.toJson(),
    };
  }
  return {
    'connectionVerified': false,
    'centerDoorRoundTripVerified': false,
    'limitedProof': 'No safe complete route selected; only preview movement and save/reload are qualified.',
    'diagnostics': diagnostics,
  };
}

final class _Door {
  const _Door(this.eventId, this.source, this.command);
  final String eventId;
  final Map<String, Object?> source;
  final SceneWarpInteractiveCommand command;
}

Future<List<Map>> _qualifiedEventRows(String referencePath, Map delivery) async {
  final qualification = jsonDecode(await File(path.join(path.dirname(referencePath),
      'source-event-qualification.json')).readAsString()) as Map;
  expect(qualification['kind'], 'fullKantoSourceEventQualification');
  expect(qualification['sourceSnapshotHash'], delivery['snapshotHash']);
  expect(qualification['nativeDraftHash'], delivery['nativeDraftHash']);
  return (qualification['events'] as List).cast<Map>();
}

_Door _qualifiedDoor(ProjectManifest manifest, List<Map> rows,
    int sourceMapId, int sourceEventId) {
  final row = rows.singleWhere((row) {
    final locator = row['locator'] as Map;
    return locator['mapId'] == sourceMapId && locator['eventId'] == sourceEventId;
  });
  expect(row['status'], 'adaptedStaticSemantics');
  expect(row['gaps'], isEmpty);
  final page = (row['pages'] as List).cast<Map>()
      .singleWhere((page) => page['originalPageIndex'] == 0);
  final record = manifest.eventRegistry!.records
      .singleWhere((record) => record.id == page['nativeEventId']);
  expect(record.enabledOrNull, isTrue);
  final definition = record.definitionOrNull!;
  final source = definition.source.toJson();
  expect(source['kind'], isIn(['entityBump', 'triggerEnter', 'triggerBump']));
  final scene = manifest.scenes.singleWhere((scene) => scene.id == definition.sceneId);
  final commands = scene.graph.nodes.map((node) => node.payload)
      .whereType<SceneActionPayload>().map((payload) => payload.interactiveCommand)
      .whereType<SceneWarpInteractiveCommand>().toList();
  expect(commands, hasLength(1));
  return _Door(record.id, source, commands.single);
}

GameplayWorldState _worldFor(
  PlayableMapGame game,
  MapData map,
  ProjectManifest manifest,
) => GameplayWorldState.initial(
  map: map,
  playerPos: game.debugPlayerGridPosition,
  project: manifest,
  gameState: game.gameStateSnapshot,
  tileWidth: manifest.settings.tileWidth,
  tileHeight: manifest.settings.tileHeight,
);

bool _trainerSees(GameplayWorldState world, GridPos position) =>
    world.map.entities.any((entity) {
      final npc = entity.npc;
      return npc != null &&
          (npc.trainerId?.isNotEmpty ?? false) &&
          checkLineOfSight(
            npcPos: entity.pos,
            npcFacing: npc.facing,
            lineOfSightRange: npc.lineOfSightRange,
            playerPos: position,
            world: world,
          );
    });

bool _safeCell(GameplayWorldState world, GridPos position) {
  return !world.isBlocked(position.x, position.y) && _safeActivities(world, position);
}

bool _safeActivities(GameplayWorldState world, GridPos position) {
  if (world.isWaterCell(position.x, position.y) ||
      _trainerSees(world, position)) {
    return false;
  }
  final map = world.map;
  if (map.gameplayZones.any(
    (zone) =>
        const {
          GameplayZoneKind.encounter,
          GameplayZoneKind.movementEffect,
          GameplayZoneKind.hazard,
          GameplayZoneKind.special,
          GameplayZoneKind.custom,
        }.contains(zone.kind) &&
        gameplayZoneContainsPosition(zone, position),
  )) {
    return false;
  }
  if (map.triggers.any((trigger) => _contains(trigger.area, position))) {
    return false;
  }
  if (map.warps.any(
    (warp) =>
        warp.triggerMode != MapWarpTriggerMode.sceneOnly &&
        position.x >= warp.pos.x - warp.triggerPadding.left &&
        position.x <= warp.pos.x + warp.triggerPadding.right &&
        position.y >= warp.pos.y - warp.triggerPadding.top &&
        position.y <= warp.pos.y + warp.triggerPadding.bottom,
  )) {
    return false;
  }
  return !map.entities.any(
    (entity) =>
        entity.kind != MapEntityKind.spawn &&
        _contains(MapRect(pos: entity.pos, size: entity.size), position),
  );
}

Map<GridPos, Direction> _approaches(
  _Door door,
  MapData map,
  GameplayWorldState world,
) {
  final position = _doorPosition(door, map);
  return {
    for (final (_, direction, _) in _cardinals)
      if (_safeCell(
        world,
        GridPos(x: position.x - direction.dx, y: position.y - direction.dy),
      ))
        GridPos(x: position.x - direction.dx, y: position.y - direction.dy):
            direction,
  };
}

GridPos _doorPosition(_Door door, MapData map) {
  final source = door.source;
  final GridPos position;
  if (source['entityId'] case final String id) {
    position = map.entities.singleWhere((entity) => entity.id == id).pos;
  } else {
    final trigger = map.triggers.singleWhere(
      (trigger) => trigger.id == source['triggerId'],
    );
    expect(trigger.area.size, const GridSize(width: 1, height: 1));
    position = trigger.area.pos;
  }
  return position;
}

List<(Direction, GridPos)>? _pathTo(
  GameplayWorldState world,
  GridPos start,
  Set<GridPos> goals, {
  bool Function(GridPos)? acceptsGoal,
  Map<String, Object?>? diagnostics,
}) {
  final queue = Queue<GridPos>()..add(start);
  final parents = <GridPos, (GridPos, Direction)?>{start: null};
  final states = <GridPos, GameplayWorldState>{start: _planningWorldAt(world, start)};
  final results = <String, int>{};
  final jumpLandings = <GridPos>{};
  final rejected = <Map<String, Object?>>[];
  while (queue.isNotEmpty && parents.length <= 16384) {
    final current = queue.removeFirst();
    if (goals.contains(current) && (acceptsGoal?.call(current) ?? true)) {
      final result = <(Direction, GridPos)>[];
      var cursor = current;
      while (parents[cursor] != null) {
        final parent = parents[cursor]!;
        result.add((parent.$2, cursor));
        cursor = parent.$1;
      }
      return result.length > 512 ? null : result.reversed.toList();
    }
    for (final (_, direction, _) in _cardinals) {
      final adjacent = GridPos(
        x: current.x + direction.dx,
        y: current.y + direction.dy,
      );
      final result = _cardinalResult(states[current]!, direction);
      final kind = result is Blocked ? 'Blocked:${result.reason.name}' : result.runtimeType.toString();
      if (result is Jumped) jumpLandings.add(result.plan.landingPos);
      results.update(kind, (count) => count + 1, ifAbsent: () => 1);
      final moved = _safeCardinalStep(states[current]!, direction, result: result);
      if (moved == null && (_safeCell(world, adjacent) || result is Jumped)) {
        final distance = goals.isEmpty ? 0 : goals.map((goal) =>
            (goal.x - current.x).abs() + (goal.y - current.y).abs())
            .reduce((a, b) => a < b ? a : b);
        rejected.add({'from': current.toJson(), 'to': adjacent.toJson(),
          'direction': direction.name, 'result': kind, 'goalDistance': distance,
          if (result is Jumped) 'landing': result.plan.landingPos.toJson()});
        rejected.sort((a, b) => (a['goalDistance'] as int).compareTo(b['goalDistance'] as int));
        if (rejected.length > 12) rejected.removeLast();
      }
      if (moved == null) continue;
      final next = moved.player.pos;
      if (parents.containsKey(next)) continue;
      parents[next] = (current, direction);
      states[next] = moved;
      queue.add(next);
    }
  }
  if (diagnostics != null) {
    final positions = parents.keys;
    diagnostics.addAll({'reachableCellCount': parents.length,
      'reachableBounds': {
        'left': positions.map((p) => p.x).reduce((a, b) => a < b ? a : b),
        'right': positions.map((p) => p.x).reduce((a, b) => a > b ? a : b),
        'top': positions.map((p) => p.y).reduce((a, b) => a < b ? a : b),
        'bottom': positions.map((p) => p.y).reduce((a, b) => a > b ? a : b)},
      'canonicalResults': results, 'nearestRejectedEdges': rejected,
      'jumpLandingsOutsideReachable': jumpLandings.where((position) => !parents.containsKey(position)).map((position) => position.toJson()).toList(),
      'searchLimitReached': parents.length > 16384});
  }
  return null;
}

GameplayWorldState _planningWorldAt(GameplayWorldState world, GridPos position) =>
    world.withPlayer(GameplayPlayerState.fromGridSpawn(
      cell: position,
      facing: world.player.facing,
      movementMode: world.player.movementMode,
      tileWidthPx: world.tileWidthPx,
      tileHeightPx: world.tileHeightPx,
      mapWidthCells: world.map.size.width,
      mapHeightCells: world.map.size.height,
      spriteWidthPx: world.player.playerSpriteWidthPx,
      spriteHeightPx: world.player.playerSpriteHeightPx,
    ));

GameplayStepResult _cardinalResult(GameplayWorldState world, Direction direction) =>
    stepGameplayWorld(world, MoveIntent(direction,
      pixelsPerStep: direction.dx == 0 ? world.tileHeightPx : world.tileWidthPx));

GameplayWorldState? _safeCardinalStep(GameplayWorldState world, Direction direction,
    {GameplayStepResult? result}) {
  result ??= _cardinalResult(world, direction);
  if (result is Jumped) {
    return _safeCell(world, result.plan.landingPos) &&
        _safeActivities(world, result.plan.viaPos) ? result.world : null;
  }
  final target = GridPos(x: world.player.pos.x + direction.dx,
      y: world.player.pos.y + direction.dy);
  if (!_safeCell(world, target)) return null;
  if (result is! Moved || result.world.player.pos != target ||
      result.hazardEffect != null || result.movementEffect != null ||
      result.platformControl != null) {
    return null;
  }
  return result.world;
}

GridPos _endOf(GridPos start, List<(Direction, GridPos)> directions) =>
    directions.isEmpty ? start : directions.last.$2;

Future<void> _followPath(
  PlayableMapGame game,
  RuntimeMapBundle bundle,
  List<(Direction, GridPos)> directions,
) async {
  for (final (direction, target) in directions) {
    final before = game.debugPlayerGridPosition;
    final rendered = game.debugPlayerWorldTopLeft;
    final planningWorld = _planningWorldAt(
        _worldFor(game, bundle.map, bundle.manifest), before);
    expect(
      _safeCardinalStep(planningWorld, direction)?.player.pos,
      target,
      reason: 'lot6.canonical_route_edge_refused: ${bundle.map.id} $before -> $target ${direction.name}',
    );
    await _publicStep(game, direction, bundle.map.id, expectedPosition: target);
    expect(
      game.debugPlayerWorldTopLeft.x,
      closeTo(rendered.x + (target.x - before.x) * bundle.cellWidth, .001),
    );
    expect(
      game.debugPlayerWorldTopLeft.y,
      closeTo(rendered.y + (target.y - before.y) * bundle.cellHeight, .001),
    );
  }
}

Future<void> _activateDoor(
  PlayableMapGame game,
  Direction direction,
  _Door door, {
  GridPos? expectedPosition,
}) async {
  final activations = game.debugCompletedMapActivationDispatchCount;
  await _publicStep(game, direction, door.command.destinationMapId,
      expectedPosition: expectedPosition);
  expect(
    game.debugLastCompletedMapActivation?.reason,
    MapActivationReason.warp,
  );
  expect(game.debugCompletedMapActivationDispatchCount, activations + 1);
  final arrived = game.debugPlayerGridPosition;
  await _ticks(game, 30);
  expect(game.gameStateSnapshot.currentMapId, door.command.destinationMapId);
  expect(game.debugPlayerGridPosition, arrived);
  expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
}

Future<void> _publicStep(
  PlayableMapGame game,
  Direction direction,
  String destination, {
  GridPos? expectedPosition,
}) async {
  final control = _cardinals.singleWhere((entry) => entry.$2 == direction).$1;
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  try {
    game.update(.016);
    await Future<void>.delayed(Duration.zero);
  } finally {
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  }
  await _waitUntil(
    game,
    () =>
        game.gameStateSnapshot.currentMapId == destination &&
        (expectedPosition == null ||
            game.debugPlayerGridPosition == expectedPosition) &&
        !game.debugIsPlayerStepping &&
        _idle(game),
  );
  expect(game.dialoguePresentationListenable.value, isNull);
  expect(game.inputAuthoritySnapshot.acceptsOverworldInput, isTrue);
}

bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    !game.debugIsEntityAutorunInFlight &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition;

Future<void> _ticks(PlayableMapGame game, int count) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _waitUntil(PlayableMapGame game, bool Function() done) async {
  for (var tick = 0; tick < 4000; tick++) {
    if (done()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'LOT6 runtime did not settle: map=${game.gameStateSnapshot.currentMapId}, '
    'phase=${game.debugFlowPhaseName}, position=${game.debugPlayerGridPosition}, '
    'line=${game.dialoguePresentationListenable.value?.fullText}',
  );
}

Future<String> _hash(String file) async =>
    crypto.sha256.convert(await File(file).readAsBytes()).toString();

final class _DiskSave extends FileGameSaveRepository {
  _DiskSave(this.filePath);
  final String filePath;

  @override
  Future<String> getSaveFilePath() async => filePath;
}
