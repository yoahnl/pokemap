import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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
  final configured = Platform.environment['AVELUNE_MANSION_PROJECT'];
  final routeFile =
      Platform.environment['AVELUNE_MANSION_ROUTE'] ??
      path.join('test', 'fixtures', 'source_mansion_journey_route.json');
  final output = Platform.environment['AVELUNE_MANSION_RECEIPT'];
  testWidgets(
    'full Mansion route obtains Secret Key and opens Gym continuously',
    (tester) async {
      await tester.runAsync(() async {
        expect(path.isAbsolute(configured!), isTrue);
        expect(await Directory(configured).resolveSymbolicLinks(), configured);
        final route = jsonDecode(await File(routeFile).readAsString()) as Map;
        final projectFile = path.join(configured, 'project.json');
        final manifest = await loadProjectManifestFromFile(projectFile);
        expect(manifest.maps, hasLength(383));
        String mapId(String name) =>
            manifest.maps.singleWhere((map) => map.name == name).id;
        final catalog = ProjectItemCatalog.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(
              await File(
                path.join(configured, manifest.pokemon.catalogFiles['items']!),
              ).readAsString(),
            ) as Map,
          ),
        );
        final keyId = catalog.entries
            .singleWhere(
              (item) =>
                  item.displayName.toLowerCase().replaceAll(' ', '') ==
                  'secretkey',
            )
            .id;
        final before = await _projectHashes(configured);
        final saveRoot = await Directory.systemTemp.createTemp(
          'mansion-continuous-save-',
        );
        final repository = _DiskSave(path.join(saveRoot.path, 'save.json'));
        final start = route['start'] as Map;
        expect(start['map'], 'Cinnabar Island');
        final initialState = GameState(
          saveId: 'mansion-continuous-journey',
          currentMapId: mapId(start['map']),
          playerPosition: GridPos(x: start['x'], y: start['y']),
          playerFacing: EntityFacing.values.byName(start['facing']),
        );
        PlayableMapGame? game;
        final stages = <Map<String, dynamic>>[];
        final visitedMaps = <String>['Cinnabar Island'];
        final dialogues = <String>[];
        var steps = 0;
        var pickups = 0;
        var reloads = 0;
        var mapChanges = 0;
        Future<void> unmount() async {
          game?.onRemove();
          game = null;
          await tester.pumpWidget(const SizedBox.shrink());
        }

        try {
          game = await _mount(tester, projectFile, repository, initialState);
          expect(_quantity(game!, keyId), 0);
          for (final raw in route['actions'] as List) {
            final action = raw as Map;
            final kind = action['kind'] as String;
            final expectedMap = mapId(action['map'] as String);
            expect(
              game!.gameStateSnapshot.currentMapId,
              expectedMap,
              reason: 'Wrong map before route action ${stages.length}: $action',
            );
            stdout.writeln(
              jsonEncode({
                'kind': 'mansionRouteStageStart',
                'index': stages.length,
                'action': action,
                'position': game!.debugPlayerGridPosition.toJson(),
                'keyQuantity': _quantity(game!, keyId),
              }),
            );
            if (kind == 'walk') {
              final target = GridPos(x: action['x'], y: action['y']);
              final entry = manifest.maps.singleWhere(
                (map) => map.id == expectedMap,
              );
              final map = MapData.fromJson(
                Map<String, dynamic>.from(
                  jsonDecode(
                    await File(path.join(configured, entry.relativePath))
                        .readAsString(),
                  ) as Map,
                ),
              );
              final extras = <GridPos>{
                for (final pos in (action['blocked'] as List? ?? const []))
                  GridPos(x: pos[0], y: pos[1]),
              };
              for (
                var step = 0;
                step < 1000 && game!.debugPlayerGridPosition != target;
                step++
              ) {
                final controls = _routeControls(
                  manifest,
                  map,
                  game!,
                  target,
                  extras,
                );
                expect(
                  controls,
                  isNotEmpty,
                  reason:
                      'No walkable route to $target in ${map.name} from ${game!.debugPlayerGridPosition}',
                );
                final previous = game!.debugPlayerGridPosition;
                final control = controls.first;
                expect(
                  game!.handleRuntimeInputEvent(
                    RuntimeInputEvent.press(control),
                  ),
                  isTrue,
                );
                try {
                  await _wait(
                    game!,
                    () =>
                        game!.debugPlayerGridPosition != previous ||
                        game!.gameStateSnapshot.currentMapId != expectedMap,
                  );
                } finally {
                  game!.handleRuntimeInputEvent(
                    RuntimeInputEvent.release(control),
                  );
                }
                await _settle(game!);
                expect(
                  game!.gameStateSnapshot.currentMapId,
                  expectedMap,
                  reason: 'Walk action crossed an unintended map trigger',
                );
                steps++;
              }
              expect(game!.debugPlayerGridPosition, target);
            } else if (kind == 'face') {
              await _face(
                game!,
                RuntimeInputControl.values.byName(action['direction']),
              );
            } else if (kind == 'interact') {
              if (action['direction'] != null) {
                await _face(
                  game!,
                  RuntimeInputControl.values.byName(action['direction']),
                );
              }
              final priorKey = _quantity(game!, keyId);
              _press(game!, RuntimeInputControl.primary);
              await _wait(
                game!,
                () => game!.dialoguePresentationListenable.value != null,
              );
              final lines = await _finishDialogue(
                game!,
                choiceIndex: action['choiceIndex'] as int? ?? 0,
              );
              dialogues.addAll(lines);
              if (action['contains'] != null) {
                expect(
                  lines.join(' ').toLowerCase(),
                  contains((action['contains'] as String).toLowerCase()),
                );
              }
              if (action['picksUpKey'] == true) {
                expect(priorKey, 0);
                expect(_quantity(game!, keyId), 1);
                pickups++;
              }
            } else if (kind == 'blockedStep') {
              final position = game!.debugPlayerGridPosition;
              final control = RuntimeInputControl.values.byName(
                action['direction'],
              );
              final delta = switch (control) {
                RuntimeInputControl.up => const GridPos(x: 0, y: -1),
                RuntimeInputControl.down => const GridPos(x: 0, y: 1),
                RuntimeInputControl.left => const GridPos(x: -1, y: 0),
                RuntimeInputControl.right => const GridPos(x: 1, y: 0),
                _ => throw StateError('A cardinal blocked step is required'),
              };
              final target = GridPos(
                x: position.x + delta.x,
                y: position.y + delta.y,
              );
              final entry = manifest.maps.singleWhere(
                (map) => map.id == expectedMap,
              );
              final map = MapData.fromJson(
                Map<String, dynamic>.from(
                  jsonDecode(
                    await File(path.join(configured, entry.relativePath))
                        .readAsString(),
                  ) as Map,
                ),
              );
              expect(
                map.layers.whereType<CollisionLayer>().any(
                  (layer) =>
                      layer.collisions[target.y * map.size.width + target.x],
                ),
                isFalse,
                reason: 'The obstacle, rather than the terrain, must block this step.',
              );
              expect(
                game!.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
                isTrue,
              );
              try {
                await _ticks(game!, 80);
              } finally {
                game!.handleRuntimeInputEvent(
                  RuntimeInputEvent.release(control),
                );
              }
              await _settle(game!);
              expect(
                game!.debugPlayerGridPosition,
                position,
                reason: 'A closed multi-cell shutter must block its entire footprint.',
              );
              expect(game!.dialoguePresentationListenable.value, isNull);
            } else if (kind == 'interactSilent') {
              final beforePosition = game!.debugPlayerGridPosition;
              final beforeKeyQuantity = _quantity(game!, keyId);
              _press(game!, RuntimeInputControl.primary);
              await _ticks(game!, 80);
              expect(game!.dialoguePresentationListenable.value, isNull);
              await _settle(game!);
              expect(game!.debugPlayerGridPosition, beforePosition);
              expect(_quantity(game!, keyId), beforeKeyQuantity);
            } else if (kind == 'transfer') {
              final control = RuntimeInputControl.values.byName(
                action['direction'],
              );
              final destination = mapId(action['destination']);
              expect(
                game!.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
                isTrue,
              );
              try {
                await _wait(
                  game!,
                  () => game!.gameStateSnapshot.currentMapId == destination,
                );
              } finally {
                game!.handleRuntimeInputEvent(
                  RuntimeInputEvent.release(control),
                );
              }
              await _settle(game!);
              if (action['x'] != null) {
                expect(
                  game!.debugPlayerGridPosition,
                  GridPos(x: action['x'], y: action['y']),
                );
              }
              mapChanges++;
              visitedMaps.add(action['destination'] as String);
            } else if (kind == 'saveReload') {
              final snapshot = game!.gameStateSnapshot;
              expect(await game!.saveGame(), isTrue);
              await unmount();
              game = await _mount(
                tester,
                projectFile,
                repository,
                initialState,
              );
              expect(await game!.loadGame(), isTrue);
              await _settle(game!);
              expect(
                game!.gameStateSnapshot.currentMapId,
                snapshot.currentMapId,
              );
              expect(game!.debugPlayerGridPosition, snapshot.playerPosition);
              expect(game!.gameStateSnapshot.bag, snapshot.bag);
              expect(
                game!.gameStateSnapshot.narrativeFactRuntimeState,
                snapshot.narrativeFactRuntimeState,
              );
              reloads++;
            } else if (kind == 'assert') {
              if (action['keyQuantity'] != null) {
                expect(_quantity(game!, keyId), action['keyQuantity']);
              }
              if (action['fact'] != null) {
                final fact = manifest.facts.singleWhere(
                  (fact) => fact.description.endsWith(action['fact']),
                );
                expect(_fact(game!, manifest, fact.id), action['value']);
              }
            } else {
              fail('Unsupported route action $kind');
            }
            final stage = <String, dynamic>{
              'index': stages.length,
              'action': action,
              'mapId': game!.gameStateSnapshot.currentMapId,
              'position': game!.debugPlayerGridPosition.toJson(),
              'keyQuantity': _quantity(game!, keyId),
            };
            stages.add(stage);
            stdout.writeln(
              jsonEncode({'kind': 'mansionRouteStagePassed', ...stage}),
            );
          }
          expect(visitedMaps, [
            'Cinnabar Island',
            'Pokémon Mansion 1F',
            'Pokémon Mansion 2F',
            'Pokémon Mansion 3F',
            'Pokémon Mansion 1F',
            'Pokémon Mansion B1F',
            'Pokémon Mansion 1F',
            'Cinnabar Island',
            'Cinnabar Gym',
          ]);
          expect(pickups, 1);
          expect(reloads, greaterThanOrEqualTo(1));
          expect(mapChanges, greaterThanOrEqualTo(4));
          expect(game!.gameStateSnapshot.currentMapId, mapId('Cinnabar Gym'));
          expect(_quantity(game!, keyId), 1);
          expect(await _projectHashes(configured), before);
          final receipt = <String, dynamic>{
            'kind': 'continuousMansionSecretKeyGymJourney',
            'projectPath': configured,
            'mapCount': manifest.maps.length,
            'stages': stages,
            'walkedCells': steps,
            'mapTransfers': mapChanges,
            'visitedMaps': visitedMaps,
            'dialogues': dialogues,
            'keyPickups': pickups,
            'saveColdReloadCount': reloads,
            'keyInjected': false,
            'positionReseededDuringJourney': false,
            'publicRuntimeInputUsed': true,
            'projectFilesUnchanged': true,
            'fileHashes': before,
            'sourceScriptsExecuted': 0,
            'combatRulesModified': false,
            'battleExecutionCertified': false,
            'fullCampaignCertified': false,
            'audibleOutputCertified': false,
          };
          if (output != null) {
            expect(path.isWithin(configured, output), isFalse);
            await File(output).writeAsString(jsonEncode(receipt), flush: true);
          }
          stdout.writeln(
            jsonEncode({
              'kind': receipt['kind'],
              'walkedCells': steps,
              'mapTransfers': mapChanges,
              'visitedMaps': visitedMaps,
              'stages': stages.length,
              'receiptPath': output,
            }),
          );
        } finally {
          await unmount();
          await saveRoot.delete(recursive: true);
        }
      });
    },
    skip: configured == null,
    timeout: const Timeout(Duration(minutes: 12)),
  );
}

