import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final referencePath = Platform.environment['AVELUNE_LOT6_KANTO_REFERENCE'];
  testWidgets(
    'published full Kanto world preview walks from authored Route 9 spawn and persists across disk reload',
    (tester) async {
      await tester.runAsync(() async {
        final delivery = Map<String, dynamic>.from(
          jsonDecode(await File(referencePath!).readAsString()) as Map,
        );
        expect(delivery['kind'], 'fullKantoCanonicalConverterDelivery');
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
          excursionProof = await _tryCenterExcursion(
            game,
            firstBundle,
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
        renderedBefore.x + direction.dx * bundle.manifest.settings.tileWidth,
        0.001,
      ),
    );
    expect(
      game.debugPlayerWorldTopLeft.y,
      closeTo(
        renderedBefore.y + direction.dy * bundle.manifest.settings.tileHeight,
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

Future<Map<String, Object?>> _tryCenterExcursion(
  PlayableMapGame game,
  RuntimeMapBundle initial,
  String referencePath,
  String projectFile,
  Map<String, String> readMapHashes,
) async {
  final manifest = initial.manifest;
  final qualification = Map<String, dynamic>.from(
    jsonDecode(
      await File(
        path.join(
          path.dirname(referencePath),
          'source-event-qualification.json',
        ),
      ).readAsString(),
    ) as Map,
  );
  final delivery = jsonDecode(await File(referencePath).readAsString()) as Map;
  expect(qualification['kind'], 'fullKantoSourceEventQualification');
  expect(qualification['sourceSnapshotHash'], delivery['snapshotHash']);
  expect(qualification['nativeDraftHash'], delivery['nativeDraftHash']);
  final rows = (qualification['events'] as List).cast<Map>();
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

  _Door door(int sourceMapId, int sourceEventId) {
    final row = rows.singleWhere((row) {
      final locator = row['locator'] as Map;
      return locator['mapId'] == sourceMapId &&
          locator['eventId'] == sourceEventId;
    });
    expect(row['status'], 'adaptedStaticSemantics');
    expect(row['gaps'], isEmpty);
    final page = (row['pages'] as List).cast<Map>().singleWhere(
      (page) => page['originalPageIndex'] == 0,
    );
    final record = manifest.eventRegistry!.records.singleWhere(
      (record) => record.id == page['nativeEventId'],
    );
    expect(record.enabledOrNull, isTrue);
    final definition = record.definitionOrNull!;
    final source = definition.source.toJson();
    expect(source['kind'], isIn(['entityBump', 'triggerEnter', 'triggerBump']));
    final scene = manifest.scenes.singleWhere(
      (scene) => scene.id == definition.sceneId,
    );
    final commands = scene.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneWarpInteractiveCommand>()
        .toList();
    expect(commands, hasLength(1));
    return _Door(record.id, source, commands.single);
  }

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
    final outsidePaths = <GridPos, List<Direction>>{};
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
  if (world.isBlocked(position.x, position.y) ||
      world.isWaterCell(position.x, position.y) ||
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

List<Direction>? _pathTo(
  GameplayWorldState world,
  GridPos start,
  Set<GridPos> goals, {
  bool Function(GridPos)? acceptsGoal,
}) {
  final queue = Queue<GridPos>()..add(start);
  final parents = <GridPos, (GridPos, Direction)?>{start: null};
  while (queue.isNotEmpty && parents.length <= 16384) {
    final current = queue.removeFirst();
    if (goals.contains(current) && (acceptsGoal?.call(current) ?? true)) {
      final result = <Direction>[];
      var cursor = current;
      while (parents[cursor] != null) {
        final parent = parents[cursor]!;
        result.add(parent.$2);
        cursor = parent.$1;
      }
      return result.length > 512 ? null : result.reversed.toList();
    }
    for (final (_, direction, _) in _cardinals) {
      final next = GridPos(
        x: current.x + direction.dx,
        y: current.y + direction.dy,
      );
      if (parents.containsKey(next) || !_safeCell(world, next)) continue;
      parents[next] = (current, direction);
      queue.add(next);
    }
  }
  return null;
}

GridPos _endOf(GridPos start, List<Direction> directions) => directions.fold(
  start,
  (position, direction) =>
      GridPos(x: position.x + direction.dx, y: position.y + direction.dy),
);

Future<void> _followPath(
  PlayableMapGame game,
  RuntimeMapBundle bundle,
  List<Direction> directions,
) async {
  for (final direction in directions) {
    final before = game.debugPlayerGridPosition;
    final rendered = game.debugPlayerWorldTopLeft;
    final target = _endOf(before, [direction]);
    expect(
      _safeCell(_worldFor(game, bundle.map, bundle.manifest), target),
      isTrue,
      reason: 'lot6.route_became_unsafe: ${bundle.map.id} $before -> $target',
    );
    await _publicStep(game, direction, bundle.map.id, expectedPosition: target);
    expect(
      game.debugPlayerWorldTopLeft.x,
      closeTo(rendered.x + direction.dx * bundle.cellWidth, .001),
    );
    expect(
      game.debugPlayerWorldTopLeft.y,
      closeTo(rendered.y + direction.dy * bundle.cellHeight, .001),
    );
  }
}

Future<void> _activateDoor(
  PlayableMapGame game,
  Direction direction,
  _Door door,
) async {
  final activations = game.debugCompletedMapActivationDispatchCount;
  await _publicStep(game, direction, door.command.destinationMapId);
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