Future<void> _face(PlayableMapGame game, RuntimeInputControl direction) async {
  final expected = switch (direction) {
    RuntimeInputControl.up => EntityFacing.north,
    RuntimeInputControl.right => EntityFacing.east,
    RuntimeInputControl.down => EntityFacing.south,
    RuntimeInputControl.left => EntityFacing.west,
    _ => throw ArgumentError.value(direction),
  };
  if (game.gameStateSnapshot.playerFacing == expected) return;
  final before = game.debugPlayerGridPosition;
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(direction)),
    isTrue,
  );
  try {
    await _wait(game, () => game.gameStateSnapshot.playerFacing == expected);
  } finally {
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(direction));
  }
  await _settle(game);
  expect(
    game.debugPlayerGridPosition,
    before,
    reason: 'Facing must not take an unintended movement step.',
  );
}

List<RuntimeInputControl> _routeControls(
  ProjectManifest manifest,
  MapData map,
  PlayableMapGame game,
  GridPos target,
  Set<GridPos> extras,
) {
  final projected = projectMapEntityPresentations(
    project: manifest,
    gameState: game.gameStateSnapshot,
    map: map,
  );
  final blocked = <GridPos>{...extras};
  for (final layer in map.layers.whereType<CollisionLayer>()) {
    for (var index = 0; index < layer.collisions.length; index++) {
      if (layer.collisions[index]) {
        blocked.add(
          GridPos(x: index % map.size.width, y: index ~/ map.size.width),
        );
      }
    }
  }
  for (final entity in projected.entities) {
    final pos = game.debugMapEntityPosition(entity.id) ?? entity.pos;
    if (entity.blocksMovement) {
      for (var y = 0; y < entity.size.height; y++) {
        for (var x = 0; x < entity.size.width; x++) {
          blocked.add(GridPos(x: pos.x + x, y: pos.y + y));
        }
      }
    }
    final npc = entity.npc;
    if (npc != null && npc.trainerId != null && npc.lineOfSightRange > 0) {
      final delta = switch (npc.facing) {
        EntityFacing.north => const GridPos(x: 0, y: -1),
        EntityFacing.south => const GridPos(x: 0, y: 1),
        EntityFacing.east => const GridPos(x: 1, y: 0),
        EntityFacing.west => const GridPos(x: -1, y: 0),
      };
      for (var distance = 1; distance <= npc.lineOfSightRange; distance++) {
        blocked.add(
          GridPos(x: pos.x + delta.x * distance, y: pos.y + delta.y * distance),
        );
      }
    }
  }
  for (final trigger in map.triggers) {
    for (var y = 0; y < trigger.area.size.height; y++) {
      for (var x = 0; x < trigger.area.size.width; x++) {
        final pos = GridPos(
          x: trigger.area.pos.x + x,
          y: trigger.area.pos.y + y,
        );
        if (pos != target) blocked.add(pos);
      }
    }
  }
  final start = game.debugPlayerGridPosition;
  final queue = <GridPos>[start];
  final previous = <GridPos, (GridPos, RuntimeInputControl)>{};
  final visited = <GridPos>{start};
  const directions = <(int, int, RuntimeInputControl)>[
    (0, -1, RuntimeInputControl.up),
    (1, 0, RuntimeInputControl.right),
    (0, 1, RuntimeInputControl.down),
    (-1, 0, RuntimeInputControl.left),
  ];
  for (var index = 0; index < queue.length; index++) {
    final current = queue[index];
    if (current == target) {
      final controls = <RuntimeInputControl>[];
      var cursor = target;
      while (cursor != start) {
        final back = previous[cursor]!;
        controls.add(back.$2);
        cursor = back.$1;
      }
      return controls.reversed.toList();
    }
    for (final (x, y, direction) in directions) {
      final next = GridPos(x: current.x + x, y: current.y + y);
      if (next.x < 0 ||
          next.y < 0 ||
          next.x >= map.size.width ||
          next.y >= map.size.height ||
          blocked.contains(next) ||
          !visited.add(next)) {
        continue;
      }
      previous[next] = (current, direction);
      queue.add(next);
    }
  }
  return const [];
}

bool _fact(PlayableMapGame game, ProjectManifest manifest, String id) =>
    game.gameStateSnapshot.narrativeFactRuntimeState.valueFor(id)?.boolValue ??
    manifest.facts.singleWhere((fact) => fact.id == id).defaultValue;

int _quantity(PlayableMapGame game, String id) => game
    .gameStateSnapshot
    .bag
    .entries
    .where((entry) => entry.itemId == id)
    .fold(0, (total, entry) => total + entry.quantity);

void _press(PlayableMapGame game, RuntimeInputControl control) {
  expect(
    game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
    isTrue,
  );
  game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
}

Future<List<String>> _finishDialogue(
  PlayableMapGame game, {
  int choiceIndex = 0,
}) async {
  final lines = <String>[];
  for (var count = 0; count < 300; count++) {
    final presentation = game.dialoguePresentationListenable.value;
    if (presentation != null) {
      if (lines.isEmpty || lines.last != presentation.fullText) {
        lines.add(presentation.fullText);
      }
      if (presentation.mode == DialoguePresentationMode.choices) {
        expect(
          presentation.choices.any(
            (choice) => choice.index == choiceIndex && choice.enabled,
          ),
          isTrue,
        );
        for (var step = 0; step < presentation.choices.length; step++) {
          final selected = game.dialoguePresentationListenable.value!.choices
              .where((choice) => choice.selected)
              .single
              .index;
          if (selected == choiceIndex) break;
          _press(game, RuntimeInputControl.down);
        }
        expect(
          game.dialoguePresentationListenable.value!.choices
              .where((choice) => choice.selected)
              .single
              .index,
          choiceIndex,
        );
      }
      _press(game, RuntimeInputControl.primary);
      await _ticks(game, 2);
    } else if (_idle(game)) {
      await _settle(game);
      return lines;
    } else {
      await _ticks(game, 4);
    }
  }
  fail(
    'Dialogue did not finish: ${game.dialoguePresentationListenable.value?.fullText}',
  );
}

Future<void> _ticks(PlayableMapGame game, int count) async {
  for (var tick = 0; tick < count; tick++) {
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

Future<PlayableMapGame> _mount(
  WidgetTester tester,
  String projectFile,
  _DiskSave repository,
  GameState initialState,
) async {
  final bundle = await loadRuntimeMapBundle(
    projectFilePath: projectFile,
    mapId: initialState.currentMapId,
  );
  expect(
    bundle.map.layers.whereType<CollisionLayer>().any(
      (layer) =>
          layer.collisions[initialState.playerPosition.y *
                  bundle.map.size.width +
              initialState.playerPosition.x],
    ),
    isFalse,
    reason: 'The QA start position must be on a walkable source tile.',
  );
  final audio = _SceneSoundTrace(bundle);
  final game = PlayableMapGame(
    bundle: bundle,
    projectFilePath: projectFile,
    saveRepository: repository,
    initialGameState: initialState,
    sceneSoundEffectPlaybackPort: audio,
    dialogueFeedbackPlaybackPort: audio,
  );
  try {
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
    await _wait(
      game,
      () => game.debugCompletedMapActivationDispatchCount > 0 && _idle(game),
    );
    await _settle(game);
    expect(game.debugPlayerGridPosition, initialState.playerPosition);
    return game;
  } catch (_) {
    game.onRemove();
    rethrow;
  }
}

bool _idle(PlayableMapGame game) =>
    game.debugFlowPhaseName == 'overworld' &&
    !game.debugIsEntityAutorunInFlight &&
    !game.debugIsMapActivationDispatchInFlight &&
    !game.debugIsNarrativeSpatialDispatchInFlight &&
    !game.debugIsNarrativeOutcomeWorkInFlight &&
    !game.debugIsLoadActivationWorkInFlight &&
    !game.debugHasPendingDialogueLoad &&
    !game.debugHasPendingMapTransition &&
    !game.debugIsPlayerStepping;

Future<void> _settle(PlayableMapGame game) async {
  var quietFrames = 0;
  await _wait(game, () {
    quietFrames =
        _idle(game) &&
            game.dialoguePresentationListenable.value == null &&
            game.inputAuthoritySnapshot.acceptsOverworldInput
        ? quietFrames + 1
        : 0;
    return quietFrames >= 20;
  });
  expect(game.debugIsPlayerVisible, isTrue);
}

Future<void> _wait(PlayableMapGame game, bool Function() complete) async {
  final elapsed = Stopwatch()..start();
  for (
    var tick = 0;
    tick < 4000 && elapsed.elapsed < const Duration(seconds: 30);
    tick++
  ) {
    if (complete()) return;
    game.update(0.016);
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  fail(
    'Mansion journey did not settle: map=${game.gameStateSnapshot.currentMapId}, '
    'position=${game.debugPlayerGridPosition}, facing=${game.gameStateSnapshot.playerFacing}, phase=${game.debugFlowPhaseName}, '
    'input=${game.inputAuthoritySnapshot.acceptsOverworldInput}, '
    'dialogue=${game.dialoguePresentationListenable.value?.fullText}',
  );
}

Future<Map<String, String>> _projectHashes(String root) async {
  final result = <String, String>{};
  await for (final entry in Directory(
    root,
  ).list(recursive: true, followLinks: false)) {
    if (entry is File) {
      result[path.relative(entry.path, from: root)] = crypto.sha256
          .convert(await entry.readAsBytes())
          .toString();
    } else if (entry is Link) {
      fail('Qualification projects must not contain symlinks: ${entry.path}');
    }
  }
  return result;
}

final class _SceneSoundTrace
    implements SceneSoundEffectPlaybackPort, DialogueFeedbackPlaybackPort {
  _SceneSoundTrace(this.bundle);
  final RuntimeMapBundle bundle;

  @override
  Future<void> playCue(DialogueAudioCue cue, {required String playbackId}) =>
      playSoundEffect(
        cue.mediaAssetId,
        volume: cue.volume,
        playbackId: playbackId,
      );

  @override
  Future<void> playSoundEffect(
    String mediaAssetId, {
    required double volume,
    required String playbackId,
  }) async {
    final asset = bundle.manifest.cinematicMediaAssets.singleWhere(
      (asset) => asset.id == mediaAssetId,
    );
    expect(asset.kind, CinematicMediaAssetKind.sound);
    expect(volume, inInclusiveRange(0.0, 1.0));
    expect(playbackId, isNotEmpty);
    expect(
      await File(path.join(bundle.projectRootDirectory, asset.relativePath))
          .exists(),
      isTrue,
    );
  }
}

final class _DiskSave extends FileGameSaveRepository {
  _DiskSave(this.filePath);
  final String filePath;

  @override
  Future<String> getSaveFilePath() async => filePath;
}
